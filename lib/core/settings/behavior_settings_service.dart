import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Small bundle of app behavior switches and visual settings.
class BehaviorSettings {
  const BehaviorSettings({
    required this.showStreakIndicator,
    required this.adaptiveReminderTiming,
    required this.allergyKeywords,
    required this.uiScale,
    required this.highContrast,
    required this.darkMode,
  });

  static const defaults = BehaviorSettings(
    showStreakIndicator: true,
    adaptiveReminderTiming: true,
    allergyKeywords: [],
    uiScale: 1,
    highContrast: false,
    darkMode: true,
  );

  final bool showStreakIndicator;
  final bool adaptiveReminderTiming;
  final List<String> allergyKeywords;
  final double uiScale;
  final bool highContrast;
  final bool darkMode;

  BehaviorSettings copyWith({
    bool? showStreakIndicator,
    bool? adaptiveReminderTiming,
    List<String>? allergyKeywords,
    double? uiScale,
    bool? highContrast,
    bool? darkMode,
  }) {
    return BehaviorSettings(
      showStreakIndicator: showStreakIndicator ?? this.showStreakIndicator,
      adaptiveReminderTiming:
          adaptiveReminderTiming ?? this.adaptiveReminderTiming,
      allergyKeywords: allergyKeywords ?? this.allergyKeywords,
      uiScale: uiScale ?? this.uiScale,
      highContrast: highContrast ?? this.highContrast,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class BehaviorSettingsService {
  BehaviorSettingsService._();

  // Notifier so the UI can rebuild when settings change.
  static final ValueNotifier<BehaviorSettings> notifier = ValueNotifier(
    BehaviorSettings.defaults,
  );

  // Shared prefs keys, just the usual stuff.
  static const _showStreakKey = 'show_streak_indicator';
  static const _adaptiveReminderKey = 'adaptive_reminder_timing';
  static const _allergyKeywordsKey = 'allergy_keywords';
  static const _uiScaleKey = 'ui_scale';
  static const _highContrastKey = 'high_contrast';
  static const _darkModeKey = 'dark_mode';
  static const _velouriaDarkDefaultAppliedKey = 'velouria_dark_default_applied';

  static Future<BehaviorSettings> load() async {
    // Load saved values and clean up older preference values.
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_velouriaDarkDefaultAppliedKey) ?? false)) {
      await prefs.setBool(_darkModeKey, true);
      await prefs.setBool(_velouriaDarkDefaultAppliedKey, true);
    }

    final rawAllergies = prefs.getString(_allergyKeywordsKey) ?? '';
    final allergyKeywords = <String>[];
    for (final raw in rawAllergies.split(',')) {
      final keyword = _titleCaseUserInput(raw);
      if (keyword.isEmpty) continue;
      final alreadyAdded = allergyKeywords.any(
        (existing) => existing.toLowerCase() == keyword.toLowerCase(),
      );
      if (!alreadyAdded) allergyKeywords.add(keyword);
    }
    final normalizedAllergies = allergyKeywords.join(', ');
    if (normalizedAllergies != rawAllergies.trim()) {
      await prefs.setString(_allergyKeywordsKey, normalizedAllergies);
    }

    final settings = BehaviorSettings(
      showStreakIndicator: prefs.getBool(_showStreakKey) ?? true,
      adaptiveReminderTiming: prefs.getBool(_adaptiveReminderKey) ?? true,
      allergyKeywords: allergyKeywords,
      uiScale: (prefs.getDouble(_uiScaleKey) ?? 1).clamp(0.85, 1.35),
      highContrast: prefs.getBool(_highContrastKey) ?? false,
      darkMode: prefs.getBool(_darkModeKey) ?? true,
    );
    notifier.value = settings;
    return settings;
  }

  static Future<void> setShowStreakIndicator(bool value) async {
    // Save the toggle, then refresh the in-memory copy.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showStreakKey, value);
    await load();
  }

  static Future<void> setAdaptiveReminderTiming(bool value) async {
    // Same idea, just the reminder timing toggle.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adaptiveReminderKey, value);
    await load();
  }

  static Future<void> setAllergyKeywordsCsv(String value) async {
    // Store allergy words as one comma-separated string.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_allergyKeywordsKey, value.trim());
    await load();
  }

  static Future<void> setUiScale(double value) async {
    // Keep UI scale in a safe-ish range.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_uiScaleKey, value.clamp(0.85, 1.35));
    await load();
  }

  static Future<void> setHighContrast(bool value) async {
    // High contrast is just another checkbox.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
    await load();
  }

  static Future<void> setDarkMode(bool value) async {
    // Dark mode is stored separately so it survives restarts.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    await load();
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
}
