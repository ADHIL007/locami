import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database for user-saved/tagged locations (Home, Work, Gym, etc.)
class SavedLocationDb {
  static final SavedLocationDb instance = SavedLocationDb._internal();
  static Database? _db;
  static const String _tableName = 'saved_locations';

  SavedLocationDb._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final path = join(await getDatabasesPath(), 'saved_locations.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        display_name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        icon TEXT NOT NULL DEFAULT 'place',
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_label ON $_tableName (label)');
  }

  /// Save a new tagged location.
  Future<int> saveLocation({
    required String label,
    required String displayName,
    required double latitude,
    required double longitude,
    String icon = 'place',
  }) async {
    final db = await database;
    return db.insert(_tableName, {
      'label': label,
      'display_name': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'icon': icon,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Update an existing saved location.
  Future<void> updateLocation(int id, {String? label, String? icon}) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (label != null) updates['label'] = label;
    if (icon != null) updates['icon'] = icon;
    if (updates.isNotEmpty) {
      await db.update(_tableName, updates, where: 'id = ?', whereArgs: [id]);
    }
  }

  /// Delete a saved location.
  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Get all saved locations.
  Future<List<SavedLocation>> getAll() async {
    final db = await database;
    final results = await db.query(_tableName, orderBy: 'created_at DESC');
    return results.map((r) => SavedLocation.fromMap(r)).toList();
  }

  /// Search saved locations by label or display_name.
  Future<List<SavedLocation>> search(String query) async {
    final db = await database;
    final q = query.toLowerCase();
    final results = await db.rawQuery(
      '''SELECT * FROM $_tableName
         WHERE LOWER(label) LIKE ? OR LOWER(display_name) LIKE ?
         ORDER BY 
           CASE WHEN LOWER(label) LIKE ? THEN 0 ELSE 1 END,
           created_at DESC''',
      ['%$q%', '%$q%', '$q%'],
    );
    return results.map((r) => SavedLocation.fromMap(r)).toList();
  }

  /// Check if a location with the same lat/lng already exists.
  Future<SavedLocation?> findByCoordinates(double lat, double lon) async {
    final db = await database;
    final results = await db.rawQuery(
      '''SELECT * FROM $_tableName
         WHERE ABS(latitude - ?) < 0.0001 AND ABS(longitude - ?) < 0.0001
         LIMIT 1''',
      [lat, lon],
    );
    if (results.isEmpty) return null;
    return SavedLocation.fromMap(results.first);
  }

  /// Clear all saved locations.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }
}

/// Model for a saved/tagged location.
class SavedLocation {
  final int id;
  final String label;
  final String displayName;
  final double latitude;
  final double longitude;
  final String icon;
  final DateTime createdAt;

  const SavedLocation({
    required this.id,
    required this.label,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.icon,
    required this.createdAt,
  });

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] as int,
      label: map['label'] as String,
      displayName: map['display_name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      icon: map['icon'] as String? ?? 'place',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Get the appropriate icon data based on icon string.
  static Map<String, IconData> iconOptions() {
    return {
      'home': SolarIconsOutline.home,
      'work': SolarIconsOutline.caseMinimalistic,
      'gym': SolarIconsOutline.dumbbell,
      'school': SolarIconsOutline.library,
      'hospital': SolarIconsOutline.hospital,
      'restaurant': SolarIconsOutline.cupFirst,
      'shopping': SolarIconsOutline.cart,
      'airport': SolarIconsOutline.plain,
      'temple': SolarIconsOutline.buildings,
      'park': SolarIconsOutline.mapPoint,
      'place': SolarIconsOutline.mapPoint,
      'heart': SolarIconsOutline.heart,
      'star': SolarIconsOutline.star,
      'flag': SolarIconsOutline.flag,
      'bus': SolarIconsOutline.bus,
      'train': SolarIconsOutline.tram,
    };
  }

  IconData get iconData {
    return iconOptions()[icon] ?? SolarIconsOutline.mapPoint;
  }
}
