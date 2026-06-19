import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum EventType {
  newMed,
  stoppedMed,
  stress,
  cycleStart,
  cycleEnd,
  temperature,
  other,
}

extension EventTypeExtension on EventType {
  String get label {
    switch (this) {
      case EventType.newMed:
        return 'New Medication';
      case EventType.stoppedMed:
        return 'Stopped Medication';
      case EventType.stress:
        return 'Stressful Event';
      case EventType.cycleStart:
        return 'Cycle Start';
      case EventType.cycleEnd:
        return 'Cycle End';
      case EventType.temperature:
        return 'Temperature Log';
      case EventType.other:
        return 'Other';
    }
  }

  String get dbValue {
    switch (this) {
      case EventType.newMed:
        return 'new_med';
      case EventType.stoppedMed:
        return 'stopped_med';
      case EventType.stress:
        return 'stress';
      case EventType.cycleStart:
        return 'cycle_start';
      case EventType.cycleEnd:
        return 'cycle_end';
      case EventType.temperature:
        return 'temperature';
      case EventType.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.newMed:
        return Icons.medication_outlined;
      case EventType.stoppedMed:
        return Icons.medication_liquid_outlined;
      case EventType.stress:
        return Icons.bolt_outlined;
      case EventType.cycleStart:
        return Icons.circle_outlined;
      case EventType.cycleEnd:
        return Icons.circle;
      case EventType.temperature:
        return Icons.thermostat_outlined;
      case EventType.other:
        return Icons.note_outlined;
    }
  }

  Color get color {
    switch (this) {
      case EventType.newMed:
        return const Color(0xFF4CAF50);
      case EventType.stoppedMed:
        return const Color(0xFFE57373);
      case EventType.stress:
        return const Color(0xFFFF9800);
      case EventType.cycleStart:
        return const Color(0xFFE91E63);
      case EventType.cycleEnd:
        return const Color(0xFF9C27B0);
      case EventType.temperature:
        return const Color(0xFF2196F3);
      case EventType.other:
        return const Color(0xFF9E9E9E);
    }
  }

  static EventType fromDbValue(String value) {
    switch (value) {
      case 'new_med':
        return EventType.newMed;
      case 'stopped_med':
        return EventType.stoppedMed;
      case 'stress':
        return EventType.stress;
      case 'cycle_start':
        return EventType.cycleStart;
      case 'cycle_end':
        return EventType.cycleEnd;
      case 'temperature':
        return EventType.temperature;
      default:
        return EventType.other;
    }
  }
}

class EventEntry {
  final int? id;
  final DateTime date;
  final EventType type;
  final String name;
  final double? temperature; // °F current (legacy / fallback)
  final double? tempHigh;   // °F daily high
  final double? tempLow;    // °F daily low
  final String? zipcode;
  final String? notes;

  const EventEntry({
    this.id,
    required this.date,
    required this.type,
    required this.name,
    this.temperature,
    this.tempHigh,
    this.tempLow,
    this.zipcode,
    this.notes,
  });

  String get dateKey => DateFormat('yyyy-MM-dd').format(date);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': dateKey,
        'type': type.dbValue,
        'name': name,
        'temperature': temperature,
        'temp_high': tempHigh,
        'temp_low': tempLow,
        'zipcode': zipcode,
        'notes': notes,
      };

  factory EventEntry.fromMap(Map<String, dynamic> map) => EventEntry(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        type: EventTypeExtension.fromDbValue(map['type'] as String),
        name: (map['name'] as String?) ?? '',
        temperature: map['temperature'] != null
            ? (map['temperature'] as num).toDouble()
            : null,
        tempHigh: map['temp_high'] != null
            ? (map['temp_high'] as num).toDouble()
            : null,
        tempLow: map['temp_low'] != null
            ? (map['temp_low'] as num).toDouble()
            : null,
        zipcode: map['zipcode'] as String?,
        notes: map['notes'] as String?,
      );

  EventEntry copyWith({
    int? id,
    DateTime? date,
    EventType? type,
    String? name,
    double? temperature,
    double? tempHigh,
    double? tempLow,
    String? zipcode,
    String? notes,
  }) =>
      EventEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        type: type ?? this.type,
        name: name ?? this.name,
        temperature: temperature ?? this.temperature,
        tempHigh: tempHigh ?? this.tempHigh,
        tempLow: tempLow ?? this.tempLow,
        zipcode: zipcode ?? this.zipcode,
        notes: notes ?? this.notes,
      );
}
