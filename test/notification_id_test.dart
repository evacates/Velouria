import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:dosey/core/notifications/notification_service.dart';

void main() {
  // Same input should always produce the same reminder id.
  test('notificationIdForOccurrence is deterministic', () {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    final scheduledAt = tz.TZDateTime(tz.local, 2026, 1, 2, 9, 0);

    final id1 = NotificationService.instance.notificationIdForOccurrence(
      'med-1',
      10,
      scheduledAt,
    );

    final id2 = NotificationService.instance.notificationIdForOccurrence(
      'med-1',
      10,
      scheduledAt,
    );

    expect(id1, equals(id2));
  });

  // Different times should not collapse into the same id.
  test('notificationIdForOccurrence changes when scheduledAt changes', () {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    final scheduledAtA = tz.TZDateTime(tz.local, 2026, 1, 2, 9, 0);
    final scheduledAtB = tz.TZDateTime(tz.local, 2026, 1, 2, 20, 0);

    final idA = NotificationService.instance.notificationIdForOccurrence(
      'med-1',
      10,
      scheduledAtA,
    );

    final idB = NotificationService.instance.notificationIdForOccurrence(
      'med-1',
      10,
      scheduledAtB,
    );

    expect(idA, isNot(equals(idB)));
  });
}
