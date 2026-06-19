import 'package:intl/intl.dart';

class SymptomEntry {
  final int? id;
  final DateTime date;
  final int hotFlashes;     // 0 = none, 1-5 severity
  final int nausea;         // 0-5
  final int sleeplessness;  // 0-5
  final int exhaustion;     // 0-5
  final bool cycle;         // true = period today
  final int bloat;          // 0-5
  final int appetite;       // -1 decrease, 0 normal, 1 increase
  final String? notes;

  const SymptomEntry({
    this.id,
    required this.date,
    this.hotFlashes = 0,
    this.nausea = 0,
    this.sleeplessness = 0,
    this.exhaustion = 0,
    this.cycle = false,
    this.bloat = 0,
    this.appetite = 0,
    this.notes,
  });

  String get dateKey => DateFormat('yyyy-MM-dd').format(date);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': dateKey,
        'hot_flashes': hotFlashes,
        'nausea': nausea,
        'sleeplessness': sleeplessness,
        'exhaustion': exhaustion,
        'cycle': cycle ? 1 : 0,
        'bloat': bloat,
        'appetite': appetite,
        'notes': notes,
      };

  factory SymptomEntry.fromMap(Map<String, dynamic> map) => SymptomEntry(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        hotFlashes: (map['hot_flashes'] as int?) ?? 0,
        nausea: (map['nausea'] as int?) ?? 0,
        sleeplessness: (map['sleeplessness'] as int?) ?? 0,
        exhaustion: (map['exhaustion'] as int?) ?? 0,
        cycle: ((map['cycle'] as int?) ?? 0) == 1,
        bloat: (map['bloat'] as int?) ?? 0,
        appetite: (map['appetite'] as int?) ?? 0,
        notes: map['notes'] as String?,
      );

  SymptomEntry copyWith({
    int? id,
    DateTime? date,
    int? hotFlashes,
    int? nausea,
    int? sleeplessness,
    int? exhaustion,
    bool? cycle,
    int? bloat,
    int? appetite,
    String? notes,
  }) =>
      SymptomEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        hotFlashes: hotFlashes ?? this.hotFlashes,
        nausea: nausea ?? this.nausea,
        sleeplessness: sleeplessness ?? this.sleeplessness,
        exhaustion: exhaustion ?? this.exhaustion,
        cycle: cycle ?? this.cycle,
        bloat: bloat ?? this.bloat,
        appetite: appetite ?? this.appetite,
        notes: notes ?? this.notes,
      );

  bool get hasAnySymptom =>
      hotFlashes > 0 ||
      nausea > 0 ||
      sleeplessness > 0 ||
      exhaustion > 0 ||
      cycle ||
      bloat > 0 ||
      appetite != 0;

  double get totalSeverity =>
      (hotFlashes + nausea + sleeplessness + exhaustion + bloat).toDouble();
}
