import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/app_database.dart';

// Notification helper for scheduling and canceling dose reminders.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  // The local notifications plugin for the whole app.
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionsRequested = false;

  Future<void> init({
    required String timezoneName,
    void Function(String payload)? onNotificationTap,
  }) async {
    // Only do the setup one time.
    if (_initialized) return;

    // Set up timezone stuff before any reminders are scheduled.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null) return;
        onNotificationTap?.call(payload);
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchPayload != null) {
      onNotificationTap?.call(launchPayload);
    }

    _initialized = true;
  }

  Future<void> requestUserPermissions() async {
    // Ask for notification permissions on each platform once.
    if (_permissionsRequested) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);

    _permissionsRequested = true;
  }

  Future<void> scheduleUpcomingDoseNotificationsForMedication({
    required Medication medication,
    required List<DoseScheduleTime> scheduleTimes,
    required String timezoneName,
    int reminderOffsetMinutes = 0,
    int daysAhead = 14,
  }) async {
    // Make sure permissions are ready before we build reminders.
    await requestUserPermissions();

    // Keep the scheduler aligned with the chosen timezone.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    final now = tz.TZDateTime.now(tz.local);

    for (final st in scheduleTimes) {
      if (!st.isEnabled) continue;

      final locationTz = st.timezone != null
          ? tz.getLocation(st.timezone!)
          : tz.local;

      final startDay = _dateOnlyInTz(st.startDate, location: locationTz);

      final endDay = st.endDate == null
          ? null
          : _dateOnlyInTz(st.endDate!, location: locationTz);

      final horizonEnd = _dateOnlyInTz(
        now.add(Duration(days: daysAhead)),
        location: locationTz,
      );

      final effectiveStart = startDay.isAfter(now)
          ? startDay
          : _dateOnlyInTz(now, location: locationTz);
      final effectiveEnd = endDay == null
          ? horizonEnd
          : (endDay.isBefore(horizonEnd) ? endDay : horizonEnd);

      for (
        var day = effectiveStart;
        !day.isAfter(effectiveEnd);
        day = _nextCalendarDay(day, locationTz)
      ) {
        final enabledForDay = _isScheduleEnabledForDay(
          day: day,
          schedule: st,
          location: locationTz,
        );
        if (!enabledForDay) continue;

        final baseScheduledAt = tz.TZDateTime(
          locationTz,
          day.year,
          day.month,
          day.day,
          st.timeHour,
          st.timeMinute,
        );

        var scheduledAt = baseScheduledAt.add(
          Duration(minutes: reminderOffsetMinutes),
        );

        // If adaptive offset pushes this into the past but the original dose
        // time is still upcoming, keep a minimum 1-minute lead time.
        if (!scheduledAt.isAfter(now) && baseScheduledAt.isAfter(now)) {
          scheduledAt = now.add(const Duration(minutes: 1));
        }

        if (!scheduledAt.isAfter(now)) continue;

        // Use a stable id so the same reminder can be canceled later.
        final notificationId = notificationIdForOccurrence(
          medication.id,
          st.id,
          scheduledAt,
        );

        final payload = jsonEncode({
          'medicationId': medication.id,
          'doseScheduleTimeId': st.id,
          'scheduledAt': scheduledAt.toIso8601String(),
        });

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const androidDetails = AndroidNotificationDetails(
          'velouria_dose_reminders',
          'Dose reminders',
          channelDescription: 'Medication dose reminders from Velouria.',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
          macOS: iosDetails,
        );

        await _plugin.zonedSchedule(
          notificationId,
          '${medication.name} reminder',
          'Next dose: ${medication.name}.',
          scheduledAt,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: null,
          payload: payload,
        );
      }
    }
  }

  Future<void> cancelUpcomingDoseNotificationsForMedication({
    required Medication medication,
    required List<DoseScheduleTime> scheduleTimes,
    required String timezoneName,
    int daysAhead = 14,
  }) async {
    // Rebuild the same reminder ids and cancel the future ones.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    final now = tz.TZDateTime.now(tz.local);

    for (final st in scheduleTimes) {
      if (!st.isEnabled) continue;

      final locationTz = st.timezone != null
          ? tz.getLocation(st.timezone!)
          : tz.local;

      final startDay = _dateOnlyInTz(st.startDate, location: locationTz);
      final endDay = st.endDate == null
          ? null
          : _dateOnlyInTz(st.endDate!, location: locationTz);

      final horizonEnd = _dateOnlyInTz(
        now.add(Duration(days: daysAhead)),
        location: locationTz,
      );

      final effectiveStart = startDay.isAfter(now)
          ? startDay
          : _dateOnlyInTz(now, location: locationTz);
      final effectiveEnd = endDay == null
          ? horizonEnd
          : (endDay.isBefore(horizonEnd) ? endDay : horizonEnd);

      for (
        var day = effectiveStart;
        !day.isAfter(effectiveEnd);
        day = _nextCalendarDay(day, locationTz)
      ) {
        final enabledForDay = _isScheduleEnabledForDay(
          day: day,
          schedule: st,
          location: locationTz,
        );
        if (!enabledForDay) continue;

        final scheduledAt = tz.TZDateTime(
          locationTz,
          day.year,
          day.month,
          day.day,
          st.timeHour,
          st.timeMinute,
        );

        if (!scheduledAt.isAfter(now)) continue;

        final notificationId = notificationIdForOccurrence(
          medication.id,
          st.id,
          scheduledAt,
        );

        await _plugin.cancel(notificationId);
      }
    }
  }

  int notificationIdForOccurrence(
    String medicationId,
    int doseScheduleTimeId,
    tz.TZDateTime scheduledAt,
  ) {
    // Mix the med, schedule slot, and time into one repeatable number.
    final medHash = medicationId.hashCode & 0x7fffffff;
    final atMillis = scheduledAt.millisecondsSinceEpoch;

    final raw = medHash ^ (doseScheduleTimeId * 1000003) ^ atMillis;
    return (raw.abs() % 2147483000) + 1;
  }

  tz.TZDateTime _dateOnlyInTz(DateTime dt, {required tz.Location location}) {
    // Strip the time part so date math stays simple.
    final converted = tz.TZDateTime.from(dt, location);
    return tz.TZDateTime(
      location,
      converted.year,
      converted.month,
      converted.day,
    );
  }

  bool _isScheduleEnabledForDay({
    required tz.TZDateTime day,
    required DoseScheduleTime schedule,
    required tz.Location location,
  }) {
    // Weekly bitmask schedules use the normal Monday-to-Sunday layout.
    if (schedule.daysOfWeekBitmask > 0) {
      final weekday = day.weekday; // Mon=1..Sun=7
      final bitIndex = weekday - 1;
      return ((schedule.daysOfWeekBitmask >> bitIndex) & 1) == 1;
    }

    // Negative values mean "repeat every N days" instead.
    final intervalDays = (-schedule.daysOfWeekBitmask).clamp(1, 365).toInt();
    final start = tz.TZDateTime.from(schedule.startDate, location);
    final startOnly = tz.TZDateTime(
      location,
      start.year,
      start.month,
      start.day,
    );
    final dayOnly = tz.TZDateTime(location, day.year, day.month, day.day);

    final daysSinceStart = dayOnly.difference(startOnly).inDays;
    return daysSinceStart >= 0 && daysSinceStart % intervalDays == 0;
  }

  tz.TZDateTime _nextCalendarDay(tz.TZDateTime day, tz.Location location) {
    // Move to the next calendar day without messing with hours.
    return tz.TZDateTime(location, day.year, day.month, day.day + 1);
  }
}
