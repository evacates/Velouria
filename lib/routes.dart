import 'package:flutter/widgets.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const HomeScreen(),
        settings: (_) => const SettingsScreen(),
      };
}

