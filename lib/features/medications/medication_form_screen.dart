import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/db/db_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/settings/behavior_settings_service.dart';
import '../../core/time/timezone_mode_service.dart';
import '../../core/time/timezone_service.dart';
import '../dosing/domain/dosing_services.dart';
import 'data/rxnorm_service.dart';

// Form for adding or editing a medication and its schedule times.
class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({super.key, this.medicationId});

  final String? medicationId;

  @override
  ConsumerState<MedicationFormScreen> createState() =>
      _MedicationFormScreenState();
}

class _DoseTimeInput {
  _DoseTimeInput({
    required this.time,
    required this.daysOfWeek,
    required this.repeatEveryXDays,
    required this.intervalDays,
    required this.timezoneName,
    required this.startDate,
    required this.endDate,
  });

  // One time slot on the schedule.
  TimeOfDay time;

  /// Mon=0 .. Sun=6
  Set<int> daysOfWeek;
  bool repeatEveryXDays;
  int intervalDays;
  String? timezoneName;
  DateTime startDate;
  DateTime? endDate;
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  // Some helper objects and controllers for the form.
  final _uuid = const Uuid();
  final _rxNormService = RxNormService();

  bool _loading = false;
  bool _saving = false;
  bool _rxLookupInFlight = false;
  bool _rxSuggestionsLoading = false;
  int _rxSearchToken = 0;
  Timer? _rxDebounce;
  bool _adaptiveReminderTiming = true;
  List<String> _allergyKeywords = const [];

  List<RxNormMedicationSuggestion> _rxSuggestions = [];

  late final TextEditingController _nameC;
  late final TextEditingController _strengthC;
  late final TextEditingController _formC;
  late final TextEditingController _totalPillsC;
  late final TextEditingController _pillPerDoseC;
  late final TextEditingController _refillThresholdC;
  late final TextEditingController _notesC;
  late final TextEditingController _allergyInputC;

  // Dose time slots.
  final List<_DoseTimeInput> _timeInputs = [];

  Medication? _editingMedication;

  @override
  void initState() {
    super.initState();
    // Set up blank form state or load an edit target.
    _loading = widget.medicationId != null;
    _nameC = TextEditingController();
    _nameC.addListener(_onNameChanged);
    _strengthC = TextEditingController();
    _formC = TextEditingController();
    _totalPillsC = TextEditingController(text: '30');
    _pillPerDoseC = TextEditingController(text: '1');
    _refillThresholdC = TextEditingController(text: '5');
    _notesC = TextEditingController();
    _allergyInputC = TextEditingController();

    if (widget.medicationId != null) {
      _loadForEdit(widget.medicationId!);
    } else {
      // Start with one default time.
      _timeInputs.add(
        _DoseTimeInput(
          time: const TimeOfDay(hour: 9, minute: 0),
          daysOfWeek: {0, 1, 2, 3, 4, 5, 6},
          repeatEveryXDays: false,
          intervalDays: 1,
          timezoneName: null,
          startDate: DateTime.now(),
          endDate: null,
        ),
      );
      _loading = false;
    }

    _loadBehaviorSettings();
  }

  @override
  void dispose() {
    _rxDebounce?.cancel();
    _nameC.removeListener(_onNameChanged);
    _nameC.dispose();
    _strengthC.dispose();
    _formC.dispose();
    _totalPillsC.dispose();
    _pillPerDoseC.dispose();
    _refillThresholdC.dispose();
    _notesC.dispose();
    _allergyInputC.dispose();
    super.dispose();
  }

