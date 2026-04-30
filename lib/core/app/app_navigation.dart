import 'package:flutter/foundation.dart';

// Super simple tab state for the app shell.
/// App-level destinations: 0 Home, 1 Medication hub, 2 Settings.
class AppNavigationController {
  AppNavigationController._();

  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  // Jump to the today tab.
  static void showToday() {
    tabIndex.value = 0;
  }

  // Jump to the meds hub.
  static void showMedications() {
    tabIndex.value = 1;
  }

  /// History is part of the medication hub.
  // Same tab, just a different intent.
  static void showHistory() {
    tabIndex.value = 1;
  }

  // Open settings.
  static void showSettings() {
    tabIndex.value = 2;
  }
}
