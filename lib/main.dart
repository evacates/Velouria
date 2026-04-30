import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app/app_shell.dart';
import 'core/app/app_navigation.dart';
import 'core/integrations/siri_shortcuts_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/behavior_settings_service.dart';
import 'core/time/timezone_service.dart';

// App bootstrap: set timezone, load settings, then launch the shell.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final deviceTimezoneName = await TimezoneService.getDeviceTimezoneName();
  tz.setLocalLocation(tz.getLocation(deviceTimezoneName));

  await BehaviorSettingsService.load();
  await NotificationService.instance.init(
    timezoneName: deviceTimezoneName,
    onNotificationTap: (_) => AppNavigationController.showToday(),
  );
  await SiriShortcutsService.instance.initialize(
    onOpenMedications: AppNavigationController.showMedications,
    onOpenHistory: AppNavigationController.showHistory,
    onOpenToday: AppNavigationController.showToday,
  );

  runApp(const ProviderScope(child: DoseyApp()));
}

class DoseyApp extends StatelessWidget {
  const DoseyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole MaterialApp when behavior settings change.
    return ValueListenableBuilder<BehaviorSettings>(
      valueListenable: BehaviorSettingsService.notifier,
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Velouria',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(settings),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(settings.uiScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppShell(),
        );
      },
    );
  }

  ThemeData _buildTheme(BehaviorSettings settings) {
    // Theme colors are custom but still based on a seeded scheme.
    final darkMode = settings.darkMode;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF66D8CB),
      brightness: darkMode ? Brightness.dark : Brightness.light,
    );
    final colorScheme = settings.highContrast
        ? darkMode
              ? scheme.copyWith(
                  primary: const Color(0xFFA8FFF7),
                  onPrimary: const Color(0xFF020A09),
                  primaryContainer: const Color(0xFF123B37),
                  onPrimaryContainer: const Color(0xFFEFFFFD),
                  secondary: const Color(0xFFE0C36A),
                  secondaryContainer: const Color(0xFF302813),
                  onSecondaryContainer: const Color(0xFFFFF5D6),
                  tertiary: const Color(0xFFD59A72),
                  tertiaryContainer: const Color(0xFF3B2117),
                  onTertiaryContainer: const Color(0xFFFFEDE8),
                  surface: const Color(0xFF070D0C),
                  onSurface: const Color(0xFFF7FFFC),
                  surfaceContainerHighest: const Color(0xFF111B19),
                  error: const Color(0xFFE99A8E),
                )
              : scheme.copyWith(
                  primary: const Color(0xFF005B52),
                  onPrimary: Colors.white,
                  surface: const Color(0xFFF7FBF8),
                  onSurface: const Color(0xFF071512),
                  error: const Color(0xFF8C2D22),
                )
        : darkMode
        ? scheme.copyWith(
            primary: const Color(0xFF83E6DC),
            onPrimary: const Color(0xFF050A09),
            primaryContainer: const Color(0xFF123631),
            onPrimaryContainer: const Color(0xFFD8FFFB),
            secondary: const Color(0xFFD9BF6C),
            onSecondary: const Color(0xFF141006),
            secondaryContainer: const Color(0xFF2B2412),
            onSecondaryContainer: const Color(0xFFF7E8B2),
            tertiary: const Color(0xFFC9936C),
            tertiaryContainer: const Color(0xFF352116),
            onTertiaryContainer: const Color(0xFFFFDDD6),
            surface: const Color(0xFF080D0C),
            onSurface: const Color(0xFFF1EFE8),
            surfaceContainerHighest: const Color(0xFF111A18),
            error: const Color(0xFFE99A8E),
          )
        : scheme.copyWith(
            primary: const Color(0xFF006B61),
            onPrimary: const Color(0xFFFFFCF4),
            primaryContainer: const Color(0xFFD7F2ED),
            onPrimaryContainer: const Color(0xFF062925),
            secondary: const Color(0xFF7E6A31),
            secondaryContainer: const Color(0xFFF2E7BC),
            tertiary: const Color(0xFF9D594E),
            tertiaryContainer: const Color(0xFFFFE1DA),
            surface: const Color(0xFFFAF8F2),
            surfaceContainerHighest: const Color(0xFFE6F0ED),
            error: const Color(0xFFA43D32),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: darkMode ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: settings.highContrast
          ? (darkMode ? const Color(0xFF040807) : const Color(0xFFF7FBF8))
          : darkMode
          ? const Color(0xFF040807)
          : const Color(0xFFFAF8F2),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: settings.highContrast
            ? (darkMode ? const Color(0xFF040807) : const Color(0xFFF7FBF8))
            : darkMode
            ? const Color(0xFF040807)
            : const Color(0xFFFAF8F2),
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkMode
            ? (settings.highContrast
                  ? const Color(0xFF111B19)
                  : const Color(0xE60E1715))
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: settings.highContrast
                ? (darkMode ? const Color(0xFF8FFAF0) : const Color(0xFF005B52))
                : darkMode
                ? const Color(0x1F83E6DC)
                : const Color(0xFFD6E4DF),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(
          color: settings.highContrast
              ? (darkMode ? const Color(0xFF8FFAF0) : const Color(0xFF005B52))
              : darkMode
              ? const Color(0x3383E6DC)
              : const Color(0xFFD1DDCF),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkMode
            ? const Color(0xFF0C1412)
            : colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: darkMode ? const Color(0x2683E6DC) : const Color(0xFFC9DAD5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: darkMode ? const Color(0xFFE0C36A) : null,
          foregroundColor: darkMode ? const Color(0xFF121006) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: darkMode ? const Color(0x6683E6DC) : colorScheme.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkMode
            ? const Color(0xFF112B26)
            : const Color(0xFFE6F0ED),
        contentTextStyle: TextStyle(
          color: darkMode ? const Color(0xFFF4F2EA) : const Color(0xFF061512),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
