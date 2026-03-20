import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:locami/core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class MapCacheManager {
  MapCacheManager._();
  static final MapCacheManager instance = MapCacheManager._();

  FileCacheStore? _cacheStore;
  Dio? _dio;
  
  FileCacheStore get cacheStore {
    if (_cacheStore == null) {
      throw Exception('MapCacheManager not initialized. Call init() first.');
    }
    return _cacheStore!;
  }

  Future<void> init() async {
    if (_cacheStore != null) return;
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/map_cache';
    _cacheStore = FileCacheStore(path);
    
    _dio = Dio()
      ..interceptors.add(
        DioCacheInterceptor(
          options: CacheOptions(
            store: _cacheStore,
            policy: CachePolicy.request,
            hitCacheOnErrorExcept: [401, 403],
            maxStale: const Duration(days: 30),
            priority: CachePriority.high,
          ),
        ),
      );
  }

  /// Calculates the tile coordinates for a given latitude and longitude.
  math.Point<int> _latLngToTile(double lat, double lon, int zoom) {
    final latRad = lat * math.pi / 180.0;
    final n = math.pow(2.0, zoom).toDouble();
    final x = ((lon + 180.0) / 360.0 * n).floor();
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
    return math.Point<int>(x, y);
  }

  /// Preloads map tiles in an approx 10km grid for a given location, caching them directly.
  Future<void> preloadSurroundingMap(double lat, double lon, {bool isDark = true, bool isSatellite = false}) async {
    if (_dio == null) return;
    
    // Using zoom 14 which gives decent detail for offline use
    const int zoom = 14; 
    
    // Zoom 14 tile represents approx 2.5km length depending on latitude.
    // So 10km radius means ~4 tiles each direction.
    const int tileRadius = 4;
    
    final centerTile = _latLngToTile(lat, lon, zoom);
    
    final String urlTemplate = isSatellite 
        ? ApiConstants.arcGisSatelliteUrl 
        : (isDark ? ApiConstants.cartoDbDarkUrl : ApiConstants.cartoDbLightUrl);

    final subdomains = ['a', 'b', 'c', 'd'];
    final futures = <Future>[];

    for (int dx = -tileRadius; dx <= tileRadius; dx++) {
      for (int dy = -tileRadius; dy <= tileRadius; dy++) {
        final x = centerTile.x + dx;
        final y = centerTile.y + dy;
        
        final subdomain = subdomains[(x + y) % subdomains.length];
        String url = urlTemplate
            .replaceAll('{s}', subdomain)
            .replaceAll('{z}', zoom.toString())
            .replaceAll('{x}', x.toString())
            .replaceAll('{y}', y.toString())
            .replaceAll('{r}', '@2x');
        
        // Use generic headers to mock typical browser/OS requests
        futures.add(
          _fetchTileSafely(url)
        );
      }
    }
    
    // Batch download tiles in chunks of 10 to not overwhelm connection
    for (int i = 0; i < futures.length; i += 10) {
      final end = (i + 10 < futures.length) ? i + 10 : futures.length;
      await Future.wait(futures.sublist(i, end));
    }
    
    debugPrint('[MapCacheManager] Finished preloading ${futures.length} tiles.');
  }
  
  Future<void> _fetchTileSafely(String url) async {
    try {
      await _dio!.get(
        url,
        options: Options(headers: {'User-Agent': 'com.example.locami'}),
      );
    } catch (e) {
      // It will just skip invalid tiles
    }
  }
}
