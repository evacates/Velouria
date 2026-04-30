import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dosing/presentation/today_screen.dart';
import '../features/medications/medications_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../core/app/app_initializer.dart';
import '../core/app/app_navigation.dart';
import '../core/integrations/siri_shortcuts_service.dart';

// Bottom-less app shell that just swaps the main tab content.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _initInFlight = false;

  @override
  void initState() {
    super.initState();
    // Listen for navigation changes and do the startup work after first draw.
    WidgetsBinding.instance.addObserver(this);
    AppNavigationController.tabIndex.addListener(_onTabIndexChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_initInFlight) return;
      _initInFlight = true;
      try {
        await initializeApp(ref);
        unawaited(
          SiriShortcutsService.instance.donateNavigationShortcut('today'),
        );
        unawaited(
          SiriShortcutsService.instance.donateNavigationShortcut('medications'),
        );
        unawaited(
          SiriShortcutsService.instance.donateNavigationShortcut('history'),
        );
      } catch (e, st) {
        debugPrint('AppShell: initializeApp failed: $e');
        debugPrint('StackTrace: $st');
      } finally {
        _initInFlight = false;
      }
    });
  }

  void _onTabIndexChanged() {
    // Mirror the shared tab state into this shell widget.
    if (!mounted) return;
    final newIndex = AppNavigationController.tabIndex.value;
    if (newIndex == _index) return;
    setState(() => _index = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    // The IndexedStack keeps each tab alive.
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [TodayScreen(), MedicationsScreen(), SettingsScreen()],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the listeners so the shell does not leak.
    AppNavigationController.tabIndex.removeListener(_onTabIndexChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When resuming, catch any pending Siri destination and refresh setup.
    if (state != AppLifecycleState.resumed) return;
    unawaited(
      SiriShortcutsService.instance.consumePendingDestinationOnResume(),
    );
    if (_initInFlight) return;
    _initInFlight = true;
    initializeApp(ref).whenComplete(() => _initInFlight = false);
  }
}
