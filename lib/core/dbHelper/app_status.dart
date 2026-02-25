import 'package:locami/core/model/appstatus_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppStatusDbHelper {
  static final AppStatusDbHelper instance = AppStatusDbHelper._internal();
  static Database? _db;

  final String tableName = 'app_status';

  AppStatusDbHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final path = join(await getDatabasesPath(), 'app_status.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN accent_color INTEGER NOT NULL DEFAULT 4293212469',
      ); // 0xFFE53935
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_first_time_user INTEGER NOT NULL DEFAULT 1 CHECK (is_first_time_user IN (0,1)),
        is_logged_in INTEGER NOT NULL DEFAULT 0 CHECK (is_logged_in IN (0,1)),
        is_trip_started INTEGER NOT NULL DEFAULT 0 CHECK (is_trip_started IN (0,1)),
        is_trip_ended INTEGER NOT NULL DEFAULT 0 CHECK (is_trip_ended IN (0,1)),
        is_internet_on INTEGER NOT NULL DEFAULT 0 CHECK (is_internet_on IN (0,1)),
        is_gps_on INTEGER NOT NULL DEFAULT 0 CHECK (is_gps_on IN (0,1)),
        theme TEXT NOT NULL DEFAULT 'system',
        accent_color INTEGER NOT NULL DEFAULT 4293212469
      )
    ''');

    await db.insert(tableName, {'id': 1});
  }

  Future<AppStatus> getStatus() async {
    final db = await database;
    final result = await db.query(tableName, where: 'id = ?', whereArgs: [1]);

    if (result.isEmpty) return const AppStatus();

    final row = result.first;
    return AppStatus(
      isFirstTimeUser: row['is_first_time_user'] == 1,
      isLoggedIn: row['is_logged_in'] == 1,
      isTripStarted: row['is_trip_started'] == 1,
      isTripEnded: row['is_trip_ended'] == 1,
      isInternetOn: row['is_internet_on'] == 1,
      isGpsOn: row['is_gps_on'] == 1,
      theme: row['theme'] as String,
      accentColor: row['accent_color'] as int,
    );
  }

  Future<void> saveStatus(AppStatus status) async {
    final db = await database;

    await db.insert(tableName, {
      'id': 1,
      'is_first_time_user': status.isFirstTimeUser ? 1 : 0,
      'is_logged_in': status.isLoggedIn ? 1 : 0,
      'is_trip_started': status.isTripStarted ? 1 : 0,
      'is_trip_ended': status.isTripEnded ? 1 : 0,
      'is_internet_on': status.isInternetOn ? 1 : 0,
      'is_gps_on': status.isGpsOn ? 1 : 0,
      'theme': status.theme,
      'accent_color': status.accentColor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
