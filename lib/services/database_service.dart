import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/symptom_entry.dart';
import '../models/weight_entry.dart';
import '../models/event_entry.dart';
import '../models/journal_entry.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  // Broadcast stream — fires whenever any data is written so tabs can refresh.
  final _changeCtrl = StreamController<void>.broadcast();
  Stream<void> get onChange => _changeCtrl.stream;
  void _notify() => _changeCtrl.add(null);

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'regeneration.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE symptom_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        hot_flashes INTEGER DEFAULT 0,
        nausea INTEGER DEFAULT 0,
        sleeplessness INTEGER DEFAULT 0,
        exhaustion INTEGER DEFAULT 0,
        cycle INTEGER DEFAULT 0,
        bloat INTEGER DEFAULT 0,
        appetite INTEGER DEFAULT 0,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'lbs',
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        temperature REAL,
        temp_high REAL,
        temp_low REAL,
        zipcode TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        content TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journal_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          content TEXT NOT NULL DEFAULT ''
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE events ADD COLUMN temp_high REAL');
      await db.execute(
          'ALTER TABLE events ADD COLUMN temp_low REAL');
    }
    if (oldVersion < 4) {
      // Remove legacy temperature events that only have current temp (no high/low).
      // These are meaningless now that we store daily high/low instead.
      await db.execute(
          "DELETE FROM events WHERE type = 'temperature' AND temp_high IS NULL");
    }
  }

  // ── Symptom Entries ────────────────────────────────────────────────────────

  Future<int> upsertSymptom(SymptomEntry entry) async {
    final database = await db;
    final existing = await getSymptomByDate(entry.date);
    int id;
    if (existing != null) {
      await database.update(
        'symptom_entries',
        entry.copyWith(id: existing.id).toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      id = existing.id!;
    } else {
      id = await database.insert('symptom_entries', entry.toMap());
    }
    _notify();
    return id;
  }

  Future<SymptomEntry?> getSymptomByDate(DateTime date) async {
    final database = await db;
    final dateKey = SymptomEntry(date: date).dateKey;
    final rows = await database.query(
      'symptom_entries',
      where: 'date = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SymptomEntry.fromMap(rows.first);
  }

  Future<List<SymptomEntry>> getSymptomsBetween(
      DateTime start, DateTime end) async {
    final database = await db;
    final startKey = SymptomEntry(date: start).dateKey;
    final endKey = SymptomEntry(date: end).dateKey;
    final rows = await database.query(
      'symptom_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'date ASC',
    );
    return rows.map(SymptomEntry.fromMap).toList();
  }

  Future<List<SymptomEntry>> getAllSymptoms() async {
    final database = await db;
    final rows = await database.query(
      'symptom_entries',
      where: 'notes IS NOT NULL',
      orderBy: 'date DESC',
    );
    return rows.map(SymptomEntry.fromMap).toList();
  }

  Future<void> deleteSymptom(int id) async {
    final database = await db;
    await database.delete('symptom_entries', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  // ── Weight Entries ─────────────────────────────────────────────────────────

  Future<int> insertWeight(WeightEntry entry) async {
    final database = await db;
    final id = await database.insert('weight_entries', entry.toMap());
    _notify();
    return id;
  }

  Future<int> updateWeight(WeightEntry entry) async {
    final database = await db;
    final rows = await database.update(
      'weight_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    _notify();
    return rows;
  }

  Future<List<WeightEntry>> getWeightsBetween(
      DateTime start, DateTime end) async {
    final database = await db;
    final startKey = WeightEntry(date: start, weight: 0).dateKey;
    final endKey = WeightEntry(date: end, weight: 0).dateKey;
    final rows = await database.query(
      'weight_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'date ASC',
    );
    return rows.map(WeightEntry.fromMap).toList();
  }

  Future<List<WeightEntry>> getAllWeights() async {
    final database = await db;
    final rows = await database.query(
      'weight_entries',
      orderBy: 'date DESC',
    );
    return rows.map(WeightEntry.fromMap).toList();
  }

  Future<void> deleteWeight(int id) async {
    final database = await db;
    await database.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  Future<int> insertEvent(EventEntry entry) async {
    final database = await db;
    final id = await database.insert('events', entry.toMap());
    _notify();
    return id;
  }

  Future<int> updateEvent(EventEntry entry) async {
    final database = await db;
    final rows = await database.update(
      'events',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    _notify();
    return rows;
  }

  Future<List<EventEntry>> getEventsBetween(
      DateTime start, DateTime end) async {
    final database = await db;
    final startKey = EventEntry(
            date: start, type: EventType.other, name: '')
        .dateKey;
    final endKey =
        EventEntry(date: end, type: EventType.other, name: '').dateKey;
    final rows = await database.query(
      'events',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'date ASC',
    );
    return rows.map(EventEntry.fromMap).toList();
  }

  Future<List<EventEntry>> getAllEvents() async {
    final database = await db;
    final rows = await database.query('events', orderBy: 'date DESC');
    return rows.map(EventEntry.fromMap).toList();
  }

  Future<void> deleteEvent(int id) async {
    final database = await db;
    await database.delete('events', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  /// Removes all temperature events for a given date so a re-save always
  /// produces exactly one up-to-date high/low entry per day.
  Future<void> deleteTemperatureEventsForDate(DateTime date) async {
    final database = await db;
    final dateKey =
        EventEntry(date: date, type: EventType.temperature, name: '').dateKey;
    await database.delete(
      'events',
      where: 'date = ? AND type = ?',
      whereArgs: [dateKey, EventType.temperature.dbValue],
    );
    // No _notify() — caller will insert immediately after and notify then.
  }

  // ── Journal Entries ────────────────────────────────────────────────────────

  Future<void> upsertJournal(JournalEntry entry) async {
    final database = await db;
    final existing = await getJournalByDate(entry.date);
    if (existing != null) {
      await database.update(
        'journal_entries',
        entry.copyWith(id: existing.id).toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      await database.insert('journal_entries', entry.toMap());
    }
    _notify();
  }

  Future<JournalEntry?> getJournalByDate(DateTime date) async {
    final database = await db;
    final dateKey = JournalEntry(date: date, content: '').dateKey;
    final rows = await database.query(
      'journal_entries',
      where: 'date = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return JournalEntry.fromMap(rows.first);
  }

  Future<List<JournalEntry>> getAllJournals() async {
    final database = await db;
    final rows = await database.query(
      'journal_entries',
      orderBy: 'date DESC',
    );
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<void> deleteJournal(int id) async {
    final database = await db;
    await database.delete('journal_entries',
        where: 'id = ?', whereArgs: [id]);
    _notify();
  }
}
