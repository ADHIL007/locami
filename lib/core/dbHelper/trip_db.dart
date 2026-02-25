import 'package:locami/core/model/trip_details_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TripDbHelper {
  static final TripDbHelper instance = TripDbHelper._internal();
  static Database? _db;

  final String tableName = 'trip_details';

  TripDbHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final path = join(await getDatabasesPath(), 'trip_details.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
        destination_longitude REAL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN acceleration REAL DEFAULT 0.0',
        );
      } catch (e) {
        print('Error adding column acceleration: $e');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN destination TEXT');
      } catch (e) {
        print('Error adding column destination: $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN remaining_distance REAL',
        );
      } catch (e) {
        print('Error adding column remaining_distance: $e');
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN total_distance REAL',
        );
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN total_duration REAL',
        );
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN destination_latitude REAL',
        );
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN destination_longitude REAL',
        );
      } catch (e) {
        print('Error upgrading to version 5: $e');
      }
    }
  }

  Future<int> insertTripDetail(TripDetailsModel detail) async {
    final db = await database;
    try {
      return await db.insert(tableName, detail.toJson());
    } catch (e) {
      final error = e.toString();
      bool fixed = false;
      if (error.contains('acceleration')) {
        try {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN acceleration REAL DEFAULT 0.0',
          );
          fixed = true;
        } catch (_) {}
      }
      if (error.contains('destination') && !error.contains('latitude')) {
        try {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN destination TEXT',
          );
          fixed = true;
        } catch (_) {}
      }
      if (error.contains('remaining_distance')) {
        try {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN remaining_distance REAL',
          );
          fixed = true;
        } catch (_) {}
      }
      if (error.contains('total_distance')) {
        try {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN total_distance REAL',
          );
          fixed = true;
        } catch (_) {}
      }
      if (error.contains('total_duration')) {
        try {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN total_duration REAL',
          );
          fixed = true;
        } catch (_) {}
      }
      if (error.contains('destination_latitude')) {
        try {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN destination_latitude REAL',
          );
          fixed = true;
        } catch (_) {}
      }
      if (error.contains('destination_longitude')) {
        try {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN destination_longitude REAL',
          );
          fixed = true;
        } catch (_) {}
      }

      if (fixed) {
        return await db.insert(tableName, detail.toJson());
      }
      rethrow;
    }
  }

  Future<List<TripDetailsModel>> getAllTripDetails() async {
    final db = await database;
    final result = await db.query(tableName, orderBy: 'timestamp DESC');

    return result.map((json) => TripDetailsModel.fromJson(json)).toList();
  }

  // Get latest point
  Future<TripDetailsModel?> getLastPoint() async {
    final db = await database;
    final result = await db.query(
      tableName,
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
  }
}
