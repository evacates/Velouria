import 'package:drift/drift.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/db/app_database.dart';

// Status codes for dose events, kept as plain ints for Drift.
const int doseStatusScheduled = 0;
const int doseStatusTaken = 1;
const int doseStatusMissed = 2;
const int doseStatusSkipped = 3;

const int doseSourceNotification = 0;
const int doseSourceManual = 1;

// One planned dose occurrence at a specific time.
class DoseOccurrence {
  DoseOccurrence({
    required this.medicationId,
    required this.scheduleTimeId,
    required this.scheduledAt,
  });

  final String medicationId;
  final int scheduleTimeId;
  final DateTime scheduledAt;
}

// Buckets used by the today screen.
enum TodayDoseBucket { upcoming, completed, missed, skipped }

// One item in the today feed with bucket and status info.
class TodayDoseItem {
  TodayDoseItem({
    required this.occurrence,
    required this.medicationName,
    required this.bucket,
    required this.eventStatus,
    required this.takenAt,
  });

  final DoseOccurrence occurrence;
  final String medicationName;
  final TodayDoseBucket bucket;

  /// Raw [DoseEvents.status] (0..3).
  final int eventStatus;

  final DateTime? takenAt;
}

// The main logic layer for occurrence generation and dose reconciliation.
class DosingService {
  DosingService({
    required AppDatabase db,
    required MedicationDao medicationDao,
    required DoseScheduleDao doseScheduleDao,
    required DoseEventDao doseEventDao,
    required UserSettingsDao userSettingsDao,
  }) : _db = db,
       _medicationDao = medicationDao,
       _doseScheduleDao = doseScheduleDao,
       _doseEventDao = doseEventDao,
       _userSettingsDao = userSettingsDao;

  final AppDatabase _db;
  final MedicationDao _medicationDao;
  final DoseScheduleDao _doseScheduleDao;
  final DoseEventDao _doseEventDao;
  final UserSettingsDao _userSettingsDao;

  List<DoseOccurrence> generateOccurrencesForDay({
    required DateTime day,
    required List<DoseScheduleTime> scheduleTimes,
  }) {
    // Build the day's occurrences from schedule rows.
    tzdata.initializeTimeZones();

    final occurrences = <DoseOccurrence>[];

    for (final st in scheduleTimes) {
      if (!st.isEnabled) continue;

      final location = st.timezone != null
          ? tz.getLocation(st.timezone!)
          : tz.local;

      final dayInLocation = tz.TZDateTime.from(day, location);
      final dayYear = dayInLocation.year;
      final dayMonth = dayInLocation.month;
      final dayDay = dayInLocation.day;
      final weekday = dayInLocation.weekday;

      if (!_isDayWithinRange(
        dayInLocation,
        st.startDate,
        st.endDate,
        location,
      )) {
        continue;
      }

      final enabledForDay = _isScheduleEnabledForDay(
        dayInLocation,
        st,
        weekday,
        location,
      );
      if (!enabledForDay) continue;

      final scheduledAt = tz.TZDateTime(
        location,
        dayYear,
        dayMonth,
        dayDay,
        st.timeHour,
        st.timeMinute,
      );

      occurrences.add(
        DoseOccurrence(
          medicationId: st.medicationId,
          scheduleTimeId: st.id,
          scheduledAt: scheduledAt,
        ),
      );
    }

    return occurrences;
  }

  bool _isScheduleEnabledForDay(
    tz.TZDateTime dayInLocation,
    DoseScheduleTime st,
    int weekday,
    tz.Location location,
  ) {
    // Weekly bitmask schedules or repeating interval schedules.
    // Positive values keep the existing weekly bitmask behavior.
    if (st.daysOfWeekBitmask > 0) {
      final bitIndex = weekday - 1;
      return ((st.daysOfWeekBitmask >> bitIndex) & 1) == 1;
    }

    // Negative values represent interval schedules: every N days.
    final intervalDays = (-st.daysOfWeekBitmask).clamp(1, 365).toInt();
    final start = tz.TZDateTime.from(st.startDate, location);
    final startOnly = tz.TZDateTime(
      location,
      start.year,
      start.month,
      start.day,
    );
    final dayOnly = tz.TZDateTime(
      location,
      dayInLocation.year,
      dayInLocation.month,
      dayInLocation.day,
    );

    final daysSinceStart = dayOnly.difference(startOnly).inDays;
    return daysSinceStart >= 0 && daysSinceStart % intervalDays == 0;
  }

