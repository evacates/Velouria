import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app/app_navigation.dart';
import '../../core/db/app_database.dart';
import '../../core/db/db_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/time/timezone_service.dart';
import '../dosing/domain/dosing_services.dart';
import 'medication_form_screen.dart';

// Main medication list screen with quick summaries.
class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  bool _loading = true;
  List<Medication> _medications = [];
  final Map<String, String> _doseFrequencyById = {};
  final Map<String, double?> _adherenceByMedicationId = {};
  int _takenDosesToday = 0;
  int _remainingDosesToday = 0;
  List<String> _takenMedicationNames = [];
  List<String> _remainingMedicationNames = [];
  List<DoseEvent> _recentEvents = [];
  String? _historyMedicationId;
  late DateTime _historyWeekEnd;
  List<double> _historyWeekPercents = const [];

  final Map<String, bool> _weekLoading = {};
  final Map<String, List<double>> _weekDailyPercents = {};
  final Map<String, List<DoseEvent>> _weekEvents = {};

  @override
  void initState() {
    super.initState();
    _historyWeekEnd = DateTime.now();
    _reload();
  }

  Future<void> _reload() async {
    // Refresh the full list, today summary, and history cache.
    setState(() => _loading = true);
    final appDb = ref.read(appDatabaseProvider);
    final medicationDao = ref.read(medicationDaoProvider);
    final doseScheduleDao = ref.read(doseScheduleDaoProvider);
    final doseEventDao = ref.read(doseEventDaoProvider);
    final userSettingsDao = ref.read(userSettingsDaoProvider);
    await medicationDao.normalizeStoredUserText();
    final meds = await medicationDao.getAll();

    final dosingService = DosingService(
      db: appDb,
      medicationDao: medicationDao,
      doseScheduleDao: doseScheduleDao,
      doseEventDao: doseEventDao,
      userSettingsDao: userSettingsDao,
    );

    final now = DateTime.now();

    final frequencyEntries = await Future.wait(
      meds.map((med) async {
        final times = await doseScheduleDao.getByMedicationId(med.id);
        return MapEntry(med.id, _buildDoseFrequencyLabel(med, times));
      }),
    );
    final doseFrequencyById = Map<String, String>.fromEntries(frequencyEntries);

    final activeMeds = meds.where((m) => m.isActive).toList();
    if (_historyMedicationId != null &&
        !activeMeds.any((med) => med.id == _historyMedicationId)) {
      _historyMedicationId = null;
    }

    final calendarToday = DateTime(
      _historyWeekEnd.year,
      _historyWeekEnd.month,
      _historyWeekEnd.day,
    );
    final daysFromMonday = (calendarToday.weekday - DateTime.monday) % 7;
    final weekStart = calendarToday.subtract(Duration(days: daysFromMonday));
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    final historyMeds = _historyMedicationId == null
        ? activeMeds
        : activeMeds
              .where((med) => med.id == _historyMedicationId)
              .toList(growable: false);

    final adherenceEntries = await Future.wait(
      activeMeds.map((med) async {
        final adherence = await dosingService.getDailyAdherencePercent(
          medicationId: med.id,
          day: now,
        );
        return MapEntry(med.id, adherence);
      }),
    );
    final adherenceById = Map<String, double?>.fromEntries(adherenceEntries);

    final recentEventsNested = await Future.wait(
      historyMeds.map(
        (med) => doseEventDao.getForMedicationInRange(
          medicationId: med.id,
          start: weekStart,
          end: weekEndExclusive,
        ),
      ),
    );
    final recentEvents = recentEventsNested.expand((events) => events).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    final historyWeekPercents = _historyMedicationId == null
        ? await _aggregateWeekPercentsForMedications(
            dosingService: dosingService,
            medications: historyMeds,
            referenceDay: _historyWeekEnd,
          )
        : await dosingService.getMondaySundayWeekDailyPercents(
            medicationId: _historyMedicationId!,
            referenceDay: _historyWeekEnd,
          );

    final todaySummary = await _buildTodaySummary(
      meds: meds,
      doseScheduleDao: doseScheduleDao,
      doseEventDao: doseEventDao,
      dosingService: dosingService,
    );

    setState(() {
      _medications = meds;
      _doseFrequencyById
        ..clear()
        ..addAll(doseFrequencyById);
      _adherenceByMedicationId
        ..clear()
        ..addAll(adherenceById);
      _takenDosesToday = todaySummary.takenDoses;
      _remainingDosesToday = todaySummary.remainingDoses;
      _takenMedicationNames = todaySummary.takenMedicationNames;
      _remainingMedicationNames = todaySummary.remainingMedicationNames;
      _recentEvents = recentEvents;
      _historyWeekPercents = historyWeekPercents;
      _weekLoading.clear();
      _weekDailyPercents.clear();
      _weekEvents.clear();
      _loading = false;
    });
  }

  Future<List<double>> _aggregateWeekPercentsForMedications({
    required DosingService dosingService,
    required List<Medication> medications,
    required DateTime referenceDay,
  }) async {
    // Average the weekly adherence across whatever meds are visible.
    final cal = DateTime(
      referenceDay.year,
      referenceDay.month,
      referenceDay.day,
    );
    final daysFromMonday = (cal.weekday - DateTime.monday) % 7;
    final monday = cal.subtract(Duration(days: daysFromMonday));
    final out = <double>[];
    for (var index = 0; index < 7; index++) {
      final day = monday.add(Duration(days: index));
      if (medications.isEmpty) {
        out.add(0);
        continue;
      }

      var sum = 0.0;
      for (final med in medications) {
        sum += await dosingService.getDailyAdherencePercent(
          medicationId: med.id,
          day: day,
        );
      }
      out.add(sum / medications.length);
    }
    return out;
  }

  Future<void> _loadWeekForMedication(Medication med) async {
    // Load the expanded history card on demand.
    if (!med.isActive) return;

    setState(() => _weekLoading[med.id] = true);

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
      final dailies = await dosingService.getMondaySundayWeekDailyPercents(
        medicationId: med.id,
        referenceDay: now,
      );

      final cal = DateTime(now.year, now.month, now.day);
      final daysFromMonday = (cal.weekday - DateTime.monday) % 7;
      final monday = cal.subtract(Duration(days: daysFromMonday));
      final weekEndExclusive = monday.add(const Duration(days: 7));

      final events =
          await doseEventDao.getForMedicationInRange(
              medicationId: med.id,
              start: monday,
              end: weekEndExclusive,
            )
            ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

      if (!mounted) return;
      setState(() {
        _weekDailyPercents[med.id] = dailies;
        _weekEvents[med.id] = events;
        _weekLoading[med.id] = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _weekLoading[med.id] = false);
    }
  }

  Future<_TodayIntakeSummary> _buildTodaySummary({
    required List<Medication> meds,
    required DoseScheduleDao doseScheduleDao,
    required DoseEventDao doseEventDao,
    required DosingService dosingService,
  }) async {
    // Build the little taken/remaining pill summary at the top.
    final now = DateTime.now();
    await dosingService.reconcileMissedDoses(now: now, daysBack: 0);

    var takenDoses = 0;
    var remainingDoses = 0;
    final takenMeds = <String>{};
    final remainingMeds = <String>{};

    for (final med in meds.where((m) => m.isActive)) {
      final scheduleTimes = await doseScheduleDao.getByMedicationId(med.id);
      final occurrences = dosingService.generateOccurrencesForDay(
        day: now,
        scheduleTimes: scheduleTimes,
      );

      var hasTakenToday = false;
      var hasRemainingToday = false;

      for (final occ in occurrences) {
        final event = await doseEventDao.getByMedicationAndScheduledAt(
          medicationId: occ.medicationId,
          scheduledAt: occ.scheduledAt,
        );

        if (event?.status == doseStatusTaken) {
          takenDoses++;
          hasTakenToday = true;
          continue;
        }

        if (event?.status == doseStatusSkipped) {
          continue;
        }

        remainingDoses++;
        hasRemainingToday = true;
      }

      if (hasTakenToday) takenMeds.add(med.name);
      if (hasRemainingToday) remainingMeds.add(med.name);
    }

    final takenList = takenMeds.toList()..sort();
    final remainingList = remainingMeds.toList()..sort();

    return _TodayIntakeSummary(
      takenDoses: takenDoses,
      remainingDoses: remainingDoses,
      takenMedicationNames: takenList,
      remainingMedicationNames: remainingList,
    );
  }

  Future<void> _deleteMedication(Medication med) async {
    // Ask first, then delete the medication and reminders.
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete medication?'),
        content: Text('Delete "${med.name}" and its scheduled reminders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final medicationDao = ref.read(medicationDaoProvider);
    final doseScheduleDao = ref.read(doseScheduleDaoProvider);
    final timezoneName = await TimezoneService.getDeviceTimezoneName();

    final oldTimes = await doseScheduleDao.getByMedicationId(med.id);
    await NotificationService.instance
        .cancelUpcomingDoseNotificationsForMedication(
          medication: med,
          scheduleTimes: oldTimes,
          timezoneName: timezoneName,
        );

    await medicationDao.deleteById(med.id);
    if (_historyMedicationId == med.id) {
      _historyMedicationId = null;
    }
    await _reload();
  }

  void _previousHistoryWeek() {
    // Slide the history window back a week.
    setState(() {
      _historyWeekEnd = _historyWeekEnd.subtract(const Duration(days: 7));
    });
    _reload();
  }

  void _nextHistoryWeek() {
    // Slide the history window forward a week.
    setState(() {
      _historyWeekEnd = _historyWeekEnd.add(const Duration(days: 7));
    });
    _reload();
  }

  String _historyWeekRangeLabel() {
    final endDay = _historyWeekEnd;
    final daysIntoWeek = (endDay.weekday - DateTime.monday) % 7;
    final weekStart = endDay.subtract(Duration(days: daysIntoWeek));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormat.MMMd().format(weekStart)} - ${DateFormat.MMMd().format(weekEnd)}';
  }

  Future<void> _editEventStatus(DoseEvent event) async {
    // Same status editor used in the history view.
    final selectedStatus = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Taken'),
              onTap: () => Navigator.of(context).pop(doseStatusTaken),
            ),
            ListTile(
              title: const Text('Missed'),
              onTap: () => Navigator.of(context).pop(doseStatusMissed),
            ),
            ListTile(
              title: const Text('Skipped'),
              onTap: () => Navigator.of(context).pop(doseStatusSkipped),
            ),
            ListTile(
              title: const Text('Scheduled'),
              onTap: () => Navigator.of(context).pop(doseStatusScheduled),
            ),
          ],
        ),
      ),
    );

    if (selectedStatus == null || selectedStatus == event.status) return;

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
      medicationId: event.medicationId,
      scheduledAt: event.scheduledAt,
      newStatus: selectedStatus,
      takenAt: selectedStatus == doseStatusTaken ? DateTime.now() : null,
      source: doseSourceManual,
    );

    await _reload();
  }

  String _medicationNameForEvent(DoseEvent event) {
    for (final med in _medications) {
      if (med.id == event.medicationId) return med.name;
    }
    return 'Unknown medication';
  }

  String _statusLabel(int status) {
    switch (status) {
      case doseStatusTaken:
        return 'Taken';
      case doseStatusMissed:
        return 'Missed';
      case doseStatusSkipped:
        return 'Skipped';
      default:
        return 'Scheduled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: AppNavigationController.showToday,
          tooltip: 'Back to today',
        ),
        title: const Text('Your schedule'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
          ? _EmptyScheduleState(
              onCreate: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MedicationFormScreen(),
                  ),
                );
                await _reload();
              },
            )
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                children: [
                  _MedicationIntakeSummaryCard(
                    takenDosesToday: _takenDosesToday,
                    remainingDosesToday: _remainingDosesToday,
                    takenMedicationNames: _takenMedicationNames,
                    remainingMedicationNames: _remainingMedicationNames,
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_medications.length, (i) {
                    final med = _medications[i];
                    final doseFrequency = _doseFrequencyById[med.id];
                    final strength = med.strength?.trim();
                    final displayTitle = () {
                      final leftSide = strength;
                      final rightSide = doseFrequency;

                      if ((leftSide == null || leftSide.isEmpty) &&
                          (rightSide == null || rightSide.isEmpty)) {
                        return med.name;
                      }

                      if (leftSide != null &&
                          leftSide.isNotEmpty &&
                          rightSide != null &&
                          rightSide.isNotEmpty) {
                        return '${med.name} $leftSide / $rightSide';
                      }

                      if (leftSide != null && leftSide.isNotEmpty) {
                        return '${med.name} $leftSide';
                      }

                      return '${med.name} $rightSide';
                    }();

                    final weekBusy = _weekLoading[med.id] == true;
                    final dailies = _weekDailyPercents[med.id];
                    final events = _weekEvents[med.id] ?? const [];

                    return Card(
                      margin: EdgeInsets.only(top: i == 0 ? 0 : 8, bottom: 0),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(child: Text(displayTitle)),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MedicationFormScreen(
                                      medicationId: med.id,
                                    ),
                                  ),
                                );
                                await _reload();
                              },
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteMedication(med),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          med.isActive
                              ? 'Units: ${med.totalPills} • Per dose: ${med.pillPerDose}'
                              : 'Inactive',
                        ),
                        onExpansionChanged: (open) {
                          if (open && med.isActive) {
                            _loadWeekForMedication(med);
                          }
                        },
                        children: [
                          if (!med.isActive)
                            const ListTile(
                              title: Text(
                                'Activate this medication to see schedules and history.',
                              ),
                            )
                          else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: _AdherenceIndicator(
                                adherencePercent:
                                    _adherenceByMedicationId[med.id],
                              ),
                            ),
                            if (weekBusy)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (dailies != null && dailies.length == 7)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: _CareWeekChart(
                                  valuesMondayToSunday: dailies,
                                  referenceDayInWeek: now,
                                  compact: true,
                                ),
                              ),
                            if (events.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  'Dose log',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              ...events.map(
                                (e) => ListTile(
                                  dense: true,
                                  title: Text(
                                    TimeOfDay.fromDateTime(
                                      e.scheduledAt,
                                    ).format(context),
                                  ),
                                  subtitle: Text(_statusLabel(e.status)),
                                ),
                              ),
                            ] else if (!weekBusy &&
                                (dailies != null && dailies.length == 7))
                              const ListTile(
                                dense: true,
                                title: Text('No dose events this week.'),
                              ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  _MedicationHistoryCard(
                    events: _recentEvents,
                    medications: _medications.where((m) => m.isActive).toList(),
                    selectedMedicationId: _historyMedicationId,
                    weekLabel: _historyWeekRangeLabel(),
                    weekPercents: _historyWeekPercents,
                    referenceDayInWeek: _historyWeekEnd,
                    onPreviousWeek: _previousHistoryWeek,
                    onNextWeek: _nextHistoryWeek,
                    onSelectedMedicationChanged: (value) {
                      setState(() => _historyMedicationId = value);
                      _reload();
                    },
                    medicationNameForEvent: _medicationNameForEvent,
                    statusLabel: _statusLabel,
                    onEditStatus: _editEventStatus,
                  ),
                ],
              ),
            ),
    );
  }

  String _buildDoseFrequencyLabel(
    Medication med,
    List<DoseScheduleTime> times,
  ) {
    if (times.isEmpty) return '';

    final allWeeklyAllDays = times.every((t) => t.daysOfWeekBitmask == 127);
    final allIntervalMode = times.every((t) => t.daysOfWeekBitmask <= 0);

    if (allWeeklyAllDays) {
      if (times.length == 1) return '1x a day';
      return '${times.length}x a day';
    }

    if (allIntervalMode) {
      final intervals = times
          .map((t) => (-t.daysOfWeekBitmask).clamp(1, 365).toInt())
          .toSet();
      if (intervals.length == 1) {
        final interval = intervals.first;
        return interval == 1
            ? '${times.length}x a day'
            : 'every $interval days';
      }
      return 'scheduled doses';
    }

    final weeklyCount = times.length;
    if (weeklyCount == 1) return '1x a day';
    return '$weeklyCount scheduled doses';
  }
}

