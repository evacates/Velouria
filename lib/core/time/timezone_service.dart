import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  TimezoneService._();

  // If detection fails, UTC is the boring fallback.
  static const fallbackTimezone = 'UTC';

  static Future<String> getDeviceTimezoneName() async {
    // Ask the platform first, then sanity-check the result.
    try {
      final detected = await FlutterTimezone.getLocalTimezone();
      final value = detected.trim();
      if (value.isEmpty) return fallbackTimezone;

      tz.getLocation(value);
      return value;
    } catch (_) {
      return fallbackTimezone;
    }
  }
}
