import 'package:locami/core/model/trip_details_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TripDbHelper {
  static final TripDbHelper instance = TripDbHelper._internal();
  static Database? _db;

  final String tableName = 'trip_details';
  final String routeCacheTable = 'cached_routes';

  TripDbHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final path = join(await getDatabasesPath(), 'trip_details.db');
    final db = await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await db.rawQuery('PRAGMA journal_mode=WAL');
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        speed REAL,
        heading REAL,
        accuracy REAL,
        altitude REAL,
        distance_traveled REAL,
        country TEXT,
        street TEXT,
        acceleration REAL,
        destination TEXT,
        remaining_distance REAL,
        total_distance REAL,
        total_duration REAL,
        destination_latitude REAL,
        destination_longitude REAL,
        trip_id TEXT,
        alert_distance REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE $routeCacheTable (
        id TEXT PRIMARY KEY,
        points TEXT,
        distance REAL,
        duration REAL,
        timestamp TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN alert_distance REAL');
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE $routeCacheTable (
            id TEXT PRIMARY KEY,
            points TEXT,
            distance REAL,
            duration REAL,
            timestamp TEXT
          )
        ''');
      } catch (_) {}
    }
  }

  Future<int> insertTripDetail(TripDetailsModel detail) async {
    final db = await database;
    try {
      return await db.insert(tableName, detail.toJson());
    } catch (e) {
      // Re-run migration auto-fixes if needed
      rethrow;
    }
  }

  // --- Route Cache Methods ---
  
  Future<void> saveCachedRoute(String id, String pointsJson, double distance, double duration) async {
    final db = await database;
    await db.insert(
      routeCacheTable,
      {
        'id': id,
        'points': pointsJson,
        'distance': distance,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedRoute(String id) async {
    final db = await database;
    final results = await db.query(
      routeCacheTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) return results.first;
    return null;
  }

  // --- Existing Methods ---

  Future<TripDetailsModel?> getLastPointForTrip(String? tripId) async {
    final db = await database;
    final whereClause = tripId != null ? 'trip_id = ?' : '1=1';
    final whereArgs = tripId != null ? [tripId] : [];
    
    final result = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return TripDetailsModel.fromJson(result.first);
    }
    return null;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableName);
    await db.delete(routeCacheTable);
  }
}
