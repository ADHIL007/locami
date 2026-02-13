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
    return openDatabase(path, version: 1, onCreate: _onCreate);
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
        acceleration REAL
      )
    ''');
  }

  Future<int> insertTripDetail(TripDetailsModel detail) async {
    final db = await database;
    try {
      return await db.insert(tableName, detail.toJson());
    } catch (e) {
      // If column missing (dev mode migration), try to add it
      if (e.toString().contains('no such column: acceleration')) {
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN acceleration REAL DEFAULT 0.0',
        );
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