  Future<void> _loadForEdit(String medicationId) async {
    // Fill the form with the saved med and schedule rows.
    final medicationDao = ref.read(medicationDaoProvider);
    final doseScheduleDao = ref.read(doseScheduleDaoProvider);

    final med = await medicationDao.getById(medicationId);
    if (med == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final times = await doseScheduleDao.getByMedicationId(medicationId);

    _editingMedication = med;
    _nameC.text = med.name;
    _strengthC.text = med.strength ?? '';
    _formC.text = med.form ?? '';
    _totalPillsC.text = med.totalPills.toString();
    _pillPerDoseC.text = med.pillPerDose.toString();
    _refillThresholdC.text = med.refillThreshold.toString();
    _notesC.text = med.notes ?? '';
    _rxSuggestions = [];

    _timeInputs.clear();
    for (final t in times) {
      final isInterval = t.daysOfWeekBitmask <= 0;
      _timeInputs.add(
        _DoseTimeInput(
          time: TimeOfDay(hour: t.timeHour, minute: t.timeMinute),
          daysOfWeek: isInterval
              ? {0, 1, 2, 3, 4, 5, 6}
              : _daysFromBitmask(t.daysOfWeekBitmask),
          repeatEveryXDays: isInterval,
          intervalDays: isInterval
              ? (-t.daysOfWeekBitmask).clamp(1, 365).toInt()
              : 1,
          timezoneName: t.timezone,
          startDate: t.startDate,
          endDate: t.endDate,
        ),
      );
    }

    if (_timeInputs.isEmpty) {
      _timeInputs.add(
        _DoseTimeInput(
          time: const TimeOfDay(hour: 9, minute: 0),
          daysOfWeek: {0, 1, 2, 3, 4, 5, 6},
          repeatEveryXDays: false,
          intervalDays: 1,
          timezoneName: null,
          startDate: DateTime.now(),
          endDate: null,
        ),
      );
    }

    setState(() => _loading = false);
  }

  Set<int> _daysFromBitmask(int mask) {
    final result = <int>{};
    for (var i = 0; i < 7; i++) {
      if (((mask >> i) & 1) == 1) result.add(i);
    }
    return result;
  }

  int _bitmaskFromDays(Set<int> days) {
    var mask = 0;
    for (final d in days) {
      mask |= (1 << d);
    }
    return mask;
  }

  Future<void> _pickTime({
    required int index,
    required TimeOfDay initial,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked == null) return;
    setState(() => _timeInputs[index].time = picked);
  }

  Future<void> _autofillFromRxNorm() async {
    // Use RxNorm so the student does not have to type everything.
    final query = _nameC.text.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a medication name first.')),
      );
      return;
    }

    if (_rxLookupInFlight) return;

    setState(() => _rxLookupInFlight = true);

    try {
      final suggestions = await _rxNormService.searchSuggestions(query);
      if (!mounted) return;

      if (suggestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No RxNorm matches found.')),
        );
        return;
      }

      final selected = await showDialog<RxNormMedicationSuggestion>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select RxNorm match'),
          content: SizedBox(
            width: 420,
            height: 340,
            child: ListView.separated(
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = suggestions[i];
                final subtitleParts = <String>[];
                if (s.tty != null && s.tty!.isNotEmpty) {
                  subtitleParts.add(s.tty!);
                }
                if (s.synonym != null && s.synonym!.isNotEmpty) {
                  subtitleParts.add(s.synonym!);
                }

                return ListTile(
                  title: Text(s.name),
                  subtitle: subtitleParts.isEmpty
                      ? null
                      : Text(subtitleParts.join(' • ')),
                  onTap: () => Navigator.of(context).pop(s),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selected == null) return;

      final details = await _rxNormService.fetchDetails(selected.rxcui);
      if (!mounted) return;

      setState(() {
        _nameC.text = _preferredMedicationName(selected.name);
        if ((details.strength ?? '').isNotEmpty) {
          _strengthC.text = details.strength!;
        }
        if ((details.form ?? '').isNotEmpty) {
          _formC.text = details.form!;
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('RxNorm lookup failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _rxLookupInFlight = false);
      }
    }
  }

  void _onNameChanged() {
    // Debounce search input so it does not spam the API.
    final query = _nameC.text.trim();

    _rxDebounce?.cancel();

    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _rxSuggestions = [];
          _rxSuggestionsLoading = false;
        });
      }
      return;
    }

