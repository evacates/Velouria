import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app/app_navigation.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_providers.dart';
import '../../../core/integrations/siri_shortcuts_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/settings/behavior_settings_service.dart';
import '../../../core/time/timezone_service.dart';
import '../../dosing/domain/dosing_services.dart';
import '../../medications/medication_form_screen.dart';

// Main dashboard for the current day.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  String? _errorMessage;
  bool _reloadInFlight = false;
  bool _reloadQueued = false;

  /// When multiple reloads queue, any non-silent (full) request wins for the follow-up run.
  bool _queuedReloadSilent = true;

  List<String> _allergyKeywords = const [];

  final List<TodayDoseItem> _upcoming = [];
  final List<TodayDoseItem> _completed = [];
  final List<TodayDoseItem> _missed = [];
  final List<TodayDoseItem> _skipped = [];
  final List<Medication> _refillAlerts = [];
  final Set<String> _dismissedRefillAlertIds = {};

  int _todayTotal = 0;
  int _todayDone = 0;
  int _activeMedicationCount = 0;
  double _weeklyAverage = 0;
  int _bestStreak = 0;
  bool _showStreakIndicator = true;

  @override
  void initState() {
    super.initState();
    // Watch the DB streams and kick off the first load.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllergyField());
    WidgetsBinding.instance.addObserver(this);

    ref.listenManual<AsyncValue<List<Medication>>>(
      medicationsStreamProvider,
      (medications, next) => _reloadFromDataChange(),
    );
    ref.listenManual<AsyncValue<List<DoseScheduleTime>>>(
      doseScheduleTimesStreamProvider,
      (scheduleTimes, next) => _reloadFromDataChange(),
    );
    ref.listenManual<AsyncValue<List<DoseEvent>>>(
      doseEventsStreamProvider,
      (doseEvents, next) => _reloadFromDataChange(),
    );

    _reload();
  }

  Future<void> _loadAllergyField() async {
    // Keep the warning list in sync with saved settings.
    final behavior = await BehaviorSettingsService.load();
    if (!mounted) return;
    setState(() => _allergyKeywords = behavior.allergyKeywords);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAllergyField();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _reloadFromDataChange() {
    // If the DB changes, do a quiet refresh.
    if (!mounted || _loading) return;
    _reload(silent: true);
  }

  Future<void> _openAddMedication() async {
    // Shortcut to the medication form.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MedicationFormScreen()),
    );
    await _reload();
  }

  Future<void> _openAddAllergyOrSensitivity() async {
    // Let the user add a simple allergy keyword.
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add allergy/sensitivity'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Allergy or sensitivity',
            hintText: 'e.g. penicillin',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final keyword = _formatAllergyKeyword(value ?? '');
    if (keyword.isEmpty) return;
    final keywordKey = _allergyDuplicateKey(keyword);

    final existing = _allergyKeywords.toList(growable: true);

    final alreadyExists = existing.any(
      (item) => _allergyDuplicateKey(item) == keywordKey,
    );
    if (!alreadyExists) {
      existing.add(keyword);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$keyword is already listed.')));
    }

    setState(() => _allergyKeywords = existing);
    await _saveAllergies();
  }

  Future<void> _removeAllergy(String keyword) async {
    final keywordKey = _allergyDuplicateKey(keyword);
    final existing = _allergyKeywords
        .where((item) => _allergyDuplicateKey(item) != keywordKey)
        .toList(growable: false);
    setState(() => _allergyKeywords = existing);
    await BehaviorSettingsService.setAllergyKeywordsCsv(existing.join(', '));
  }

  String _formatAllergyKeyword(String value) {
    final canonical = _allergyDuplicateKey(value);
    if (canonical.isEmpty) return '';
    return canonical
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  String _allergyDuplicateKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r'[^a-z0-9-]'), ''))
        .where((word) => word.isNotEmpty)
        .map(_singularizeAllergyWord)
        .join(' ');
  }

  String _singularizeAllergyWord(String word) {
    if (word.length > 4 && word.endsWith('ies')) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.length > 4 && word.endsWith('oes')) {
      return word.substring(0, word.length - 2);
    }
    if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  Future<void> _reload({bool silent = false}) async {
    // Heavy reload: recalc dose buckets, stats, and warning cards.
    if (_reloadInFlight) {
      _reloadQueued = true;
      _queuedReloadSilent = _queuedReloadSilent && silent;
      return;
    }

    _reloadInFlight = true;
    _queuedReloadSilent = true;
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    final nextUpcoming = <TodayDoseItem>[];
    final nextCompleted = <TodayDoseItem>[];
    final nextMissed = <TodayDoseItem>[];
    final nextSkipped = <TodayDoseItem>[];
    var nextTodayTotal = 0;
    var nextTodayDone = 0;
    var nextActiveMedicationCount = 0;
    var nextWeeklyAverage = 0.0;
    var nextBestStreak = 0;
    var nextShowStreakIndicator = _showStreakIndicator;

    try {
      final appDb = ref.read(appDatabaseProvider);
      final medicationDao = ref.read(medicationDaoProvider);
      final doseScheduleDao = ref.read(doseScheduleDaoProvider);
      final doseEventDao = ref.read(doseEventDaoProvider);
      final userSettingsDao = ref.read(userSettingsDaoProvider);

      final dosingService = DosingService(
        db: appDb,
        medicationDao: medicationDao,
        doseScheduleDao: doseScheduleDao,
        doseEventDao: doseEventDao,
        userSettingsDao: userSettingsDao,
      );

      final now = DateTime.now();
      await dosingService.reconcileMissedDoses(now: now, daysBack: 7);
      final behavior = await BehaviorSettingsService.load();
      nextShowStreakIndicator = behavior.showStreakIndicator;

      await medicationDao.normalizeStoredUserText();
      final meds = await medicationDao.getAll();
      final activeMeds = meds.where((m) => m.isActive).toList();
      final refillAlertResults = await Future.wait(
        activeMeds.map((med) async {
          if (med.totalPills <= med.refillThreshold) return med;
          final fireAt = await dosingService.getLowPillWarningFireAt(
            medicationId: med.id,
            now: now,
          );
          return fireAt == null || fireAt.isAfter(now) ? null : med;
        }),
      );
      final refillAlerts = refillAlertResults.nonNulls.toList(growable: false);
      nextActiveMedicationCount = activeMeds.length;
      final dayOccurrencesByMedication = <String, List<DoseOccurrence>>{};

      final occurrenceAndWeeklyResults = await Future.wait(
        activeMeds.map((med) async {
          final times = await doseScheduleDao.getByMedicationId(med.id);
          final occs = dosingService.generateOccurrencesForDay(
            day: now,
            scheduleTimes: times,
          );

          final weekly = await dosingService
              .getWeeklyAdherenceSummaryPercentages(
                medicationId: med.id,
                endDay: now,
              );
          return (medicationId: med.id, occurrences: occs, weekly: weekly);
        }),
      );

      var weeklySum = 0.0;
      var weeklyCount = 0;
      for (final result in occurrenceAndWeeklyResults) {
        dayOccurrencesByMedication[result.medicationId] = result.occurrences;
        final weekly = result.weekly;
        if (weekly.isNotEmpty) {
          weeklySum += weekly.reduce((a, b) => a + b) / weekly.length;
          weeklyCount++;
        }
      }

      final streakService = StreakService(
        medicationDao: medicationDao,
        doseScheduleDao: doseScheduleDao,
        doseEventDao: doseEventDao,
      );

      final streaks = await Future.wait(
        activeMeds.map(
          (med) => streakService.getPerfectDayStreak(
            medicationId: med.id,
            now: now,
            maxLookbackDays: 365,
          ),
        ),
      );
      final bestStreak = streaks.isEmpty
          ? 0
          : streaks.reduce((a, b) => a > b ? a : b);

      for (final med in activeMeds) {
        final occs = dayOccurrencesByMedication[med.id] ?? const [];
        final eventResults = await Future.wait(
          occs.map((occ) async {
            final event = await doseEventDao.getByMedicationAndScheduledAt(
              medicationId: occ.medicationId,
              scheduledAt: occ.scheduledAt,
            );
            return (occurrence: occ, event: event);
          }),
        );

        for (final result in eventResults) {
          final occ = result.occurrence;
          final event = result.event;
          nextTodayTotal++;

          if (event != null) {
            final bucket = switch (event.status) {
              doseStatusTaken => TodayDoseBucket.completed,
              doseStatusMissed => TodayDoseBucket.missed,
              doseStatusSkipped => TodayDoseBucket.skipped,
              _ => TodayDoseBucket.upcoming,
            };

            final item = TodayDoseItem(
              occurrence: occ,
              medicationName: med.name,
              bucket: bucket,
              eventStatus: event.status,
              takenAt: event.takenAt,
            );

            switch (bucket) {
              case TodayDoseBucket.completed:
                nextCompleted.add(item);
                nextTodayDone++;
                break;
              case TodayDoseBucket.missed:
                nextMissed.add(item);
                break;
              case TodayDoseBucket.skipped:
                nextSkipped.add(item);
                nextTodayDone++;
                break;
              case TodayDoseBucket.upcoming:
                nextUpcoming.add(item);
            }
          } else {
            final isUpcoming = occ.scheduledAt.isAfter(now);
            final bucket = isUpcoming
                ? TodayDoseBucket.upcoming
                : TodayDoseBucket.missed;

            final item = TodayDoseItem(
              occurrence: occ,
              medicationName: med.name,
              bucket: bucket,
              eventStatus: doseStatusScheduled,
              takenAt: null,
            );

            if (bucket == TodayDoseBucket.upcoming) {
              nextUpcoming.add(item);
            } else {
              nextMissed.add(item);
            }
          }
        }
      }

      nextWeeklyAverage = weeklyCount == 0 ? 0 : (weeklySum / weeklyCount);
      nextBestStreak = bestStreak;

      if (!mounted) return;
      setState(() {
        _upcoming
          ..clear()
          ..addAll(nextUpcoming);
        _completed
          ..clear()
          ..addAll(nextCompleted);
        _missed
          ..clear()
          ..addAll(nextMissed);
        _skipped
          ..clear()
          ..addAll(nextSkipped);
        _refillAlerts
          ..clear()
          ..addAll(refillAlerts);
        _todayTotal = nextTodayTotal;
        _todayDone = nextTodayDone;
        _activeMedicationCount = nextActiveMedicationCount;
        _weeklyAverage = nextWeeklyAverage;
        _bestStreak = nextBestStreak;
        _showStreakIndicator = nextShowStreakIndicator;
        _errorMessage = null;
      });

      await _writeIosDaySnapshot();
    } catch (error, stackTrace) {
      debugPrint('TodayScreen reload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      _reloadInFlight = false;
      if (mounted) {
        setState(() => _loading = false);

        if (_reloadQueued) {
          _reloadQueued = false;
          final runSilent = _queuedReloadSilent;
          _queuedReloadSilent = true;
          _reload(silent: runSilent);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => AppNavigationController.showSettings(),
          ),
        ],
      ),
      body: _loading
          ? const _CalmLoadingState()
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load today\'s doses.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                const Positioned.fill(child: _CelestialBackdrop()),
                if (_activeMedicationCount == 0)
                  _EmptyMedicationHome(onAddMedication: _openAddMedication)
                else
                  RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      key: const ValueKey('today_home_content'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                      children: [
                        for (final alert in _refillAlerts.where(
                          (med) => !_dismissedRefillAlertIds.contains(med.id),
                        )) ...[
                          _RefillAlertCard(
                            medication: alert,
                            onDismiss: () {
                              setState(
                                () => _dismissedRefillAlertIds.add(alert.id),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        _DoseyWelcomeCard(
                          activeMedicationCount: _activeMedicationCount,
                          todayDone: _todayDone,
                          todayTotal: _todayTotal,
                          onAddMedication: _openAddMedication,
                          onCareTap: AppNavigationController.showMedications,
                        ),
                        const SizedBox(height: 24),
                        _AdherenceVisualCard(
                          todayDone: _todayDone,
                          todayTotal: _todayTotal,
                          weeklyAverage: _weeklyAverage,
                          showStreak: _showStreakIndicator,
                          bestStreak: _bestStreak,
                        ),
                        const SizedBox(height: 24),
                        _HomeOverviewCard(
                          takenDoses: _completed.length,
                          upcomingDoses: _upcoming.length,
                          missedDoses: _missed.length,
                          skippedDoses: _skipped.length,
                          upcomingItems: _upcoming,
                          onCategoryTap: _showDoseCategorySheet,
                          onUpcomingTaken: _confirmDoseTaken,
                        ),
                        const SizedBox(height: 24),
                        _AllergiesCard(
                          items: _allergyKeywords,
                          onAdd: _openAddAllergyOrSensitivity,
                          onRemove: _removeAllergy,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _showDoseCategorySheet(TodayDoseBucket bucket) async {
    late final String title;
    late final List<TodayDoseItem> items;

    switch (bucket) {
      case TodayDoseBucket.upcoming:
        title = 'Upcoming doses';
        items = List<TodayDoseItem>.from(_upcoming);
        break;
      case TodayDoseBucket.completed:
        title = 'Taken doses';
        items = List<TodayDoseItem>.from(_completed);
        break;
      case TodayDoseBucket.missed:
        title = 'Missed doses';
        items = List<TodayDoseItem>.from(_missed);
        break;
      case TodayDoseBucket.skipped:
        title = 'Skipped doses';
        items = List<TodayDoseItem>.from(_skipped);
        break;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  items.isEmpty ? 'No doses here.' : 'Change a dose status.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No doses here.')),
                  )
                else
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _DoseRow(
                          item: item,
                          onStatusSelected: (rowItem, newStatus) async {
                            await _updateDoseStatus(
                              rowItem,
                              newStatus: newStatus,
                            );
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                          },
                          onTakenTimeEditRequested: (rowItem) async {
                            await _editTakenTime(rowItem);
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDoseTaken(TodayDoseItem item) async {
    await _updateDoseStatus(item, newStatus: doseStatusTaken);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dose confirmed')));
  }

  Future<void> _updateDoseStatus(
    TodayDoseItem item, {
    required int newStatus,
    DateTime? takenAt,
  }) async {
    final appDb = ref.read(appDatabaseProvider);
    final medicationDao = ref.read(medicationDaoProvider);
    final doseScheduleDao = ref.read(doseScheduleDaoProvider);
    final doseEventDao = ref.read(doseEventDaoProvider);
    final userSettingsDao = ref.read(userSettingsDaoProvider);

    final dosingService = DosingService(
      db: appDb,
      medicationDao: medicationDao,
      doseScheduleDao: doseScheduleDao,
      doseEventDao: doseEventDao,
      userSettingsDao: userSettingsDao,
    );

    await dosingService.updateDoseEventStatus(
      medicationId: item.occurrence.medicationId,
      scheduledAt: item.occurrence.scheduledAt,
      newStatus: newStatus,
      takenAt:
          takenAt ?? (newStatus == doseStatusTaken ? DateTime.now() : null),
      source: doseSourceManual,
    );

    if (!mounted) return;
    if (newStatus == doseStatusTaken) {
      await _rescheduleAdaptiveReminders(item.occurrence.medicationId);
    }
    await _reload(silent: true);
  }

  Future<void> _rescheduleAdaptiveReminders(String medicationId) async {
    final behavior = await BehaviorSettingsService.load();
    if (!behavior.adaptiveReminderTiming) return;

    final appDb = ref.read(appDatabaseProvider);
    final medicationDao = ref.read(medicationDaoProvider);
    final doseScheduleDao = ref.read(doseScheduleDaoProvider);
    final doseEventDao = ref.read(doseEventDaoProvider);
    final userSettingsDao = ref.read(userSettingsDaoProvider);
    final med = await medicationDao.getById(medicationId);
    if (med == null || !med.isActive) return;

    final times = await doseScheduleDao.getByMedicationId(medicationId);
    final timezoneName = await TimezoneService.getDeviceTimezoneName();
    final dosingService = DosingService(
      db: appDb,
      medicationDao: medicationDao,
      doseScheduleDao: doseScheduleDao,
      doseEventDao: doseEventDao,
      userSettingsDao: userSettingsDao,
    );
    final offset = await dosingService.getAdaptiveReminderOffsetMinutes(
      medicationId: medicationId,
    );

    await NotificationService.instance
        .cancelUpcomingDoseNotificationsForMedication(
          medication: med,
          scheduleTimes: times,
          timezoneName: timezoneName,
        );
    await NotificationService.instance
        .scheduleUpcomingDoseNotificationsForMedication(
          medication: med,
          scheduleTimes: times,
          timezoneName: timezoneName,
          reminderOffsetMinutes: offset,
        );
  }

  Future<void> _saveAllergies() async {
    await BehaviorSettingsService.setAllergyKeywordsCsv(
      _allergyKeywords.join(', '),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allergies & sensitivities saved.')),
    );
  }

  Future<void> _editTakenTime(TodayDoseItem item) async {
    final takenAt = item.takenAt ?? item.occurrence.scheduledAt;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(takenAt),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked == null) return;

    final updatedTakenAt = DateTime(
      takenAt.year,
      takenAt.month,
      takenAt.day,
      picked.hour,
      picked.minute,
    );

    await _updateDoseStatus(
      item,
      newStatus: doseStatusTaken,
      takenAt: updatedTakenAt,
    );
  }

  Future<void> _writeIosDaySnapshot() async {
    try {
      final appDb = ref.read(appDatabaseProvider);
      final medicationDao = ref.read(medicationDaoProvider);
      final doseScheduleDao = ref.read(doseScheduleDaoProvider);
      final doseEventDao = ref.read(doseEventDaoProvider);
      final userSettingsDao = ref.read(userSettingsDaoProvider);

      final dosingService = DosingService(
        db: appDb,
        medicationDao: medicationDao,
        doseScheduleDao: doseScheduleDao,
        doseEventDao: doseEventDao,
        userSettingsDao: userSettingsDao,
      );

      final now = DateTime.now();
      final behavior = await BehaviorSettingsService.load();
      final meds = await medicationDao.getAll();

      var total = 0;
      var completed = 0;
      var takenDoseCount = 0;
      final takenMeds = <String>{};
      final remainingMeds = <String>{};

      for (final med in meds.where((m) => m.isActive)) {
        final scheduleTimes = await doseScheduleDao.getByMedicationId(med.id);
        final occurrences = dosingService.generateOccurrencesForDay(
          day: now,
          scheduleTimes: scheduleTimes,
        );

        for (final occ in occurrences) {
          total++;
          final event = await doseEventDao.getByMedicationAndScheduledAt(
            medicationId: occ.medicationId,
            scheduledAt: occ.scheduledAt,
          );
          final status = event?.status ?? doseStatusScheduled;
          if (status == doseStatusTaken) {
            completed++;
            takenDoseCount++;
            takenMeds.add(med.name);
          } else if (status == doseStatusSkipped) {
            completed++;
          } else {
            remainingMeds.add(med.name);
          }
        }
      }

      final next = await dosingService.findEarliestPendingDose(now: now);

      await SiriShortcutsService.instance.updateDailySummary(
        date: now,
        takenDoses: takenDoseCount,
        remainingDoses: total - completed,
        takenMedicationNames: takenMeds.toList()..sort(),
        remainingMedicationNames: remainingMeds.toList()..sort(),
        totalDosesToday: total,
        completedDosesToday: completed,
        nextDoseEpochMs: next?.scheduledAt.millisecondsSinceEpoch,
        nextDoseMedicationName: next?.medicationName ?? '',
        darkMode: behavior.darkMode,
        highContrast: behavior.highContrast,
        uiScale: behavior.uiScale,
      );
    } catch (_) {
      // Silently ignore Siri / widget bridge errors
    }
  }
}

class _CalmLoadingState extends StatelessWidget {
  const _CalmLoadingState();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.35, end: 1),
        duration: const Duration(milliseconds: 1800),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.20 * value),
                    blurRadius: 34,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(Icons.brightness_2_outlined, color: color, size: 28),
            ),
          );
        },
      ),
    );
  }
}

