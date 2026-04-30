import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// Main Drift database for meds, schedules, events, and settings.
@DriftDatabase(
  tables: [Medications, DoseScheduleTimes, DoseEvents, UserSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'medication_app'));

  @override
  int get schemaVersion => 1;
}

// Medication table, basically the core data for the app.
class Medications extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get strength => text().nullable()();

  TextColumn get form => text().nullable()();

  IntColumn get totalPills => integer()();

  IntColumn get pillPerDose => integer()();

  IntColumn get refillThreshold => integer()();

  TextColumn get notes => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// Each row is one scheduled dose time for a medication.
class DoseScheduleTimes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get medicationId =>
      text().references(Medications, #id, onDelete: KeyAction.cascade)();

  IntColumn get timeHour => integer()();
  IntColumn get timeMinute => integer()();

  IntColumn get daysOfWeekBitmask =>
      integer().withDefault(const Constant(127))();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  TextColumn get timezone => text().nullable()();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
}

// Stores whether a dose was taken, missed, or skipped.
@TableIndex(
  name: 'unique_dose_event_per_med_and_time',
  columns: {#medicationId, #scheduledAt},
  unique: true,
)
class DoseEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get medicationId =>
      text().references(Medications, #id, onDelete: KeyAction.cascade)();

  IntColumn get doseScheduleTimeId =>
      integer().nullable().references(DoseScheduleTimes, #id)();

  DateTimeColumn get scheduledAt => dateTime()();

  DateTimeColumn get takenAt => dateTime().nullable()();

  IntColumn get status => integer().withDefault(const Constant(0))();

  IntColumn get source => integer().withDefault(const Constant(0))();
}

// Small settings table so the app can remember defaults.
class UserSettings extends Table {
  IntColumn get id => integer()();

  IntColumn get doseGraceMinutes =>
      integer().withDefault(const Constant(120))();

  IntColumn get lowPillWarningDays =>
      integer().withDefault(const Constant(3))();

  TextColumn get lastTimezone => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// DAO for the medication table.
@DriftAccessor(tables: [Medications])
class MedicationDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationDaoMixin {
  MedicationDao(super.db);

  Future<List<Medication>> getAll() async {
    // Keep the list sorted by name because that is less chaotic.
    final query = select(medications)
      ..orderBy([
        (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
      ]);
    return query.get();
  }

  Future<void> normalizeStoredUserText() async {
    // Clean up old text so names and notes look a bit nicer.
    final rows = await getAll();
    for (final med in rows) {
      final normalizedName = _titleCaseUserInput(med.name);
      final normalizedStrength = _nullableTitleCase(med.strength);
      final normalizedForm = _nullableTitleCase(med.form);
      final normalizedNotes = _nullableSentenceCase(med.notes);

      if (normalizedName == med.name &&
          normalizedStrength == med.strength &&
          normalizedForm == med.form &&
          normalizedNotes == med.notes) {
        continue;
      }

      await (update(medications)..where((t) => t.id.equals(med.id))).write(
        MedicationsCompanion(
          name: normalizedName.isEmpty
              ? const Value.absent()
              : Value(normalizedName),
          strength: Value(normalizedStrength),
          form: Value(normalizedForm),
          notes: Value(normalizedNotes),
        ),
      );
    }
  }

  Stream<List<Medication>> watchAll() {
    final query = select(medications)
      ..orderBy([
        (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
      ]);
    return query.watch();
  }

  Future<Medication?> getById(String id) {
    return (select(
      medications,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(MedicationsCompanion med) async {
    await into(medications).insertOnConflictUpdate(med);
  }

  Future<void> updateTotalPills(String id, int totalPills) async {
    await (update(medications)..where((t) => t.id.equals(id))).write(
      MedicationsCompanion(totalPills: Value(totalPills)),
    );
  }

  Future<void> deleteById(String id) async {
    await (delete(medications)..where((t) => t.id.equals(id))).go();
  }

  static String? _nullableTitleCase(String? value) {
    if (value == null) return null;
    final normalized = _titleCaseUserInput(value);
    return normalized.isEmpty ? null : normalized;
  }

  static String? _nullableSentenceCase(String? value) {
    if (value == null) return null;
    final normalized = _sentenceCaseUserInput(value);
    return normalized.isEmpty ? null : normalized;
  }

  static String _titleCaseUserInput(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length <= 3 && word == word.toUpperCase()) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  static String _sentenceCaseUserInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}

// DAO for scheduled dose times.
@DriftAccessor(tables: [DoseScheduleTimes])
class DoseScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$DoseScheduleDaoMixin {
  DoseScheduleDao(super.db);

  Stream<List<DoseScheduleTime>> watchAll() {
    // Also sorted, because random schedule order would be annoying.
    final query = select(doseScheduleTimes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.medicationId, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.timeHour, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.timeMinute, mode: OrderingMode.asc),
      ]);
    return query.watch();
  }

  Future<List<DoseScheduleTime>> getByMedicationId(String medicationId) {
    return (select(doseScheduleTimes)
          ..where((t) => t.medicationId.equals(medicationId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.timeHour, mode: OrderingMode.asc),
            (t) =>
                OrderingTerm(expression: t.timeMinute, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<void> deleteByMedicationId(String medicationId) async {
    await (delete(
      doseScheduleTimes,
    )..where((t) => t.medicationId.equals(medicationId))).go();
  }

  Future<void> insertTimes(List<DoseScheduleTimesCompanion> times) async {
    await batch((b) {
      for (final t in times) {
        b.insert(doseScheduleTimes, t);
      }
    });
  }

  Future<void> clearAllTimezones() async {
    await update(
      doseScheduleTimes,
    ).write(const DoseScheduleTimesCompanion(timezone: Value(null)));
  }

  Future<void> setNullTimezonesTo(String timezoneName) async {
    await (update(doseScheduleTimes)..where((t) => t.timezone.isNull())).write(
      DoseScheduleTimesCompanion(timezone: Value(timezoneName)),
    );
  }
}

// DAO for event rows like taken/missed/skipped.
@DriftAccessor(tables: [DoseEvents])
class DoseEventDao extends DatabaseAccessor<AppDatabase>
    with _$DoseEventDaoMixin {
  DoseEventDao(super.db);

  Stream<List<DoseEvent>> watchAll() {
    final query = select(doseEvents)
      ..orderBy([
        (t) => OrderingTerm(expression: t.scheduledAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  Future<List<DoseEvent>> getForMedicationInRange({
    required String medicationId,
    required DateTime start,
    required DateTime end,
  }) {
    return (select(doseEvents)
          ..where((t) => t.medicationId.equals(medicationId))
          ..where((t) => t.scheduledAt.isBiggerOrEqualValue(start))
          ..where((t) => t.scheduledAt.isSmallerThanValue(end)))
        .get();
  }

  Future<void> upsert(DoseEventsCompanion event) async {
    await into(doseEvents).insert(
      event,
      onConflict: DoUpdate(
        (_) => event,
        target: [doseEvents.medicationId, doseEvents.scheduledAt],
      ),
    );
  }

  Future<DoseEvent?> getByMedicationAndScheduledAt({
    required String medicationId,
    required DateTime scheduledAt,
  }) {
    return (select(doseEvents)
          ..where((t) => t.medicationId.equals(medicationId))
          ..where((t) => t.scheduledAt.equals(scheduledAt)))
        .getSingleOrNull();
  }
}

@DriftAccessor(tables: [UserSettings])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.db);

  Future<UserSetting?> getSingleton() {
    return (select(
      userSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
  }

  Future<void> upsertSingleton(UserSettingsCompanion settings) async {
    await into(userSettings).insertOnConflictUpdate(settings);
  }

  Future<void> ensureDefaultSingleton() async {
    final existing = await getSingleton();
    if (existing != null) return;
    await upsertSingleton(
      UserSettingsCompanion(
        id: const Value(1),
        doseGraceMinutes: const Value(120),
        lowPillWarningDays: const Value(3),
        lastTimezone: const Value(null),
      ),
    );
  }
}
