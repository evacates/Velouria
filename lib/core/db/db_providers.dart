import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

// Shared database instance for the whole app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Tiny provider wrappers so screens can grab DAOs fast.
final medicationDaoProvider = Provider<MedicationDao>(
  (ref) => MedicationDao(ref.watch(appDatabaseProvider)),
);

final medicationsStreamProvider = StreamProvider<List<Medication>>(
  (ref) => ref.watch(medicationDaoProvider).watchAll(),
);

final doseScheduleDaoProvider = Provider<DoseScheduleDao>(
  (ref) => DoseScheduleDao(ref.watch(appDatabaseProvider)),
);

final doseScheduleTimesStreamProvider = StreamProvider<List<DoseScheduleTime>>(
  (ref) => ref.watch(doseScheduleDaoProvider).watchAll(),
);

final doseEventDaoProvider = Provider<DoseEventDao>(
  (ref) => DoseEventDao(ref.watch(appDatabaseProvider)),
);

final doseEventsStreamProvider = StreamProvider<List<DoseEvent>>(
  (ref) => ref.watch(doseEventDaoProvider).watchAll(),
);

final userSettingsDaoProvider = Provider<UserSettingsDao>(
  (ref) => UserSettingsDao(ref.watch(appDatabaseProvider)),
);
