import 'package:shared_preferences/shared_preferences.dart';

// Just two modes for whether dose times follow the device or stay pinned.
enum TimezoneDoseMode { followDevice, anchorOriginal }

class TimezoneModeService {
  TimezoneModeService._();

  // Shared prefs key for the timezone behavior.
  static const String _key = 'timezone_dose_mode';

  static Future<TimezoneDoseMode> getMode() async {
    // Read the saved mode, or fall back to the default.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    return switch (raw) {
      'anchor_original' => TimezoneDoseMode.anchorOriginal,
      _ => TimezoneDoseMode.followDevice,
    };
  }

  static Future<void> setMode(TimezoneDoseMode mode) async {
    // Save whichever mode the user picked.
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      TimezoneDoseMode.followDevice => 'follow_device',
      TimezoneDoseMode.anchorOriginal => 'anchor_original',
    };
    await prefs.setString(_key, raw);
  }
}