class _CelestialBackdrop extends StatelessWidget {
  const _CelestialBackdrop();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: CustomPaint(
        painter: _CelestialBackdropPainter(
          starColor: scheme.primary.withValues(alpha: 0.18),
          moonColor: scheme.secondary.withValues(alpha: 0.10),
          planetColor: scheme.primary.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _CelestialBackdropPainter extends CustomPainter {
  const _CelestialBackdropPainter({
    required this.starColor,
    required this.moonColor,
    required this.planetColor,
  });

  final Color starColor;
  final Color moonColor;
  final Color planetColor;

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = starColor;
    final moonPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final planetPaint = Paint()..color = planetColor;

    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.15),
      42,
      moonPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.72),
      86,
      planetPaint,
    );

    final stars = <Offset>[
      Offset(size.width * 0.18, size.height * 0.10),
      Offset(size.width * 0.78, size.height * 0.30),
      Offset(size.width * 0.62, size.height * 0.58),
      Offset(size.width * 0.30, size.height * 0.84),
      Offset(size.width * 0.90, size.height * 0.78),
    ];
    for (final point in stars) {
      canvas.drawCircle(point, 1.6, starPaint);
      canvas.drawLine(
        Offset(point.dx - 4, point.dy),
        Offset(point.dx + 4, point.dy),
        starPaint,
      );
      canvas.drawLine(
        Offset(point.dx, point.dy - 4),
        Offset(point.dx, point.dy + 4),
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelestialBackdropPainter oldDelegate) {
    return oldDelegate.starColor != starColor ||
        oldDelegate.moonColor != moonColor ||
        oldDelegate.planetColor != planetColor;
  }
}

class _EmptyMedicationHome extends StatelessWidget {
  const _EmptyMedicationHome({required this.onAddMedication});

