import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:drift/drift.dart' show Value;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/db_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/settings/behavior_settings_service.dart';
import '../../core/time/timezone_mode_service.dart';
import '../../core/time/timezone_service.dart';
import '../../features/dosing/domain/dosing_services.dart';

// Bootstraps app state, timezone sync, and reminder repair.
/// Runs offline-first reconciliation and (if needed) reschedules notifications.
///
/// - Ensures default user settings exist
/// - Detects timezone changes using `user_settings.lastTimezone`
/// - Cancels/reschedules upcoming dose notifications when timezone changes
/// - Reconciles missed doses after grace window
Future<void> initializeApp(WidgetRef ref) async {
  // Timezone data needs to be ready before any date math happens.
  tzdata.initializeTimeZones();

  final appDb = ref.read(appDatabaseProvider);
  final medicationDao = ref.read(medicationDaoProvider);
  final doseScheduleDao = ref.read(doseScheduleDaoProvider);
  final doseEventDao = ref.read(doseEventDaoProvider);
  final userSettingsDao = ref.read(userSettingsDaoProvider);

  // Ensure defaults exist so grace window calculations are stable.
  await userSettingsDao.ensureDefaultSingleton();
  final settings = await userSettingsDao.getSingleton();
  final storedTimezone = settings?.lastTimezone;
  final behaviorSettings = await BehaviorSettingsService.load();

  final deviceTimezoneName = await TimezoneService.getDeviceTimezoneName();
  tz.setLocalLocation(tz.getLocation(deviceTimezoneName));

  final currentTimezoneName = tz.local.name;
  final timezoneMode = await TimezoneModeService.getMode();

  final meds = await medicationDao.getAll();

  // Old timezone means we need to rebuild reminder schedules.
  // If timezone changed, cancel scheduled occurrences using the OLD timezone
  // so deterministic notification ids match, then reschedule using the new one.
  final didChangeTimezone =
      storedTimezone != null && storedTimezone != currentTimezoneName;

  if (didChangeTimezone) {
    for (final med in meds.where((m) => m.isActive)) {
      final allScheduleTimes = await doseScheduleDao.getByMedicationId(med.id);
      final scheduleTimes = timezoneMode == TimezoneDoseMode.anchorOriginal
          ? allScheduleTimes.where((t) => t.timezone == null).toList()
          : allScheduleTimes;

      if (scheduleTimes.isEmpty) continue;

      await NotificationService.instance
          .cancelUpcomingDoseNotificationsForMedication(
            medication: med,
            scheduleTimes: scheduleTimes,
            timezoneName: storedTimezone,
          );

      await NotificationService.instance
          .scheduleUpcomingDoseNotificationsForMedication(
            medication: med,
            scheduleTimes: scheduleTimes,
            timezoneName: currentTimezoneName,
            reminderOffsetMinutes: behaviorSettings.adaptiveReminderTiming
                ? await DosingService(
                    db: appDb,
                    medicationDao: medicationDao,
                    doseScheduleDao: doseScheduleDao,
                    doseEventDao: doseEventDao,
                    userSettingsDao: userSettingsDao,
                  ).getAdaptiveReminderOffsetMinutes(medicationId: med.id)
                : 0,
          );
    }

    await userSettingsDao.upsertSingleton(
      UserSettingsCompanion(
        id: const Value(1),
        lastTimezone: Value(currentTimezoneName),
      ),
    );
  } else if (storedTimezone == null) {
    await userSettingsDao.upsertSingleton(
      UserSettingsCompanion(
        id: const Value(1),
        lastTimezone: Value(currentTimezoneName),
      ),
    );
  }

  final dosingService = DosingService(
    db: appDb,
    medicationDao: medicationDao,
    doseScheduleDao: doseScheduleDao,
    doseEventDao: doseEventDao,
    userSettingsDao: userSettingsDao,
  );

  // Final cleanup pass so missed doses are caught after startup.
  await dosingService.reconcileMissedDoses(now: DateTime.now(), daysBack: 7);
}
