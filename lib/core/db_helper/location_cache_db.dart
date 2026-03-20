import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite cache for location search results.
/// Stores every location the user has ever searched/selected,
/// along with coordinates so we can sort by proximity.
class LocationCacheDb {
  static final LocationCacheDb instance = LocationCacheDb._internal();
  static Database? _db;

  static const String _tableName = 'location_cache';

  LocationCacheDb._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final path = join(await getDatabasesPath(), 'location_cache.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        display_name TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        search_query TEXT NOT NULL,
        hit_count INTEGER NOT NULL DEFAULT 1,
        last_used INTEGER NOT NULL,
        UNIQUE(display_name)
      )
    ''');

    // Index for fast prefix search
    await db.execute(
      'CREATE INDEX idx_search_query ON $_tableName (search_query)',
    );
    await db.execute(
      'CREATE INDEX idx_display_name ON $_tableName (display_name)',
    );
  }

  /// Insert or update a cached location.
  /// If it already exists, bump hit_count and update last_used.
  Future<void> cacheLocation({
    required String displayName,
    required String searchQuery,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Try to update existing entry
    final updated = await db.rawUpdate(
      '''UPDATE $_tableName 
         SET hit_count = hit_count + 1, 
             last_used = ?,
             latitude = COALESCE(?, latitude),
             longitude = COALESCE(?, longitude)
         WHERE display_name = ?''',
      [now, latitude, longitude, displayName],
    );

    if (updated == 0) {
      // Insert new entry
      await db.insert(_tableName, {
        'display_name': displayName,
        'search_query': searchQuery.toLowerCase(),
        'latitude': latitude,
        'longitude': longitude,
        'hit_count': 1,
        'last_used': now,
      });
    }
  }

  /// Batch-cache multiple results from a single search.
  Future<void> cacheResults({
    required String searchQuery,
    required List<Map<String, dynamic>> results,
  }) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final r in results) {
      batch.rawInsert(
        '''INSERT INTO $_tableName (display_name, search_query, latitude, longitude, hit_count, last_used)
           VALUES (?, ?, ?, ?, 1, ?)
           ON CONFLICT(display_name) DO UPDATE SET
             hit_count = hit_count + 1,
             last_used = ?,
             latitude = COALESCE(excluded.latitude, latitude),
             longitude = COALESCE(excluded.longitude, longitude)''',
        [
          r['display_name'],
          searchQuery.toLowerCase(),
          r['latitude'],
          r['longitude'],
          now,
          now,
        ],
      );
    }

    await batch.commit(noResult: true);
  }

  /// Search cached locations by prefix.
  /// Returns results sorted by: hit_count DESC, last_used DESC.
  /// If userLat/userLon provided, results within 100km are prioritized.
  Future<List<Map<String, dynamic>>> searchCache({
    required String query,
    double? userLat,
    double? userLon,
    int limit = 15,
  }) async {
    final db = await database;
    final q = query.toLowerCase();

    // Search by prefix match on display_name (case-insensitive)
    final results = await db.rawQuery(
      '''SELECT display_name, latitude, longitude, hit_count, last_used
         FROM $_tableName
         WHERE LOWER(display_name) LIKE ?
         ORDER BY hit_count DESC, last_used DESC
         LIMIT ?''',
      ['$q%', limit],
    );

    if (results.isEmpty) {
      // Also try contains-match if prefix didn't find anything
      final containsResults = await db.rawQuery(
        '''SELECT display_name, latitude, longitude, hit_count, last_used
           FROM $_tableName
           WHERE LOWER(display_name) LIKE ?
           ORDER BY hit_count DESC, last_used DESC
           LIMIT ?''',
        ['%$q%', limit],
      );
      return containsResults;
    }

    // If we have user location, sort nearby first
    if (userLat != null && userLon != null) {
      final sorted = List<Map<String, dynamic>>.from(results);
      sorted.sort((a, b) {
        final aLat = a['latitude'] as double?;
        final aLon = a['longitude'] as double?;
        final bLat = b['latitude'] as double?;
        final bLon = b['longitude'] as double?;

        // Items with coords go first, sorted by rough distance
        if (aLat != null && bLat != null) {
          final aDist = _roughDistance(userLat, userLon, aLat, aLon!);
          final bDist = _roughDistance(userLat, userLon, bLat, bLon!);
          // Weight: nearby + frequently used
          final aScore = aDist - (a['hit_count'] as int) * 10;
          final bScore = bDist - (b['hit_count'] as int) * 10;
          return aScore.compareTo(bScore);
        }
        if (aLat != null) return -1;
        if (bLat != null) return 1;
        // Both without coords: sort by hit_count
        return (b['hit_count'] as int).compareTo(a['hit_count'] as int);
      });
      return sorted;
    }

    return results;
  }

  /// Rough distance in km (no trig — fast approximation).
  double _roughDistance(double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat1 - lat2).abs() * 111.0;
    final dLon = (lon1 - lon2).abs() * 111.0 * 0.7; // rough cos correction
    return dLat + dLon;
  }

  /// Get total cached location count (for stats).
  Future<int> get count async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM $_tableName');
    return result.first['c'] as int;
  }
}