    _rxDebounce = Timer(const Duration(milliseconds: 100), () {
      _searchRxSuggestions(query);
    });
  }

  Future<void> _loadBehaviorSettings() async {
    final settings = await BehaviorSettingsService.load();
    if (!mounted) return;

    setState(() {
      _adaptiveReminderTiming = settings.adaptiveReminderTiming;
      _allergyKeywords = settings.allergyKeywords;
    });
  }

  Future<void> _searchRxSuggestions(String query) async {
    // Fetch the little RxNorm suggestion list.
    final searchToken = ++_rxSearchToken;

    if (mounted) {
      setState(() {
        _rxSuggestionsLoading = true;
      });
    }

    try {
      final suggestions = await _rxNormService.searchSuggestions(query);
      if (!mounted || searchToken != _rxSearchToken) return;

      setState(() {
        _rxSuggestions = suggestions;
        _rxSuggestionsLoading = false;
      });
    } catch (_) {
      if (!mounted || searchToken != _rxSearchToken) return;
      setState(() {
        _rxSuggestions = [];
        _rxSuggestionsLoading = false;
      });
    }
  }

  void _applyRxSuggestion(RxNormMedicationSuggestion suggestion) {
    setState(() {
      _nameC.text = _preferredMedicationName(suggestion.name);
      _rxSuggestions = [];
    });

    _fillRxNormDetails(suggestion);
  }

  Future<void> _fillRxNormDetails(RxNormMedicationSuggestion suggestion) async {
    if (_rxLookupInFlight) return;

    setState(() => _rxLookupInFlight = true);

    try {
      final details = await _rxNormService.fetchDetails(suggestion.rxcui);
      if (!mounted) return;

      setState(() {
        if ((details.strength ?? '').isNotEmpty) {
          _strengthC.text = details.strength!;
        }
        if ((details.form ?? '').isNotEmpty) {
          _formC.text = details.form!;
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('RxNorm autofill failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _rxLookupInFlight = false);
      }
    }
  }

  String _preferredMedicationName(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return cleaned;

    final bracketMatches = RegExp(r'\[(.*?)\]|\((.*?)\)').allMatches(cleaned);
    for (final match in bracketMatches) {
      final bracketed = (match.group(1) ?? match.group(2) ?? '').trim();
      if (bracketed.isNotEmpty) {
        final bracketHasLetters = RegExp(r'[A-Za-z]').hasMatch(bracketed);
        if (bracketHasLetters) {
          return _cleanMedicationLabel(bracketed);
        }
      }
    }

    return _cleanMedicationLabel(cleaned);
  }

  String _cleanMedicationLabel(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return cleaned;

    final stopWords = RegExp(
      r'\b(\d|mg|mcg|g|iu|unit|units|ml|oral|tablet|capsule|solution|suspension|injection|injectable|patch|cream|ointment|gel|drops|spray|powder|extended release|er|sr|xr|dr)\b',
      caseSensitive: false,
    );

    final parts = cleaned.split(RegExp(r'\s+'));
    final kept = <String>[];

    for (final part in parts) {
      if (kept.isNotEmpty && stopWords.hasMatch(part)) break;
      if (kept.isNotEmpty && RegExp(r'^\d').hasMatch(part)) break;
      kept.add(part);
    }

    final shortened = kept.join(' ').trim();
    return shortened.isEmpty ? cleaned : shortened;
  }

  Future<void> _pickDate({
    required int index,
    required DateTime initial,
    required bool isStart,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _timeInputs[index].startDate = picked;
      } else {
        _timeInputs[index].endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    // Validate, save, then reschedule everything.
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final medicationDao = ref.read(medicationDaoProvider);
      final doseScheduleDao = ref.read(doseScheduleDaoProvider);
      final doseEventDao = ref.read(doseEventDaoProvider);
      final userSettingsDao = ref.read(userSettingsDaoProvider);
      final appDb = ref.read(appDatabaseProvider);
      final timezoneName = await TimezoneService.getDeviceTimezoneName();
      final timezoneMode = await TimezoneModeService.getMode();
      final behaviorSettings = await BehaviorSettingsService.load();

      final existing = _editingMedication;
      final medicationId = existing?.id ?? _uuid.v4();

      final name = _titleCaseUserInput(_nameC.text);
      if (name.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication name is required.')),
        );
        return;
      }

      // Check for allergy conflict
      final normalizedMedName = _normalizeAllergyKeyword(name);
      final conflictingAllergy = behaviorSettings.allergyKeywords.firstWhere(
        (allergy) => _normalizeAllergyKeyword(allergy) == normalizedMedName,
        orElse: () => '',
      );
      if (conflictingAllergy.isNotEmpty) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Allergy Conflict'),
            content: Text(
              'You have "$conflictingAllergy" listed as an allergy or sensitivity. '
              'Saving "$name" as a medication may conflict. Continue anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (proceed != true) {
          setState(() => _saving = false);
          return;
        }
      }

      final totalPills = int.tryParse(_totalPillsC.text.trim()) ?? 0;
      final pillPerDose = int.tryParse(_pillPerDoseC.text.trim()) ?? 0;
      final refillThreshold = int.tryParse(_refillThresholdC.text.trim()) ?? 0;

      if (pillPerDose <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Units per dose must be > 0.')),
        );
        return;
      }

      if (_timeInputs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one dose time.')),
        );
        return;
      }

      // Cancel existing upcoming notifications before rescheduling.
      if (existing != null) {
        final oldTimes = await doseScheduleDao.getByMedicationId(medicationId);
        await NotificationService.instance
            .cancelUpcomingDoseNotificationsForMedication(
              medication: existing,
              scheduleTimes: oldTimes,
              timezoneName: timezoneName,
            );
      }

      // Upsert medication.
      await medicationDao.upsert(
        MedicationsCompanion(
          id: Value(medicationId),
          name: Value(name),
          strength: _titleCaseUserInput(_strengthC.text).isEmpty
              ? const Value.absent()
              : Value(_titleCaseUserInput(_strengthC.text)),
          form: _titleCaseUserInput(_formC.text).isEmpty
              ? const Value.absent()
              : Value(_titleCaseUserInput(_formC.text)),
          totalPills: Value(totalPills),
          pillPerDose: Value(pillPerDose),
          refillThreshold: Value(refillThreshold),
          notes: _sentenceCaseUserInput(_notesC.text).isEmpty
              ? const Value.absent()
              : Value(_sentenceCaseUserInput(_notesC.text)),
          isActive: const Value(true),
        ),
      );

      // Replace schedule times.
      await doseScheduleDao.deleteByMedicationId(medicationId);

      final scheduleTimes = _timeInputs.map((input) {
        return DoseScheduleTimesCompanion(
          medicationId: Value(medicationId),
          timeHour: Value(input.time.hour),
          timeMinute: Value(input.time.minute),
          daysOfWeekBitmask: Value(
            input.repeatEveryXDays
                ? -input.intervalDays.clamp(1, 365).toInt()
                : _bitmaskFromDays(input.daysOfWeek),
          ),
          startDate: Value(
            DateTime(
              input.startDate.year,
              input.startDate.month,
              input.startDate.day,
            ),
          ),
          endDate: input.endDate == null
              ? const Value.absent()
              : Value(
                  DateTime(
                    input.endDate!.year,
                    input.endDate!.month,
                    input.endDate!.day,
                  ),
                ),
          timezone: timezoneMode == TimezoneDoseMode.anchorOriginal
              ? Value(input.timezoneName ?? timezoneName)
              : const Value.absent(),
          isEnabled: const Value(true),
        );
      }).toList();

      await doseScheduleDao.insertTimes(scheduleTimes);

      // Reschedule upcoming dose notifications for the updated schedule.
      final updatedMed = await medicationDao.getById(medicationId);
      final updatedTimes = await doseScheduleDao.getByMedicationId(
        medicationId,
      );

      if (updatedMed != null) {
        var reminderOffsetMinutes = 0;
        if (behaviorSettings.adaptiveReminderTiming) {
          final dosingService = DosingService(
            db: appDb,
            medicationDao: medicationDao,
            doseScheduleDao: doseScheduleDao,
            doseEventDao: doseEventDao,
            userSettingsDao: userSettingsDao,
          );

          reminderOffsetMinutes = await dosingService
              .getAdaptiveReminderOffsetMinutes(medicationId: medicationId);

          final weekly = await dosingService
              .getWeeklyAdherenceSummaryPercentages(
                medicationId: medicationId,
                endDay: DateTime.now(),
              );
          if (weekly.isNotEmpty) {
            final avg = weekly.reduce((a, b) => a + b) / weekly.length;
            if (avg < 0.5) {
              reminderOffsetMinutes -= 20;
            } else if (avg < 0.75) {
              reminderOffsetMinutes -= 10;
            }
          }
        }

        await NotificationService.instance
            .scheduleUpcomingDoseNotificationsForMedication(
              medication: updatedMed,
              scheduleTimes: updatedTimes,
              timezoneName: timezoneName,
              reminderOffsetMinutes: reminderOffsetMinutes,
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.medicationId == null
                ? 'Medication added.'
                : 'Medication updated.',
          ),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MedicationFormScreen()),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save medication: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _addAllergyOrSensitivity() async {
    final keyword = _titleCaseUserInput(_allergyInputC.text);
    if (keyword.isEmpty) return;

    final existing = _allergyKeywords
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final normalizedKeyword = _normalizeAllergyKeyword(keyword);
    final alreadyExists = existing.any(
      (item) => _normalizeAllergyKeyword(item) == normalizedKeyword,
    );
    if (!alreadyExists) {
      existing.add(keyword);
      await BehaviorSettingsService.setAllergyKeywordsCsv(existing.join(', '));
      if (!mounted) return;
      setState(() => _allergyKeywords = existing);
      _allergyInputC.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allergy/sensitivity saved.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('That allergy/sensitivity is already added.'),
      ),
    );
  }

  String _normalizeAllergyKeyword(String value) {
    final words = value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(_normalizeAllergyWord)
        .toList(growable: false);
    return words.join(' ');
  }

  String _titleCaseUserInput(String value) {
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

  String _sentenceCaseUserInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  String _normalizeAllergyWord(String word) {
    if (word.length <= 3) return word;
    if (word.endsWith('ies') && word.length > 3) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.endsWith('oes') && word.length > 3) {
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith('s') &&
        !word.endsWith('ss') &&
        !word.endsWith('us') &&
        !word.endsWith('is') &&
        !word.endsWith('x') &&
        !word.endsWith('z') &&
        !word.endsWith('ch') &&
        !word.endsWith('sh')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medicationId == null ? 'Add medication' : 'Edit medication',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: (_loading || _saving) ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameC,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Medication name',
                    helperText:
                        'Tip: use RxNorm autofill for standardized names',
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Allergies & sensitivities',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _allergyInputC,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Add another allergy or sensitivity',
                            hintText: 'e.g. mango',
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addAllergyOrSensitivity(),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            onPressed: _addAllergyOrSensitivity,
                            icon: const Icon(Icons.add),
                            label: const Text('Add allergy/sensitivity'),
                          ),
                        ),
                        if (_allergyKeywords.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Saved allergies are managed from the Home screen.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_rxSuggestionsLoading || _rxSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: _rxSuggestionsLoading && _rxSuggestions.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Searching RxNorm...'),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _rxSuggestions.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final suggestion = _rxSuggestions[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    _preferredMedicationName(suggestion.name),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    suggestion.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _applyRxSuggestion(suggestion),
                                );
                              },
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (_adaptiveReminderTiming)
                  const Text(
                    'Adaptive reminder timing is on: reminders may fire slightly earlier when recent adherence is low.',
                    style: TextStyle(fontSize: 12),
                  ),
                if (_adaptiveReminderTiming) const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: _rxLookupInFlight ? null : _autofillFromRxNorm,
                    icon: _rxLookupInFlight
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.medical_information_outlined),
                    label: Text(
                      _rxLookupInFlight
                          ? 'Searching RxNorm...'
                          : 'Autofill from RxNorm',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _strengthC,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Strength (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _formC,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Medication type/form',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _totalPillsC,
                  decoration: const InputDecoration(
                    labelText: 'Current supply (units)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pillPerDoseC,
                  decoration: const InputDecoration(
                    labelText: 'Units per dose',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _refillThresholdC,
                  decoration: const InputDecoration(
                    labelText: 'Low supply warning at',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesC,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Dose schedule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ..._timeInputs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final input = entry.value;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Time ${index + 1}: ${input.time.format(context)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _pickTime(
                                  index: index,
                                  initial: input.time,
                                ),
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Repeat',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Weekly days'),
                                selected: !input.repeatEveryXDays,
                                onSelected: (_) {
                                  setState(
                                    () => input.repeatEveryXDays = false,
                                  );
                                },
                              ),
                              ChoiceChip(
                                label: Text(
                                  'Every ${input.intervalDays} day(s)',
                                ),
                                selected: input.repeatEveryXDays,
                                onSelected: (_) {
                                  setState(() => input.repeatEveryXDays = true);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (!input.repeatEveryXDays)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(7, (dayIdx) {
                                final selected = input.daysOfWeek.contains(
                                  dayIdx,
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(_dayLabels[dayIdx]),
                                    selected: selected,
                                    onSelected: (v) {
                                      setState(() {
                                        if (v) {
                                          input.daysOfWeek.add(dayIdx);
                                        } else {
                                          input.daysOfWeek.remove(dayIdx);
                                        }
                                        if (input.daysOfWeek.isEmpty) {
                                          input.daysOfWeek.add(dayIdx);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }),
                            )
                          else
                            Row(
                              children: [
                                const Text('Interval:'),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Decrease interval',
                                  onPressed: () {
                                    setState(() {
                                      input.intervalDays =
                                          (input.intervalDays - 1)
                                              .clamp(1, 365)
                                              .toInt();
                                    });
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${input.intervalDays} day(s)'),
                                IconButton(
                                  tooltip: 'Increase interval',
                                  onPressed: () {
                                    setState(() {
                                      input.intervalDays =
                                          (input.intervalDays + 1)
                                              .clamp(1, 365)
                                              .toInt();
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Start: ${_formatDate(input.startDate)}',
                                ),
                              ),
                              TextButton(
                                onPressed: () => _pickDate(
                                  index: index,
                                  initial: input.startDate,
                                  isStart: true,
                                ),
                                child: const Text('Pick'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  input.endDate == null
                                      ? 'No end date'
                                      : 'End: ${_formatDate(input.endDate!)}',
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: input.endDate == null,
                                        onChanged: (v) {
                                          setState(() {
                                            if (v == true) {
                                              input.endDate = null;
                                            } else {
                                              input.endDate ??= DateTime.now();
                                            }
                                          });
                                        },
                                      ),
                                      const Text('No end'),
                                    ],
                                  ),
                                  if (input.endDate != null)
                                    TextButton(
                                      onPressed: () => _pickDate(
                                        index: index,
                                        initial: input.endDate!,
                                        isStart: false,
                                      ),
                                      child: const Text('Pick end'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Remove this time',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                if (_timeInputs.length == 1) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'At least one dose time is required.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _timeInputs.removeAt(index));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(
                  height: 48,
                  child: FilledButton.tonal(
                    onPressed: () {
                      setState(() {
                        _timeInputs.add(
                          _DoseTimeInput(
                            time: const TimeOfDay(hour: 9, minute: 0),
                            daysOfWeek: {0, 1, 2, 3, 4, 5, 6},
                            repeatEveryXDays: false,
                            intervalDays: 1,
                            timezoneName: null,
                            startDate: DateTime.now(),
                            endDate: null,
                          ),
                        );
                      });
                    },
                    child: const Text('Add dose time'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : (widget.medicationId == null
                                ? 'Save medication'
                                : 'Save changes'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
