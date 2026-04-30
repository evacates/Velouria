import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app/app_navigation.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_providers.dart';
import '../../dosing/domain/dosing_services.dart';

// Screen for older dose history and adherence details.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _loading = true;
  bool _adherenceLoading = false;
  late DateTime _currentWeekEnd;

  List<Medication> _medications = [];
  String? _selectedMedicationId;
  List<DoseEvent> _events = [];
  double? _dailyAdherencePercent;
  List<double> _weeklyAdherencePercents = const [];

  @override
  void initState() {
    super.initState();
    _currentWeekEnd = DateTime.now();
    _reload();
  }

  Future<void> _reload() async {
    // Re-query the current week and rebuild the selected summary.
    setState(() => _loading = true);
    final medicationDao = ref.read(medicationDaoProvider);
    final doseEventDao = ref.read(doseEventDaoProvider);
    final doseScheduleDao = ref.read(doseScheduleDaoProvider);
    final appDb = ref.read(appDatabaseProvider);
    final userSettingsDao = ref.read(userSettingsDaoProvider);

    final meds = await medicationDao.getAll();

    // Calculate the week range: start of week (Monday) to end of week (Sunday)
    final endDay = _currentWeekEnd;
    final daysIntoWeek = (endDay.weekday - DateTime.monday) % 7;
    final weekStart = endDay.subtract(Duration(days: daysIntoWeek));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final medsToQuery = _selectedMedicationId == null
        ? meds
        : meds.where((m) => m.id == _selectedMedicationId);

    final allEvents = <DoseEvent>[];
    for (final med in medsToQuery) {
      allEvents.addAll(
        await doseEventDao.getForMedicationInRange(
          medicationId: med.id,
          start: weekStart,
          end: weekEnd,
        ),
      );
    }

    allEvents.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    double? dailyAdherencePercent;
    List<double> weeklyAdherencePercents = const [];

    final selectedMedicationId = _selectedMedicationId;
    if (selectedMedicationId != null) {
      final dosingService = DosingService(
        db: appDb,
        medicationDao: medicationDao,
        doseScheduleDao: doseScheduleDao,
        doseEventDao: doseEventDao,
        userSettingsDao: userSettingsDao,
      );

      final today = DateTime.now();
      dailyAdherencePercent = await dosingService.getDailyAdherencePercent(
        medicationId: selectedMedicationId,
        day: today,
      );
      weeklyAdherencePercents = await dosingService
          .getWeeklyAdherenceSummaryPercentages(
            medicationId: selectedMedicationId,
            endDay: today,
          );
    }

    setState(() {
      _medications = meds;
      _events = allEvents;
      _dailyAdherencePercent = dailyAdherencePercent;
      _weeklyAdherencePercents = weeklyAdherencePercents;
      _loading = false;
    });
  }

  void _previousWeek() {
    setState(() {
      _currentWeekEnd = _currentWeekEnd.subtract(const Duration(days: 7));
    });
    _reload();
  }

  void _nextWeek() {
    setState(() {
      _currentWeekEnd = _currentWeekEnd.add(const Duration(days: 7));
    });
    _reload();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentWeekEnd,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _currentWeekEnd = picked;
      });
      await _reload();
    }
  }

  String _weekRangeLabel() {
    final endDay = _currentWeekEnd;
    final daysIntoWeek = (endDay.weekday - DateTime.monday) % 7;
    final weekStart = endDay.subtract(Duration(days: daysIntoWeek));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final startStr =
        '${weekStart.month.toString().padLeft(2, '0')}/${weekStart.day.toString().padLeft(2, '0')}';
    final endStr =
        '${weekEnd.month.toString().padLeft(2, '0')}/${weekEnd.day.toString().padLeft(2, '0')}';

    return '$startStr - $endStr';
  }

  Future<void> _editEventStatus(DoseEvent event) async {
    // Manually tweak a dose event if the user needs to fix it.
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

  Future<void> _refreshAdherence() async {
    // Recompute adherence for the selected medication only.
    final selectedMedicationId = _selectedMedicationId;
    if (selectedMedicationId == null) return;

    setState(() => _adherenceLoading = true);

    final medicationDao = ref.read(medicationDaoProvider);
    final doseScheduleDao = ref.read(doseScheduleDaoProvider);
    final doseEventDao = ref.read(doseEventDaoProvider);
    final userSettingsDao = ref.read(userSettingsDaoProvider);
    final appDb = ref.read(appDatabaseProvider);

    final dosingService = DosingService(
      db: appDb,
      medicationDao: medicationDao,
      doseScheduleDao: doseScheduleDao,
      doseEventDao: doseEventDao,
      userSettingsDao: userSettingsDao,
    );

    final today = DateTime.now();
    final daily = await dosingService.getDailyAdherencePercent(
      medicationId: selectedMedicationId,
      day: today,
    );
    final weekly = await dosingService.getWeeklyAdherenceSummaryPercentages(
      medicationId: selectedMedicationId,
      endDay: today,
    );

    if (!mounted) return;
    setState(() {
      _dailyAdherencePercent = daily;
      _weeklyAdherencePercents = weekly;
      _adherenceLoading = false;
    });
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: AppNavigationController.showToday,
          tooltip: 'Back to today',
        ),
        title: const Text('History'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _previousWeek,
                        tooltip: 'Previous week',
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Center(
                            child: Text(
                              'Week: ${_weekRangeLabel()}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _nextWeek,
                        tooltip: 'Next week',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String?>(
                    isExpanded: true,
                    value: _selectedMedicationId,
                    hint: const Text('Filter by medication'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All medications'),
                      ),
                      ..._medications.map(
                        (m) => DropdownMenuItem<String?>(
                          value: m.id,
                          child: Text(m.name),
                        ),
                      ),
                    ],
                    onChanged: (v) async {
                      setState(() {
                        _selectedMedicationId = v;
                        _dailyAdherencePercent = null;
                        _weeklyAdherencePercents = const [];
                      });
                      await _reload();
                    },
                  ),
                  const SizedBox(height: 18),
                  _AdherenceSummaryCard(
                    selectedMedicationId: _selectedMedicationId,
                    medications: _medications,
                    dailyAdherencePercent: _dailyAdherencePercent,
                    weeklyAdherencePercents: _weeklyAdherencePercents,
                    loading: _adherenceLoading,
                    onRefresh: _refreshAdherence,
                  ),
                  const SizedBox(height: 18),
                  _events.isEmpty
                      ? const Center(child: Text('Waiting in quiet orbit.'))
                      : Column(
                          children: _events.map((e) {
                            final medName =
                                _medications
                                    .where((m) => m.id == e.medicationId)
                                    .firstOrNull
                                    ?.name ??
                                'Unknown medication';
                            final timeText = TimeOfDay.fromDateTime(
                              e.scheduledAt,
                            ).format(context);
                            final dateText =
                                '${e.scheduledAt.year.toString().padLeft(4, '0')}-${e.scheduledAt.month.toString().padLeft(2, '0')}-${e.scheduledAt.day.toString().padLeft(2, '0')}';

                            Color chipColor;
                            switch (e.status) {
                              case doseStatusTaken:
                                chipColor = Theme.of(
                                  context,
                                ).colorScheme.secondary;
                                break;
                              case doseStatusMissed:
                                chipColor = Theme.of(context).colorScheme.error;
                                break;
                              case doseStatusSkipped:
                                chipColor = Theme.of(
                                  context,
                                ).colorScheme.outline;
                                break;
                              default:
                                chipColor = Theme.of(
                                  context,
                                ).colorScheme.primary;
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
                                            medName,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          tooltip: 'Edit status',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _editEventStatus(e),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: chipColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            _statusLabel(e.status),
                                            style: TextStyle(
                                              color: chipColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Scheduled: $dateText • $timeText'),
                                    if (e.takenAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Taken at: ${TimeOfDay.fromDateTime(e.takenAt!).format(context)}',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }
}

class _AdherenceSummaryCard extends StatelessWidget {
  const _AdherenceSummaryCard({
    required this.selectedMedicationId,
    required this.medications,
    required this.dailyAdherencePercent,
    required this.weeklyAdherencePercents,
    required this.loading,
    required this.onRefresh,
  });

  final String? selectedMedicationId;
  final List<Medication> medications;
  final double? dailyAdherencePercent;
  final List<double> weeklyAdherencePercents;
  final bool loading;
  final Future<void> Function() onRefresh;

  String _medicationName() {
    final id = selectedMedicationId;
    if (id == null) return 'No medication selected';
    return medications.where((m) => m.id == id).firstOrNull?.name ??
        'Selected medication';
  }

  String _percentText(double? value) {
    if (value == null) return '--';
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedMedicationId != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Adherence: ${_medicationName()}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: hasSelection && !loading ? onRefresh : null,
                  child: Text(loading ? 'Loading...' : 'Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasSelection)
              const Text('Select a medication to see adherence.')
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Today',
                      value: _percentText(dailyAdherencePercent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Week average',
                      value: _percentText(
                        weeklyAdherencePercents.isEmpty
                            ? null
                            : weeklyAdherencePercents.reduce((a, b) => a + b) /
                                  weeklyAdherencePercents.length,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Weekly rhythm',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _WeeklyAdherenceChart(
                values: weeklyAdherencePercents,
                referenceDay: DateTime.now(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _WeeklyAdherenceChart extends StatefulWidget {
  const _WeeklyAdherenceChart({
    required this.values,
    required this.referenceDay,
  });

  final List<double> values;
  final DateTime referenceDay;

  @override
  State<_WeeklyAdherenceChart> createState() => _WeeklyAdherenceChartState();
}

class _WeeklyAdherenceChartState extends State<_WeeklyAdherenceChart> {
  int? _selectedIndex;

  String _percentText(double value) => '${(value * 100).toStringAsFixed(0)}%';

  DateTime _dayAtChartIndex(int index) {
    final refDay = DateTime(
      widget.referenceDay.year,
      widget.referenceDay.month,
      widget.referenceDay.day,
    );
    return refDay.subtract(Duration(days: 6 - index));
  }

  String _dateLabel(int index) {
    final day = _dayAtChartIndex(index);
    return '${day.month.toString().padLeft(2, '0')}/${day.day.toString().padLeft(2, '0')}';
  }

  String _weekdayAbbrev(BuildContext context, int index) {
    final day = _dayAtChartIndex(index);
    return DateFormat.E(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(day);
  }

  String _relativeLabel(int index) {
    final offset = 6 - index;
    return switch (offset) {
      0 => 'Today',
      1 => '1 day ago',
      _ => '$offset days ago',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No adherence data.')),
      );
    }

    final selectedIndex = _selectedIndex ?? (widget.values.length - 1);
    final selectedValue = widget.values[selectedIndex].clamp(0.0, 1.0);
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
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bar height is 0–100% for that calendar day (taken or skipped doses count toward adherence).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(widget.values.length, (index) {
                  final value = widget.values[index].clamp(0.0, 1.0);
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
                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      height: trackH,
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
                                            milliseconds: 260,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          width: double.infinity,
                                          height: fillH.clamp(0.0, trackH),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.92,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withValues(
                                                  alpha: 0.20,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
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
                              _weekdayAbbrev(context, index),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                            Text(
                              _dateLabel(index),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weekdayAbbrev(context, selectedIndex)} · ${_dateLabel(selectedIndex)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_relativeLabel(selectedIndex)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Adherence: ${_percentText(selectedValue)}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
