import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drift/drift.dart' show Value;

import '../../../core/app/app_navigation.dart';
import '../../../core/db/db_providers.dart';
import '../../../core/integrations/siri_shortcuts_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/settings/behavior_settings_service.dart';
import '../../../core/time/timezone_mode_service.dart';
import '../../../core/time/timezone_service.dart';
import '../../../core/db/app_database.dart';
import '../../dosing/domain/dosing_services.dart';

// Settings page for all the tweakable app behavior.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = true;

  late final TextEditingController _graceMinutesC;
  late final TextEditingController _lowPillDaysC;

  TimezoneDoseMode _timezoneMode = TimezoneDoseMode.followDevice;
  TimezoneDoseMode _initialTimezoneMode = TimezoneDoseMode.followDevice;
  bool _showStreakIndicator = true;
  bool _adaptiveReminderTiming = true;
  bool _initialAdaptiveReminderTiming = true;
  double _uiScale = 1;
  bool _highContrast = false;
  bool _darkMode = false;
  @override
  void initState() {
    super.initState();
    _graceMinutesC = TextEditingController(text: '120');
    _lowPillDaysC = TextEditingController(text: '3');
    _load();
  }

  Future<void> _load() async {
    // Pull in saved values and fill the inputs.
    final userSettingsDao = ref.read(userSettingsDaoProvider);
    final existing = await userSettingsDao.getSingleton();
    if (existing == null) {
      await userSettingsDao.ensureDefaultSingleton();
    }

    final s = await userSettingsDao.getSingleton();
    if (!mounted) return;

    final tzMode = await TimezoneModeService.getMode();
    final behavior = await BehaviorSettingsService.load();

    setState(() {
      _graceMinutesC.text = (s?.doseGraceMinutes ?? 120).toString();
      _lowPillDaysC.text = (s?.lowPillWarningDays ?? 3).toString();
      _timezoneMode = tzMode;
      _initialTimezoneMode = tzMode;
      _showStreakIndicator = behavior.showStreakIndicator;
      _adaptiveReminderTiming = behavior.adaptiveReminderTiming;
      _initialAdaptiveReminderTiming = behavior.adaptiveReminderTiming;
      _uiScale = behavior.uiScale;
      _highContrast = behavior.highContrast;
      _darkMode = behavior.darkMode;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _graceMinutesC.dispose();
    _lowPillDaysC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Save the form stuff and rebuild notifications if needed.
    final userSettingsDao = ref.read(userSettingsDaoProvider);
    final medicationDao = ref.read(medicationDaoProvider);
    final doseScheduleDao = ref.read(doseScheduleDaoProvider);
    final doseEventDao = ref.read(doseEventDaoProvider);
    final graceMinutes = int.tryParse(_graceMinutesC.text.trim()) ?? 120;
    final lowPillDays = int.tryParse(_lowPillDaysC.text.trim()) ?? 3;
    final currentTimezoneName = await TimezoneService.getDeviceTimezoneName();

    final modeChanged = _timezoneMode != _initialTimezoneMode;
    final adaptiveChanged =
        _adaptiveReminderTiming != _initialAdaptiveReminderTiming;
    final shouldRescheduleNotifications = modeChanged || adaptiveChanged;

    final dosingService = DosingService(
      db: ref.read(appDatabaseProvider),
      medicationDao: medicationDao,
      doseScheduleDao: doseScheduleDao,
      doseEventDao: doseEventDao,
      userSettingsDao: userSettingsDao,
    );

    if (shouldRescheduleNotifications) {
      final meds = await medicationDao.getAll();
      for (final med in meds.where((m) => m.isActive)) {
        final times = await doseScheduleDao.getByMedicationId(med.id);
        await NotificationService.instance
            .cancelUpcomingDoseNotificationsForMedication(
              medication: med,
              scheduleTimes: times,
              timezoneName: currentTimezoneName,
            );
      }

      if (modeChanged) {
        if (_timezoneMode == TimezoneDoseMode.followDevice) {
          await doseScheduleDao.clearAllTimezones();
        } else {
          await doseScheduleDao.setNullTimezonesTo(currentTimezoneName);
        }
      }

      for (final med in meds.where((m) => m.isActive)) {
        final times = await doseScheduleDao.getByMedicationId(med.id);
        var reminderOffsetMinutes = 0;
        if (_adaptiveReminderTiming) {
          reminderOffsetMinutes = await dosingService
              .getAdaptiveReminderOffsetMinutes(medicationId: med.id);
        }
        await NotificationService.instance
            .scheduleUpcomingDoseNotificationsForMedication(
              medication: med,
              scheduleTimes: times,
              timezoneName: currentTimezoneName,
              reminderOffsetMinutes: reminderOffsetMinutes,
            );
      }
    }

    await TimezoneModeService.setMode(_timezoneMode);
    await BehaviorSettingsService.setShowStreakIndicator(_showStreakIndicator);
    await BehaviorSettingsService.setAdaptiveReminderTiming(
      _adaptiveReminderTiming,
    );
    await BehaviorSettingsService.setUiScale(_uiScale);
    await BehaviorSettingsService.setHighContrast(_highContrast);
    await BehaviorSettingsService.setDarkMode(_darkMode);
    await SiriShortcutsService.instance.updateWidgetAppearance(
      darkMode: _darkMode,
      highContrast: _highContrast,
      uiScale: _uiScale,
    );

    await userSettingsDao.upsertSingleton(
      UserSettingsCompanion(
        id: const Value(1),
        doseGraceMinutes: Value(graceMinutes),
        lowPillWarningDays: Value(lowPillDays),
        lastTimezone: const Value.absent(),
      ),
    );

    _initialTimezoneMode = _timezoneMode;
    _initialAdaptiveReminderTiming = _adaptiveReminderTiming;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
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
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Missed dose window',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _graceMinutesC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Grace minutes after reminder',
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Refill window',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _lowPillDaysC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Refill reminder lead time (days)',
                    helperText:
                        'Low supply alerts also use each medication threshold.',
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Timezone',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Card(
                  child: RadioGroup<TimezoneDoseMode>(
                    groupValue: _timezoneMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _timezoneMode = value);
                    },
                    child: Column(
                      children: const [
                        RadioListTile<TimezoneDoseMode>(
                          value: TimezoneDoseMode.followDevice,
                          title: Text('Follow device timezone'),
                        ),
                        Divider(height: 1),
                        RadioListTile<TimezoneDoseMode>(
                          value: TimezoneDoseMode.anchorOriginal,
                          title: Text('Anchor to original timezone'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _timezoneMode == TimezoneDoseMode.followDevice
                      ? 'Dose times move with your current timezone while traveling.'
                      : 'Dose times stay pinned to the timezone where they were scheduled.',
                ),
                const SizedBox(height: 22),
                const Text(
                  'Behavior',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _adaptiveReminderTiming,
                  title: const Text('Adaptive reminder timing'),
                  subtitle: const Text(
                    'Adjust reminders toward recent confirmation times.',
                  ),
                  onChanged: (v) => setState(() => _adaptiveReminderTiming = v),
                ),
                SwitchListTile(
                  value: _showStreakIndicator,
                  title: const Text('Show rhythm details'),
                  subtitle: const Text('Show rhythm and adherence details.'),
                  onChanged: (v) => setState(() => _showStreakIndicator = v),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Appearance',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _darkMode,
                        title: const Text('Dark mode'),
                        subtitle: const Text(
                          'Deep emerald surfaces with restrained accents.',
                        ),
                        onChanged: (value) => setState(() => _darkMode = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Accessibility',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Text size: ${(_uiScale * 100).round()}%'),
                        Slider(
                          value: _uiScale,
                          min: 0.85,
                          max: 1.35,
                          divisions: 10,
                          label: '${(_uiScale * 100).round()}%',
                          onChanged: (value) =>
                              setState(() => _uiScale = value),
                        ),
                        MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaler: TextScaler.linear(_uiScale)),
                          child: Card(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Preview: Next dose at 9:00 AM.'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _highContrast,
                          title: const Text('High contrast colors'),
                          subtitle: const Text(
                            'Clearer text, controls, and status accents.',
                          ),
                          onChanged: (value) =>
                              setState(() => _highContrast = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save settings'),
                ),
              ],
            ),
    );
  }
}