  bool _isDayWithinRange(
    tz.TZDateTime day,
    DateTime startDate,
    DateTime? endDate,
    tz.Location location,
  ) {
    // Stay inside the start/end date window.
    final start = tz.TZDateTime.from(startDate, location);
    final startOnly = tz.TZDateTime(
      location,
      start.year,
      start.month,
      start.day,
    );

    final endOnly = endDate == null
        ? null
        : (() {
            final end = tz.TZDateTime.from(endDate, location);
            return tz.TZDateTime(location, end.year, end.month, end.day);
          })();

    final dayOnly = tz.TZDateTime(location, day.year, day.month, day.day);

    if (dayOnly.isBefore(startOnly)) return false;
    if (endOnly != null && dayOnly.isAfter(endOnly)) return false;
    return true;
  }

  Future<void> reconcileMissedDoses({
    required DateTime now,
    int daysBack = 2,
  }) async {
    // Mark old unhandled occurrences as missed.
    final settings = await _userSettingsDao.getSingleton();
    final graceMinutes = settings?.doseGraceMinutes ?? 120;

    final startDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysBack));

    final meds = await _medicationDao.getAll();

    for (var i = 0; i <= daysBack; i++) {
      final day = startDay.add(Duration(days: i));

      for (final med in meds.where((m) => m.isActive == true)) {
        final times = await _doseScheduleDao.getByMedicationId(med.id);
        final occurrences = generateOccurrencesForDay(
          day: day,
          scheduleTimes: times,
        );

        for (final occ in occurrences) {
          final isOverdue = occ.scheduledAt.isBefore(
            now.subtract(Duration(minutes: graceMinutes)),
          );
          if (!isOverdue) continue;

          final existing = await _doseEventDao.getByMedicationAndScheduledAt(
            medicationId: occ.medicationId,
            scheduledAt: occ.scheduledAt,
          );

          final isAlreadyComplete =
              existing != null &&
              (existing.status == doseStatusTaken ||
                  existing.status == doseStatusSkipped);

          if (isAlreadyComplete) continue;

          await _doseEventDao.upsert(
            DoseEventsCompanion(
              medicationId: Value(occ.medicationId),
              doseScheduleTimeId: Value(occ.scheduleTimeId),
              scheduledAt: Value(occ.scheduledAt),
              status: const Value(doseStatusMissed),
              takenAt: const Value.absent(),
              source: const Value(doseSourceNotification),
            ),
          );
        }
      }
    }
  }

  Future<void> confirmDoseTaken({
    required String medicationId,
    required int scheduleTimeId,
    required DateTime scheduledAt,
    DateTime? takenAt,
    int source = doseSourceManual,
  }) async {
    // Record a taken dose and adjust inventory in one transaction.
    final actualTakenAt = takenAt ?? DateTime.now();

    await _db.transaction(() async {
      final med = await _medicationDao.getById(medicationId);
      if (med == null) return;

      final existing = await _doseEventDao.getByMedicationAndScheduledAt(
        medicationId: medicationId,
        scheduledAt: scheduledAt,
      );

      final alreadyTaken =
          existing != null && existing.status == doseStatusTaken;
      if (alreadyTaken) return;

      final newTotal = (med.totalPills - med.pillPerDose).clamp(0, 1 << 30);

      if (existing == null || existing.status != doseStatusTaken) {
        await _medicationDao.updateTotalPills(medicationId, newTotal);
      }

      await _doseEventDao.upsert(
        DoseEventsCompanion(
          medicationId: Value(medicationId),
          doseScheduleTimeId: Value(scheduleTimeId),
          scheduledAt: Value(scheduledAt),
          status: const Value(doseStatusTaken),
          takenAt: Value(actualTakenAt),
          source: Value(source),
        ),
      );
    });
  }

  /// Records an intentional skip without changing pill inventory.
  Future<void> markDoseSkipped({
    required String medicationId,
    required int scheduleTimeId,
    required DateTime scheduledAt,
    int source = doseSourceManual,
  }) async {
    await _db.transaction(() async {
      final existing = await _doseEventDao.getByMedicationAndScheduledAt(
        medicationId: medicationId,
        scheduledAt: scheduledAt,
      );

      final scheduleId = existing?.doseScheduleTimeId ?? scheduleTimeId;

      await _doseEventDao.upsert(
        DoseEventsCompanion(
          medicationId: Value(medicationId),
          doseScheduleTimeId: Value(scheduleId),
          scheduledAt: Value(scheduledAt),
          status: const Value(doseStatusSkipped),
          takenAt: const Value.absent(),
          source: Value(source),
        ),
      );
    });
  }

  Future<void> updateDoseEventStatus({
    required String medicationId,
    required DateTime scheduledAt,
    required int newStatus,
    DateTime? takenAt,
    int source = doseSourceManual,
  }) async {
    await _db.transaction(() async {
      final med = await _medicationDao.getById(medicationId);
      if (med == null) return;

      final existing = await _doseEventDao.getByMedicationAndScheduledAt(
        medicationId: medicationId,
        scheduledAt: scheduledAt,
      );

      final previousStatus = existing?.status ?? doseStatusScheduled;

      var newTotal = med.totalPills;
      if (previousStatus != doseStatusTaken && newStatus == doseStatusTaken) {
        newTotal = (newTotal - med.pillPerDose).clamp(0, 1 << 30).toInt();
      }

      if (previousStatus == doseStatusTaken && newStatus != doseStatusTaken) {
        newTotal = (newTotal + med.pillPerDose).clamp(0, 1 << 30).toInt();
      }

      if (newTotal != med.totalPills) {
        await _medicationDao.updateTotalPills(medicationId, newTotal);
      }

      final resolvedTakenAt = newStatus == doseStatusTaken
          ? (takenAt ?? existing?.takenAt ?? DateTime.now())
          : null;

      await _doseEventDao.upsert(
        DoseEventsCompanion(
          medicationId: Value(medicationId),
          doseScheduleTimeId: existing?.doseScheduleTimeId == null
              ? const Value.absent()
              : Value(existing!.doseScheduleTimeId),
          scheduledAt: Value(scheduledAt),
          status: Value(newStatus),
          takenAt: Value(resolvedTakenAt),
          source: Value(source),
        ),
      );
    });
  }

  Future<int> getAdaptiveReminderOffsetMinutes({
    required String medicationId,
    int lookbackDays = 21,
    int leadMinutes = 10,
  }) async {
    final end = DateTime.now();
    final start = DateTime(
      end.year,
      end.month,
      end.day,
    ).subtract(Duration(days: lookbackDays));

    final events = await _doseEventDao.getForMedicationInRange(
      medicationId: medicationId,
      start: start,
      end: end.add(const Duration(days: 1)),
    );

    final takenEvents = events
        .where(
          (event) => event.status == doseStatusTaken && event.takenAt != null,
        )
        .toList(growable: false);
    if (takenEvents.isEmpty) return 0;

    final deltas = takenEvents
        .map((event) => event.takenAt!.difference(event.scheduledAt).inMinutes)
        .toList(growable: false);

    final averageDelta = deltas.reduce((a, b) => a + b) / deltas.length;
    final offset = averageDelta.round() - leadMinutes;
    return offset.clamp(-60, 60);
  }

  Future<double> getDailyAdherencePercent({
    required String medicationId,
    required DateTime day,
  }) async {
    final med = await _medicationDao.getById(medicationId);
    if (med == null) return 0;

    final times = await _doseScheduleDao.getByMedicationId(medicationId);
    final occurrences = generateOccurrencesForDay(
      day: day,
      scheduleTimes: times,
    );

    if (occurrences.isEmpty) return 0;

    var takenOrSkipped = 0;
    for (final occ in occurrences) {
      final event = await _doseEventDao.getByMedicationAndScheduledAt(
        medicationId: medicationId,
        scheduledAt: occ.scheduledAt,
      );

      if (event == null) continue;
      if (event.status == doseStatusTaken ||
          event.status == doseStatusSkipped) {
        takenOrSkipped++;
      }
    }

    return takenOrSkipped / occurrences.length;
  }

  Future<List<double>> getWeeklyAdherenceSummaryPercentages({
    required String medicationId,
    required DateTime endDay,
  }) async {
    final results = <double>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(
        endDay.year,
        endDay.month,
        endDay.day,
      ).subtract(Duration(days: i));
      final pct = await getDailyAdherencePercent(
        medicationId: medicationId,
        day: day,
      );
      results.add(pct);
    }
    return results;
  }

  /// Monday (index 0) through Sunday (index 6) for the week containing [referenceDay].
  Future<List<double>> getMondaySundayWeekDailyPercents({
    required String medicationId,
    required DateTime referenceDay,
  }) async {
    final cal = DateTime(
      referenceDay.year,
      referenceDay.month,
      referenceDay.day,
    );
    final daysFromMonday = (cal.weekday - DateTime.monday) % 7;
    final monday = cal.subtract(Duration(days: daysFromMonday));
    final out = <double>[];
    for (var d = 0; d < 7; d++) {
      final day = monday.add(Duration(days: d));
      out.add(
        await getDailyAdherencePercent(medicationId: medicationId, day: day),
      );
    }
    return out;
  }

  /// Combined adherence across all active medications for a single calendar day.
  Future<double> getAggregateDailyAdherencePercent({
    required DateTime day,
  }) async {
    final meds = await _medicationDao.getAll();
    var totalOcc = 0;
    var doneOcc = 0;
    for (final med in meds.where((m) => m.isActive)) {
      final times = await _doseScheduleDao.getByMedicationId(med.id);
      final occurrences = generateOccurrencesForDay(
        day: day,
        scheduleTimes: times,
      );
      for (final occ in occurrences) {
        totalOcc++;
        final event = await _doseEventDao.getByMedicationAndScheduledAt(
          medicationId: occ.medicationId,
          scheduledAt: occ.scheduledAt,
        );
        if (event != null &&
            (event.status == doseStatusTaken ||
                event.status == doseStatusSkipped)) {
          doneOcc++;
        }
      }
    }
    if (totalOcc == 0) return 0;
    return doneOcc / totalOcc;
  }

  /// Aggregate Mon–Sun daily percents for the week containing [referenceDay].
  Future<List<double>> getAggregateMondaySundayWeekDailyPercents({
    required DateTime referenceDay,
  }) async {
    final cal = DateTime(
      referenceDay.year,
      referenceDay.month,
      referenceDay.day,
    );
    final daysFromMonday = (cal.weekday - DateTime.monday) % 7;
    final monday = cal.subtract(Duration(days: daysFromMonday));
    final out = <double>[];
    for (var d = 0; d < 7; d++) {
      final day = monday.add(Duration(days: d));
      out.add(await getAggregateDailyAdherencePercent(day: day));
    }
    return out;
  }

  /// Earliest scheduled dose not marked taken/skipped within the next [lookaheadDays].
  Future<({DateTime scheduledAt, String medicationName})?>
  findEarliestPendingDose({
    required DateTime now,
    int lookaheadDays = 14,
  }) async {
    final meds = await _medicationDao.getAll();
    ({DateTime scheduledAt, String medicationName})? best;

    for (var offset = 0; offset <= lookaheadDays; offset++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: offset));
      for (final med in meds.where((m) => m.isActive)) {
        final times = await _doseScheduleDao.getByMedicationId(med.id);
        final occs = generateOccurrencesForDay(day: day, scheduleTimes: times);
        for (final occ in occs) {
          final event = await _doseEventDao.getByMedicationAndScheduledAt(
            medicationId: occ.medicationId,
            scheduledAt: occ.scheduledAt,
          );
          final status = event?.status ?? doseStatusScheduled;
          if (status == doseStatusTaken || status == doseStatusSkipped) {
            continue;
          }
          final candidate = (
            scheduledAt: occ.scheduledAt,
            medicationName: med.name,
          );
          if (best == null || occ.scheduledAt.isBefore(best.scheduledAt)) {
            best = candidate;
          }
        }
      }
    }
    return best;
  }

  Future<DateTime?> predictRefillDate({
    required String medicationId,
    required DateTime now,
    int lookaheadDays = 180,
  }) async {
    final med = await _medicationDao.getById(medicationId);
    if (med == null) return null;
    if (med.totalPills <= 0) return now;

    final times = await _doseScheduleDao.getByMedicationId(medicationId);

    final occurrences = <DoseOccurrence>[];
    for (var i = 0; i <= lookaheadDays; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      occurrences.addAll(
        generateOccurrencesForDay(day: day, scheduleTimes: times),
      );
    }

    occurrences.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    var remaining = med.totalPills;
    for (final occ in occurrences) {
      if (!occ.scheduledAt.isAfter(now)) continue;

      remaining -= med.pillPerDose;
      if (remaining <= 0) {
        return occ.scheduledAt;
      }
    }

    return null;
  }

  Future<DateTime?> getLowPillWarningFireAt({
    required String medicationId,
    required DateTime now,
    int lookaheadDays = 180,
  }) async {
    final settings = await _userSettingsDao.getSingleton();
    final leadDays = settings?.lowPillWarningDays ?? 3;

    final refillDate = await predictRefillDate(
      medicationId: medicationId,
      now: now,
      lookaheadDays: lookaheadDays,
    );
    if (refillDate == null) return null;

    final windowStart = refillDate.subtract(Duration(days: leadDays));
    if (now.isAfter(refillDate)) {
      return now;
    }

    return windowStart.isBefore(now) ? now : windowStart;
  }
}

