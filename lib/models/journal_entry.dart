import 'package:intl/intl.dart';

class JournalEntry {
  final int? id;
  final DateTime date;
  final String content;

  const JournalEntry({
    this.id,
    required this.date,
    required this.content,
  });

  String get dateKey => DateFormat('yyyy-MM-dd').format(date);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': dateKey,
        'content': content,
      };

  static JournalEntry fromMap(Map<String, dynamic> m) => JournalEntry(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        content: m['content'] as String? ?? '',
      );

  JournalEntry copyWith({int? id, DateTime? date, String? content}) =>
      JournalEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        content: content ?? this.content,
      );
}
