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
      version: 5,
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
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN alert_sound TEXT NOT NULL DEFAULT "alarm"',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN alert_sound_name TEXT NOT NULL DEFAULT "Default Alarm"',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN is_custom_sound INTEGER NOT NULL DEFAULT 0 CHECK (is_custom_sound IN (0,1))',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN custom_sound_path TEXT',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN loop_alarm INTEGER NOT NULL DEFAULT 1 CHECK (loop_alarm IN (0,1))',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN show_waves INTEGER NOT NULL DEFAULT 1 CHECK (show_waves IN (0,1))',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN enable_simulation INTEGER NOT NULL DEFAULT 0 CHECK (enable_simulation IN (0,1))',
      );
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
        accent_color INTEGER NOT NULL DEFAULT 4293212469,
        alert_sound TEXT NOT NULL DEFAULT 'alarm',
        alert_sound_name TEXT NOT NULL DEFAULT 'Default Alarm',
        is_custom_sound INTEGER NOT NULL DEFAULT 0 CHECK (is_custom_sound IN (0,1)),
        custom_sound_path TEXT,
        loop_alarm INTEGER NOT NULL DEFAULT 1 CHECK (loop_alarm IN (0,1)),
        show_waves INTEGER NOT NULL DEFAULT 1 CHECK (show_waves IN (0,1)),
        enable_simulation INTEGER NOT NULL DEFAULT 0 CHECK (enable_simulation IN (0,1))
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
      alertSound: row['alert_sound'] as String? ?? 'alarm',
      alertSoundName: row['alert_sound_name'] as String? ?? 'Default Alarm',
      isCustomSound: row['is_custom_sound'] == 1,
      customSoundPath: row['custom_sound_path'] as String?,
      loopAlarm: row['loop_alarm'] == 1,
      showWaves: row['show_waves'] == 1,
      enableSimulation: row['enable_simulation'] == 1,
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
      'alert_sound': status.alertSound,
      'alert_sound_name': status.alertSoundName,
      'is_custom_sound': status.isCustomSound ? 1 : 0,
      'custom_sound_path': status.customSoundPath,
      'loop_alarm': status.loopAlarm ? 1 : 0,
      'show_waves': status.showWaves ? 1 : 0,
      'enable_simulation': status.enableSimulation ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