class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 104, 28, 96),
      children: [
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.72,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  blurRadius: 44,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.brightness_2_outlined,
                  color: theme.colorScheme.secondary,
                  size: 52,
                ),
                Positioned(
                  right: 24,
                  top: 26,
                  child: Icon(
                    Icons.star_rounded,
                    color: theme.colorScheme.primary,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 34),
        Text(
          'No medications yet.',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Create one schedule to begin tracking reminders and refills.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.center,
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create medication'),
          ),
        ),
      ],
    );
  }
}

class _MedicationHistoryCard extends StatelessWidget {
  const _MedicationHistoryCard({
    required this.events,
    required this.medications,
    required this.selectedMedicationId,
    required this.weekLabel,
    required this.weekPercents,
    required this.referenceDayInWeek,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onSelectedMedicationChanged,
    required this.medicationNameForEvent,
    required this.statusLabel,
    required this.onEditStatus,
  });

  final List<DoseEvent> events;
  final List<Medication> medications;
  final String? selectedMedicationId;
  final String weekLabel;
  final List<double> weekPercents;
  final DateTime referenceDayInWeek;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final ValueChanged<String?> onSelectedMedicationChanged;
  final String Function(DoseEvent event) medicationNameForEvent;
  final String Function(int status) statusLabel;
  final Future<void> Function(DoseEvent event) onEditStatus;