class StreakService {
  StreakService({
    required MedicationDao medicationDao,
    required DoseScheduleDao doseScheduleDao,
    required DoseEventDao doseEventDao,
  }) : _doseScheduleDao = doseScheduleDao,
       _doseEventDao = doseEventDao;

  final DoseScheduleDao _doseScheduleDao;
  final DoseEventDao _doseEventDao;

  Future<int> getPerfectDayStreak({
    required String medicationId,
    required DateTime now,
    int maxLookbackDays = 365,
  }) async {
    final times = await _doseScheduleDao.getByMedicationId(medicationId);

    int streak = 0;

    for (var offset = 0; offset < maxLookbackDays; offset++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: offset));

      final occurrences = _generateOccurrencesForDay(
        day: day,
        scheduleTimes: times,
      );

      if (occurrences.isEmpty) break;

      final allTaken = await Future.wait(
        occurrences.map((occ) async {
          final event = await _doseEventDao.getByMedicationAndScheduledAt(
            medicationId: medicationId,
            scheduledAt: occ.scheduledAt,
          );
          return event != null && event.status == doseStatusTaken;
        }),
      ).then((results) => results.every((v) => v));

      if (!allTaken) break;
      streak++;
    }

    return streak;
  }

  List<DoseOccurrence> _generateOccurrencesForDay({
    required DateTime day,
    required List<DoseScheduleTime> scheduleTimes,
  }) {
    tzdata.initializeTimeZones();

    final occurrences = <DoseOccurrence>[];

    for (final st in scheduleTimes) {
      if (!st.isEnabled) continue;

      final location = st.timezone != null
          ? tz.getLocation(st.timezone!)
          : tz.local;
      final dayInLocation = tz.TZDateTime.from(day, location);
      final weekday = dayInLocation.weekday;
      final dayYear = dayInLocation.year;
      final dayMonth = dayInLocation.month;
      final dayDay = dayInLocation.day;

      final enabledForDay = _isScheduleEnabledForDay(
        dayInLocation: dayInLocation,
        st: st,
        weekday: weekday,
        location: location,
      );
      if (!enabledForDay) continue;

      final scheduledAt = tz.TZDateTime(
        location,
        dayYear,
        dayMonth,
        dayDay,
        st.timeHour,
        st.timeMinute,
      );

      if (_isInRange(dayInLocation, st, location)) {
        occurrences.add(
          DoseOccurrence(
            medicationId: st.medicationId,
            scheduleTimeId: st.id,
            scheduledAt: scheduledAt,
          ),
        );
      }
    }

    return occurrences;
  }

  bool _isScheduleEnabledForDay({
    required tz.TZDateTime dayInLocation,
    required DoseScheduleTime st,
    required int weekday,
    required tz.Location location,
  }) {
    if (st.daysOfWeekBitmask > 0) {
      final bitIndex = weekday - 1;
      return ((st.daysOfWeekBitmask >> bitIndex) & 1) == 1;
    }

    final intervalDays = (-st.daysOfWeekBitmask).clamp(1, 365).toInt();
    final start = tz.TZDateTime.from(st.startDate, location);
    final startOnly = tz.TZDateTime(
      location,
      start.year,
      start.month,
      start.day,
    );
    final dayOnly = tz.TZDateTime(
      location,
      dayInLocation.year,
      dayInLocation.month,
      dayInLocation.day,
    );
    final daysSinceStart = dayOnly.difference(startOnly).inDays;
    return daysSinceStart >= 0 && daysSinceStart % intervalDays == 0;
  }

  bool _isInRange(DateTime day, DoseScheduleTime st, tz.Location location) {
    final start = tz.TZDateTime.from(st.startDate, location);
    final dayOnly = tz.TZDateTime(location, day.year, day.month, day.day);
    final startOnly = tz.TZDateTime(
      location,
      start.year,
      start.month,
      start.day,
    );

    final endOnly = st.endDate == null
        ? null
        : (() {
            final end = tz.TZDateTime.from(st.endDate!, location);
            return tz.TZDateTime(location, end.year, end.month, end.day);
          })();

    if (dayOnly.isBefore(startOnly)) return false;
    if (endOnly != null && dayOnly.isAfter(endOnly)) return false;
    return true;
  }
}
