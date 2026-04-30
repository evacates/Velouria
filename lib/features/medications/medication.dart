import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// Tiny medication model used by the UI and database layer.
class Medication {
  final String id;
  final int notificationId;

  final String name;
  final String? notes;

  final TimeOfDay? timeOfDay;

  const Medication({
    required this.id,
    required this.notificationId,
    required this.name,
    this.notes,
    this.timeOfDay,
  });

  // Make a new medication with a random id and a usable notif id.
  static Medication create({
    required String name,
    String? notes,
    TimeOfDay? timeOfDay,
  }) {
    final uuid = const Uuid();

    final notif = uuid.v4().hashCode.abs() % 2000000000;

    return Medication(
      id: uuid.v4(),
      notificationId: notif == 0 ? 1 : notif,
      name: name.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      timeOfDay: timeOfDay,
    );
  }

  // Clone the model while swapping a few fields if needed.
  Medication copyWith({
    String? name,
    String? notes,
    TimeOfDay? timeOfDay,
    int? notificationId,
  }) {
    return Medication(
      id: id,
      notificationId: notificationId ?? this.notificationId,
      name: (name ?? this.name).trim(),
      notes: (notes?.trim().isEmpty == true)
          ? null
          : (notes ?? this.notes)?.trim(),
      timeOfDay: timeOfDay,
    );
  }

  // Plain map format for older save/load paths.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notificationId': notificationId,
      'name': name,
      'notes': notes,
      'timeHour': timeOfDay?.hour,
      'timeMinute': timeOfDay?.minute,
    };
  }

  // Rebuild the model from a map, since the app still uses that sometimes.
  static Medication fromMap(Map data) {
    final hour = data['timeHour'];
    final minute = data['timeMinute'];

    TimeOfDay? t;
    if (hour is int && minute is int) {
      t = TimeOfDay(hour: hour, minute: minute);
    }

    return Medication(
      id: (data['id'] ?? '') as String,
      notificationId: (data['notificationId'] ?? 1) as int,
      name: (data['name'] ?? '') as String,
      notes: data['notes'] as String?,
      timeOfDay: t,
    );
  }
}
