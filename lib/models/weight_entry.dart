import 'package:intl/intl.dart';

class WeightEntry {
  final int? id;
  final DateTime date;
  final double weight;
  final String unit; // 'lbs' or 'kg'
  final String? notes;

  const WeightEntry({
    this.id,
    required this.date,
    required this.weight,
    this.unit = 'lbs',
    this.notes,
  });

  String get dateKey => DateFormat('yyyy-MM-dd').format(date);

  /// Always returns weight in lbs for cross-unit comparisons.
  double get weightInLbs => unit == 'kg' ? weight * 2.20462 : weight;

  /// Always returns weight in kg.
  double get weightInKg => unit == 'lbs' ? weight / 2.20462 : weight;

  /// Returns weight in the given unit.
  double inUnit(String targetUnit) =>
      targetUnit == 'kg' ? weightInKg : weightInLbs;

  String get displayWeight =>
      '${weight.toStringAsFixed(1)} $unit';

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': dateKey,
        'weight': weight,
        'unit': unit,
        'notes': notes,
      };

  factory WeightEntry.fromMap(Map<String, dynamic> map) => WeightEntry(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        weight: (map['weight'] as num).toDouble(),
        unit: (map['unit'] as String?) ?? 'lbs',
        notes: map['notes'] as String?,
      );

  WeightEntry copyWith({
    int? id,
    DateTime? date,
    double? weight,
    String? unit,
    String? notes,
  }) =>
      WeightEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        weight: weight ?? this.weight,
        unit: unit ?? this.unit,
        notes: notes ?? this.notes,
      );
}
