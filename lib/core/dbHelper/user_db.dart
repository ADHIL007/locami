import 'package:locami/core/model/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserDbHelper {
  static final UserDbHelper instance = UserDbHelper._internal();
  static Database? _db;

  final String tableName = 'user_model';

  UserDbHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final path = join(await getDatabasesPath(), 'user_model.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        username TEXT NOT NULL DEFAULT '',
        country TEXT NOT NULL DEFAULT '',
        is_travel_started INTEGER NOT NULL DEFAULT 0 CHECK (is_travel_started IN (0,1)),
        is_travel_ended INTEGER NOT NULL DEFAULT 0 CHECK (is_travel_ended IN (0,1)),
        start_time TEXT,
        end_time TEXT,
        total_travel INTEGER,
        from_street TEXT,
        destination_street TEXT,
        destination_latitude REAL,
        destination_longitude REAL,
        travel_mode TEXT
      )
    ''');

    await db.insert(tableName, {'id': 1});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN destination_latitude REAL',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN destination_longitude REAL',
      );
    }
  }

  Future<UserModel> getUser() async {
    final db = await database;
    final result = await db.query(tableName, where: 'id = ?', whereArgs: [1]);

    if (result.isEmpty) return const UserModel();

    final row = result.first;
    return UserModel(
      username: row['username'] as String? ?? '',
      country: row['country'] as String? ?? '',
      isTravelStarted: (row['is_travel_started'] as int? ?? 0) == 1,
      isTravelEnded: (row['is_travel_ended'] as int? ?? 0) == 1,
      startTime:
          row['start_time'] != null
              ? DateTime.parse(row['start_time'] as String)
              : null,
      endTime:
          row['end_time'] != null
              ? DateTime.parse(row['end_time'] as String)
              : null,
      totalTravel:
          row['total_travel'] != null
              ? Duration(seconds: row['total_travel'] as int)
              : null,
      fromStreet: row['from_street'] as String?,
      destinationStreet: row['destination_street'] as String?,
      destinationLatitude: row['destination_latitude'] as double?,
      destinationLongitude: row['destination_longitude'] as double?,
      travelMode: row['travel_mode'] as String?,
    );
  }

  Future<void> saveUser(UserModel user) async {
    final db = await database;

    await db.insert(tableName, {
      'id': 1,
      'username': user.username,
      'country': user.country,
      'is_travel_started': user.isTravelStarted ? 1 : 0,
      'is_travel_ended': user.isTravelEnded ? 1 : 0,
      'start_time': user.startTime?.toIso8601String(),
      'end_time': user.endTime?.toIso8601String(),
      'total_travel': user.totalTravel?.inSeconds,
      'from_street': user.fromStreet,
      'destination_street': user.destinationStreet,
      'destination_latitude': user.destinationLatitude,
      'destination_longitude': user.destinationLongitude,
      'travel_mode': user.travelMode,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearUser() async {
    final db = await database;
    await db.delete(tableName);
    await db.insert(tableName, {'id': 1});
  }
}
