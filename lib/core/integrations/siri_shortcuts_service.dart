import 'dart:io';

import 'package:flutter/services.dart';

// iOS shortcut bridge for opening tabs and sharing summary data.
class SiriShortcutsService {
  SiriShortcutsService._();

  static final SiriShortcutsService instance = SiriShortcutsService._();

  // Native method channel used by the iOS side.
  static const MethodChannel _channel = MethodChannel('dosey/siri_shortcuts');

  bool _initialized = false;

  void Function()? _onOpenMedications;
  void Function()? _onOpenHistory;
  void Function()? _onOpenToday;

  Future<void> initialize({
    void Function()? onOpenMedications,
    void Function()? onOpenHistory,
    void Function()? onOpenToday,
  }) async {
    // Only iOS needs the shortcut hookup.
    if (_initialized || !Platform.isIOS) return;

    _onOpenMedications = onOpenMedications;
    _onOpenHistory = onOpenHistory;
    _onOpenToday = onOpenToday;

    // Let native code ask us which tab to open.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openDestinationFromSiri') {
        final dest = call.arguments as String? ?? 'medications';
        _applyDestination(dest);
      }
      return null;
    });

    try {
      await _consumePendingDestination();
    } on PlatformException {
      // Native shortcut support is optional; never block app launch.
    } on MissingPluginException {
      // Allows simulator/test builds without the iOS bridge to keep running.
    }

    _initialized = true;
  }

  /// When the app returns to foreground, App Intents may have written a
  /// pending tab destination to the app group.
  Future<void> consumePendingDestinationOnResume() async {
    // On resume, check for a pending destination and apply it.
    if (!Platform.isIOS) return;
    try {
      await _consumePendingDestination();
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<void> _consumePendingDestination() async {
    // Pull the saved tab request out of the native bridge.
    final pending = await _channel.invokeMethod<String>(
      'consumePendingDestination',
    );
    if (pending != null && pending.isNotEmpty) {
      _applyDestination(pending);
    }
  }

  void _applyDestination(String dest) {
    // Map the short string to the right app tab.
    switch (dest) {
      case 'history':
        _onOpenHistory?.call();
        break;
      case 'today':
        _onOpenToday?.call();
        break;
      default:
        _onOpenMedications?.call();
    }
  }

  Future<bool> isAvailable() async {
    // Ask native code if shortcuts are available on this device.
    if (!Platform.isIOS) return false;
    try {
      final available = await _channel.invokeMethod<bool>('isAvailable');
      return available ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Donates a user activity so Siri may suggest it. [destination] is
  /// `today`, `medications`, or `history`.
  Future<void> donateNavigationShortcut(String destination) async {
    // Small Siri hint for the main navigation destinations.
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('donateNavigationShortcut', {
        'destination': destination,
      });
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<void> updateDailySummary({
    required DateTime date,
    required int takenDoses,
    required int remainingDoses,
    required List<String> takenMedicationNames,
    required List<String> remainingMedicationNames,
    int? totalDosesToday,
    int? completedDosesToday,
    int? nextDoseEpochMs,
    String? nextDoseMedicationName,
    bool? darkMode,
    bool? highContrast,
    double? uiScale,
  }) async {
    // Push the daily summary data into the widget/shortcut layer.
    if (!Platform.isIOS) return;

    final localDay = DateTime(date.year, date.month, date.day);
    final dayStamp =
        '${localDay.year.toString().padLeft(4, '0')}-${localDay.month.toString().padLeft(2, '0')}-${localDay.day.toString().padLeft(2, '0')}';

    final inferredTotal = takenDoses + remainingDoses;
    try {
      await _channel.invokeMethod<void>('updateDailySummary', {
        'dayStamp': dayStamp,
        'takenDoses': takenDoses,
        'remainingDoses': remainingDoses,
        'takenMedicationNames': takenMedicationNames,
        'remainingMedicationNames': remainingMedicationNames,
        'totalDosesToday': totalDosesToday ?? inferredTotal,
        'completedDosesToday': completedDosesToday ?? takenDoses,
        'nextDoseEpochMs': nextDoseEpochMs ?? -1,
        'nextDoseMedicationName': nextDoseMedicationName ?? '',
        'darkMode': darkMode ?? false,
        'highContrast': highContrast ?? false,
        'uiScale': uiScale ?? 1.0,
      });
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<void> updateWidgetAppearance({
    required bool darkMode,
    required bool highContrast,
    required double uiScale,
  }) async {
    // Keep the iOS widget matching the app's look.
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('updateWidgetAppearance', {
        'darkMode': darkMode,
        'highContrast': highContrast,
        'uiScale': uiScale,
      });
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
