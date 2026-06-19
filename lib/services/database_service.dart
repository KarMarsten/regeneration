import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/symptom_entry.dart';
import '../models/weight_entry.dart';
import '../models/event_entry.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'regeneration.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
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
        zipcode TEXT,
        notes TEXT
      )
    ''');
  }

  // ── Symptom Entries ────────────────────────────────────────────────────────

  Future<int> upsertSymptom(SymptomEntry entry) async {
    final database = await db;
    final existing = await getSymptomByDate(entry.date);
    if (existing != null) {
      await database.update(
        'symptom_entries',
        entry.copyWith(id: existing.id).toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    }
    return database.insert('symptom_entries', entry.toMap());
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

  Future<void> deleteSymptom(int id) async {
    final database = await db;
    await database.delete('symptom_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ── Weight Entries ─────────────────────────────────────────────────────────

  Future<int> insertWeight(WeightEntry entry) async {
    final database = await db;
    return database.insert('weight_entries', entry.toMap());
  }

  Future<int> updateWeight(WeightEntry entry) async {
    final database = await db;
    return database.update(
      'weight_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
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
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  Future<int> insertEvent(EventEntry entry) async {
    final database = await db;
    return database.insert('events', entry.toMap());
  }

  Future<int> updateEvent(EventEntry entry) async {
    final database = await db;
    return database.update(
      'events',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
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
  }
}