  final VoidCallback onAddMedication;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 88, 28, 96),
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 2200),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.74),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.16,
                          ),
                          blurRadius: 46,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          color: theme.colorScheme.secondary,
                          size: 54,
                        ),
                        Positioned(
                          right: 25,
                          top: 24,
                          child: Icon(
                            Icons.star_rounded,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Begin with one medication.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Create a quiet schedule for reminders, confirmations, and refills.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 34),
          Align(
            alignment: Alignment.center,
            child: FilledButton.icon(
              onPressed: onAddMedication,
              icon: const Icon(Icons.add),
              label: const Text('Create medication'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtmosphericPanel extends StatelessWidget {
  const _AtmosphericPanel({
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SoftGlowButton extends StatefulWidget {
  const _SoftGlowButton({required this.onPressed, required this.label});

  final Future<void> Function() onPressed;
  final String label;

  @override
  State<_SoftGlowButton> createState() => _SoftGlowButtonState();
}

class _SoftGlowButtonState extends State<_SoftGlowButton> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    setState(() => _pressed = true);
    await widget.onPressed();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (mounted) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(
              alpha: _pressed ? 0.30 : 0.08,
            ),
            blurRadius: _pressed ? 34 : 16,
            spreadRadius: _pressed ? 4 : 0,
          ),
        ],
      ),
      child: FilledButton.tonal(
        onPressed: () => unawaited(_handleTap()),
        child: Text(widget.label),
      ),
    );
  }
}

class _RefillAlertCard extends StatelessWidget {
  const _RefillAlertCard({required this.medication, required this.onDismiss});

  final Medication medication;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.star_rounded, color: theme.colorScheme.tertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${medication.name}: ${medication.totalPills} remaining. Refill soon.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss refill alert',
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseyWelcomeCard extends StatelessWidget {
  const _DoseyWelcomeCard({
    required this.activeMedicationCount,
    required this.todayDone,
    required this.todayTotal,
    required this.onAddMedication,
    required this.onCareTap,
  });

  final int activeMedicationCount;
  final int todayDone;
  final int todayTotal;
  final VoidCallback onAddMedication;
  final VoidCallback onCareTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _AtmosphericPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.secondary,
            size: 22,
          ),
          const SizedBox(height: 18),
          Text(
            'Schedule',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$activeMedicationCount active medication${activeMedicationCount == 1 ? '' : 's'}. $todayDone of $todayTotal confirmed.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onAddMedication,
                icon: const Icon(Icons.add),
                label: const Text('Add medication'),
              ),
              OutlinedButton.icon(
                onPressed: onCareTap,
                icon: const Icon(Icons.medication_outlined),
                label: const Text('Open schedule'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeOverviewCard extends StatelessWidget {
  const _HomeOverviewCard({
    required this.takenDoses,
    required this.upcomingDoses,
    required this.missedDoses,
    required this.skippedDoses,
    required this.upcomingItems,
    required this.onCategoryTap,
    required this.onUpcomingTaken,
  });

  final int takenDoses;
  final int upcomingDoses;
  final int missedDoses;
  final int skippedDoses;
  final List<TodayDoseItem> upcomingItems;
  final ValueChanged<TodayDoseBucket> onCategoryTap;
  final Future<void> Function(TodayDoseItem item) onUpcomingTaken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s doses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OverviewStatTile(
                  icon: Icons.check_circle_outline,
                  label: 'Taken',
                  value: takenDoses,
                  color: theme.colorScheme.secondary,
                  onTap: () => onCategoryTap(TodayDoseBucket.completed),
                ),
                _OverviewStatTile(
                  icon: Icons.schedule_outlined,
                  label: 'Upcoming',
                  value: upcomingDoses,
                  color: theme.colorScheme.primary,
                  onTap: () => onCategoryTap(TodayDoseBucket.upcoming),
                ),
                _OverviewStatTile(
                  icon: Icons.warning_amber_outlined,
                  label: 'Missed',
                  value: missedDoses,
                  color: theme.colorScheme.error,
                  onTap: () => onCategoryTap(TodayDoseBucket.missed),
                ),
                _OverviewStatTile(
                  icon: Icons.remove_circle_outline,
                  label: 'Skipped',
                  value: skippedDoses,
                  color: theme.colorScheme.outline,
                  onTap: () => onCategoryTap(TodayDoseBucket.skipped),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Next dose', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (upcomingItems.isEmpty)
              Text('Complete.', style: Theme.of(context).textTheme.bodySmall)
            else
              Column(
                children: [
                  for (final item in upcomingItems.take(3)) ...[
                    _UpcomingDosePreview(
                      item: item,
                      onTaken: () => onUpcomingTaken(item),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (upcomingItems.length > 3)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            onCategoryTap(TodayDoseBucket.upcoming),
                        child: Text('View all ${upcomingItems.length}'),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStatTile extends StatelessWidget {
  const _OverviewStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 132, maxWidth: 220),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$label: $value',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingDosePreview extends StatelessWidget {
  const _UpcomingDosePreview({required this.item, required this.onTaken});

  final TodayDoseItem item;
  final Future<void> Function() onTaken;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(
      item.occurrence.scheduledAt,
    ).format(context);

    return _AtmosphericPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.medicationName,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Next dose at $time',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: _SoftGlowButton(onPressed: onTaken, label: 'Taken'),
          ),
        ],
      ),
    );
  }
}

class _AllergiesCard extends StatelessWidget {
  const _AllergiesCard({
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> items;
  final VoidCallback onAdd;
  final Future<void> Function(String keyword) onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allergies and sensitivities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Text('None added.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map(
                      (item) => InputChip(
                        label: Text(item),
                        onDeleted: () => onRemove(item),
                      ),
                    )
                    .toList(growable: false),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add allergy or sensitivity'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdherenceVisualCard extends StatelessWidget {
  const _AdherenceVisualCard({
    required this.todayDone,
    required this.todayTotal,
    required this.weeklyAverage,
    required this.showStreak,
    required this.bestStreak,
  });

  final int todayDone;
  final int todayTotal;
  final double weeklyAverage;
  final bool showStreak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final progress = todayTotal == 0 ? 0.0 : todayDone / todayTotal;
    final weeklyPct = (weeklyAverage * 100).round();
    final streakPrimary = showStreak ? '$bestStreak' : '—';
    final streakSecondary = showStreak ? 'days' : 'Hidden in settings';
    final streakFeedback = !showStreak
        ? null
        : bestStreak >= 7
        ? '$bestStreak days recorded.'
        : bestStreak > 0
        ? '$bestStreak day recorded.'
        : todayTotal == 0
        ? 'No doses today.'
        : 'Not started.';
    final adherenceFeedback = todayTotal == 0
        ? 'No doses today.'
        : weeklyPct >= 80
        ? 'Complete.'
        : weeklyPct >= 50
        ? 'Weekly adherence needs review.'
        : 'Weekly adherence is low.';

    final theme = Theme.of(context);
    return _AtmosphericPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1 ? 'Complete for today.' : 'Awaiting confirmation.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 28),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  color: theme.colorScheme.secondary,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.10,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 32,
            runSpacing: 22,
            children: [
              _MetricLine(
                label: 'Confirmed',
                value: '$todayDone of $todayTotal',
              ),
              _MetricLine(label: 'Week', value: '$weeklyPct%'),
              _MetricLine(
                label: 'Rhythm',
                value: showStreak ? streakPrimary : '--',
                note: showStreak ? streakSecondary : 'Hidden in settings',
              ),
            ],
          ),
          if (streakFeedback != null) ...[
            const SizedBox(height: 18),
            Text(streakFeedback, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 18),
          Text(adherenceFeedback, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 3),
          Text(note!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.item,
    required this.onStatusSelected,
    required this.onTakenTimeEditRequested,
  });

  final TodayDoseItem item;
  final Future<void> Function(TodayDoseItem item, int newStatus)
  onStatusSelected;
  final Future<void> Function(TodayDoseItem item) onTakenTimeEditRequested;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(item.occurrence.scheduledAt);
    final timeText = time.format(context);

    String statusText;
    Color chipColor;

    switch (item.eventStatus) {
      case doseStatusTaken:
        chipColor = Theme.of(context).colorScheme.secondary;
        statusText = 'Taken';
        break;
      case doseStatusMissed:
        chipColor = Theme.of(context).colorScheme.error;
        statusText = 'Missed';
        break;
      case doseStatusSkipped:
        chipColor = Theme.of(context).colorScheme.outline;
        statusText = 'Skipped';
        break;
      default:
        chipColor = Theme.of(context).colorScheme.primary;
        statusText = 'Upcoming';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.medicationName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _DoseStatusMenu(
                  currentStatusLabel: statusText,
                  color: chipColor,
                  onStatusSelected: (newStatus) =>
                      onStatusSelected(item, newStatus),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.eventStatus == doseStatusTaken && item.takenAt != null
                        ? 'Taken ${TimeOfDay.fromDateTime(item.takenAt!).format(context)}'
                        : 'Awaiting confirmation at $timeText',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (item.eventStatus == doseStatusTaken)
                  TextButton.icon(
                    onPressed: () => onTakenTimeEditRequested(item),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit time'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseStatusMenu extends StatelessWidget {
  const _DoseStatusMenu({
    required this.currentStatusLabel,
    required this.color,
    required this.onStatusSelected,
  });

  final String currentStatusLabel;
  final Color color;
  final Future<void> Function(int newStatus) onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(currentStatusLabel),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () => unawaited(onStatusSelected(doseStatusScheduled)),
          child: const Text('Upcoming'),
        ),
        MenuItemButton(
          onPressed: () => unawaited(onStatusSelected(doseStatusTaken)),
          child: const Text('Taken'),
        ),
        MenuItemButton(
          onPressed: () => unawaited(onStatusSelected(doseStatusMissed)),
          child: const Text('Missed'),
        ),
        MenuItemButton(
          onPressed: () => unawaited(onStatusSelected(doseStatusSkipped)),
          child: const Text('Skipped'),
        ),
      ],
    );
  }
}