  Color _statusColor(BuildContext context, int status) {
    switch (status) {
      case doseStatusTaken:
        return Theme.of(context).colorScheme.secondary;
      case doseStatusMissed:
        return Theme.of(context).colorScheme.error;
      case doseStatusSkipped:
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = selectedMedicationId == null
        ? events
        : events
              .where((event) => event.medicationId == selectedMedicationId)
              .toList(growable: false);
    final visibleEvents = filteredEvents.take(8).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'History this week',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Dose records and weekly patterns.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: ValueKey(selectedMedicationId ?? 'all_meds'),
              initialValue: selectedMedicationId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Medication'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All medications'),
                ),
                ...medications.map(
                  (med) => DropdownMenuItem<String?>(
                    value: med.id,
                    child: Text(med.name),
                  ),
                ),
              ],
              onChanged: onSelectedMedicationChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous week',
                  onPressed: onPreviousWeek,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    weekLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next week',
                  onPressed: onNextWeek,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _CareWeekChart(
              valuesMondayToSunday: weekPercents,
              referenceDayInWeek: referenceDayInWeek,
            ),
            const SizedBox(height: 12),
            if (visibleEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No dose events.'),
              )
            else
              Column(
                children: [
                  for (final event in visibleEvents) ...[
                    _HistoryEventRow(
                      event: event,
                      medicationName: medicationNameForEvent(event),
                      statusLabel: statusLabel(event.status),
                      statusColor: _statusColor(context, event.status),
                      onEditStatus: () => onEditStatus(event),
                    ),
                    if (event != visibleEvents.last) const Divider(height: 18),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEventRow extends StatelessWidget {
  const _HistoryEventRow({
    required this.event,
    required this.medicationName,
    required this.statusLabel,
    required this.statusColor,
    required this.onEditStatus,
  });

  final DoseEvent event;
  final String medicationName;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onEditStatus;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat.MMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(event.scheduledAt);
    final timeText = TimeOfDay.fromDateTime(event.scheduledAt).format(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '$dateText at $timeText',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEditStatus,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.22)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _CareWeekChart extends StatefulWidget {
  const _CareWeekChart({
    required this.valuesMondayToSunday,
    required this.referenceDayInWeek,
    this.compact = false,
  });

  final List<double> valuesMondayToSunday;
  final DateTime referenceDayInWeek;
  final bool compact;

  @override
  State<_CareWeekChart> createState() => _CareWeekChartState();
}

class _CareWeekChartState extends State<_CareWeekChart> {
  int? _selectedIndex;

  DateTime _mondayOfWeekContaining(DateTime d) {
    final cal = DateTime(d.year, d.month, d.day);
    final daysFromMonday = (cal.weekday - DateTime.monday) % 7;
    return cal.subtract(Duration(days: daysFromMonday));
  }

  DateTime _dayAtIndex(int index) => _mondayOfWeekContaining(
    widget.referenceDayInWeek,
  ).add(Duration(days: index));

  String _weekdayShort(BuildContext context, int index) {
    return DateFormat.E(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(_dayAtIndex(index));
  }

  String _dateShort(int index) {
    final day = _dayAtIndex(index);
    return '${day.month.toString().padLeft(2, '0')}/${day.day.toString().padLeft(2, '0')}';
  }

  String _percentText(double value) => '${(value * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    if (widget.valuesMondayToSunday.length != 7) {
      return const SizedBox.shrink();
    }

    final today = DateTime.now();
    final monday = _mondayOfWeekContaining(widget.referenceDayInWeek);
    final todayIndex = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(monday).inDays.clamp(0, 6);
    final selectedIndex = _selectedIndex ?? todayIndex;
    final selectedValue = widget.valuesMondayToSunday[selectedIndex].clamp(
      0.0,
      1.0,
    );
    final theme = Theme.of(context);
    final selectedColor =
        Color.lerp(
          theme.colorScheme.error,
          theme.colorScheme.secondary,
          selectedValue,
        ) ??
        theme.colorScheme.secondary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This week',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: widget.compact ? 150 : 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(7, (index) {
                  final value = widget.valuesMondayToSunday[index].clamp(
                    0.0,
                    1.0,
                  );
                  final color =
                      Color.lerp(
                        theme.colorScheme.error,
                        theme.colorScheme.secondary,
                        value,
                      ) ??
                      theme.colorScheme.secondary;
                  final isSelected = index == selectedIndex;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Column(
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final trackH = constraints.maxHeight;
                                  final fillH = trackH * value;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.transparent,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 240,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        width: double.infinity,
                                        height: fillH.clamp(0.0, trackH),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.92),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _weekdayShort(context, index),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                            if (!widget.compact)
                              Text(
                                _dateShort(index),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: Theme.of(context).hintColor,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (!widget.compact) ...[
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '${_weekdayShort(context, selectedIndex)} ${_dateShort(selectedIndex)} • ${_percentText(selectedValue)} adherence',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayIntakeSummary {
  const _TodayIntakeSummary({
    required this.takenDoses,
    required this.remainingDoses,
    required this.takenMedicationNames,
    required this.remainingMedicationNames,
  });

  final int takenDoses;
  final int remainingDoses;
  final List<String> takenMedicationNames;
  final List<String> remainingMedicationNames;
}

class _MedicationIntakeSummaryCard extends StatelessWidget {
  const _MedicationIntakeSummaryCard({
    required this.takenDosesToday,
    required this.remainingDosesToday,
    required this.takenMedicationNames,
    required this.remainingMedicationNames,
  });

  final int takenDosesToday;
  final int remainingDosesToday;
  final List<String> takenMedicationNames;
  final List<String> remainingMedicationNames;

  @override
  Widget build(BuildContext context) {
    final hasTaken = takenMedicationNames.isNotEmpty;
    final hasRemaining = remainingMedicationNames.isNotEmpty;

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
                Chip(
                  avatar: const Icon(Icons.check_circle_outline),
                  label: Text('Taken: $takenDosesToday'),
                ),
                Chip(
                  avatar: const Icon(Icons.pending_actions_outlined),
                  label: Text('Awaiting: $remainingDosesToday'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hasTaken
                  ? 'Taken: ${_namesPreview(takenMedicationNames)}'
                  : 'Taken: none',
            ),
            const SizedBox(height: 6),
            Text(
              hasRemaining
                  ? 'Awaiting: ${_namesPreview(remainingMedicationNames)}'
                  : 'Awaiting: none',
            ),
          ],
        ),
      ),
    );
  }

  String _namesPreview(List<String> names) {
    if (names.length <= 4) return names.join(', ');
    final displayed = names.take(4).join(', ');
    return '$displayed +${names.length - 4} more';
  }
}

class _AdherenceIndicator extends StatelessWidget {
  const _AdherenceIndicator({required this.adherencePercent});

  final double? adherencePercent;

  @override
  Widget build(BuildContext context) {
    if (adherencePercent == null) {
      return const SizedBox.shrink();
    }

    final percent = (adherencePercent! * 100).toStringAsFixed(0);
    final isGood = adherencePercent! >= 0.75;
    final isWarning = adherencePercent! >= 0.5;

    Color barColor;
    if (isGood) {
      barColor = Theme.of(context).colorScheme.secondary;
    } else if (isWarning) {
      barColor = Theme.of(context).colorScheme.tertiary;
    } else {
      barColor = Theme.of(context).colorScheme.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s adherence',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: adherencePercent,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            backgroundColor: barColor.withValues(alpha: 0.2),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
