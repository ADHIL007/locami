import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:locami/core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:locami/theme/theme_provider.dart';

class MapCacheManager {
  MapCacheManager._();
  static final MapCacheManager instance = MapCacheManager._();

  FileCacheStore? _cacheStore;
  Dio? _dio;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  FileCacheStore get cacheStore {
    if (_cacheStore == null) {
      throw Exception('MapCacheManager not initialized. Call init() first.');
    }
    return _cacheStore!;
  }

  Future<void> init() async {
    if (_cacheStore != null) return;
    
    // Initialize notifications for background progress
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notificationsPlugin.initialize(const InitializationSettings(android: androidInit));

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/map_cache_v2'; // Changed from map_cache to avoid old corrupted strings
    _cacheStore = FileCacheStore(path);
    
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    )
      ..interceptors.add(
        DioCacheInterceptor(
          options: CacheOptions(
            store: _cacheStore,
            policy: CachePolicy.request,
            hitCacheOnErrorExcept: [401, 403, 408],
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
    if (!ThemeProvider.instance.enableBackgroundMapDownload) return;

    const int zoom = 14; 
    const int tileRadius = 4;
    final centerTile = _latLngToTile(lat, lon, zoom);
    
    String urlTemplate = ApiConstants.cartoDbLightUrl;
    bool isArcGis = false;
    
    if (isSatellite) {
      urlTemplate = ApiConstants.arcGisSatelliteUrl;
      isArcGis = true;
    } else if (isDark) {
      urlTemplate = ApiConstants.cartoDbDarkUrl;
    }

    final subdomains = ['a', 'b', 'c', 'd'];
    final futures = <Future>[];

    for (int dx = -tileRadius; dx <= tileRadius; dx++) {
      for (int dy = -tileRadius; dy <= tileRadius; dy++) {
        final x = centerTile.x + dx;
        final y = centerTile.y + dy;
        final subdomain = subdomains[(x + y) % subdomains.length];
        
        String url;
        if (isArcGis) {
          // ArcGIS uses {z}/{y}/{x} pattern
          url = urlTemplate
              .replaceAll('{z}', zoom.toString())
              .replaceAll('{x}', x.toString())
              .replaceAll('{y}', y.toString());
        } else {
          // CartoDB uses {s}.basemaps.cartocdn.com/.../{z}/{x}/{y}{r}.png
          url = urlTemplate
              .replaceAll('{s}', subdomain)
              .replaceAll('{z}', zoom.toString())
              .replaceAll('{x}', x.toString())
              .replaceAll('{y}', y.toString())
              .replaceAll('{r}', '@2x');
        }
        
        futures.add(_fetchTileSafely(url));
      }
    }
    
    // Batch download
    for (int i = 0; i < futures.length; i += 15) {
      final end = (i + 15 < futures.length) ? i + 15 : futures.length;
      await Future.wait(futures.sublist(i, end));
      // Yield to main thread briefly to prevent UI frame drops
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Fast preload for zoom 0-3 to ensure basic map is visible immediately.
  Future<void> preloadInitialOverview() async {
    if (_dio == null) return;
    const zooms = [0, 1, 2, 3];
    final futures = <Future>[];
    for (final zoom in zooms) {
      final n = math.pow(2.0, zoom).toInt();
      for (int x = 0; x < n; x++) {
        for (int y = 0; y < n; y++) {
          final subdomain = ['a', 'b', 'c', 'd'][(x + y) % 4];
          String url = ApiConstants.cartoDbLightUrl
              .replaceAll('{s}', subdomain)
              .replaceAll('{z}', zoom.toString())
              .replaceAll('{x}', x.toString())
              .replaceAll('{y}', y.toString())
              .replaceAll('{r}', '');
          futures.add(_fetchTileSafely(url));
        }
      }
    }
    // Zoom 0-3 is 1+4+16+64 = 85 tiles. Download in batches.
    for (int i = 0; i < futures.length; i += 25) {
      final end = (i + 25 < futures.length) ? i + 25 : futures.length;
      await Future.wait(futures.sublist(i, end));
    }
  }

  /// Continues preloading world map to deeper levels zoomed out.
  Future<void> preloadWorldMap() async {
    if (_dio == null) return;
    
    // First ensures 0-3 are ready
    await preloadInitialOverview();

    // Then background the rest without blocking much
    const zooms = [4, 5];
    final futures = <Future>[];
    for (final zoom in zooms) {
      final n = math.pow(2.0, zoom).toInt();
      for (int x = 0; x < n; x++) {
        for (int y = 0; y < n; y++) {
          final subdomain = ['a', 'b', 'c', 'd'][(x + y) % 4];
          String url = ApiConstants.cartoDbLightUrl
              .replaceAll('{s}', subdomain)
              .replaceAll('{z}', zoom.toString())
              .replaceAll('{x}', x.toString())
              .replaceAll('{y}', y.toString())
              .replaceAll('{r}', '');
          futures.add(_fetchTileSafely(url));
        }
      }
    }
    for (int i = 0; i < futures.length; i += 20) {
      final end = (i + 20 < futures.length) ? i + 20 : futures.length;
      await Future.wait(futures.sublist(i, end));
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Preloads tiles along a route polyline with progress notification.
  Future<void> preloadRouteTiles(List<dynamic> points) async {
    if (_dio == null || points.isEmpty) return;
    if (!ThemeProvider.instance.enableBackgroundMapDownload) return;
    
    final List<int> zooms = [14, 15]; 
    final Set<String> tileKeys = {};
    final futures = <Future>[];

    for (int i = 0; i < points.length; i += 5) {
      final p = points[i];
      final double lat = p.latitude;
      final double lon = p.longitude;

      for (final zoom in zooms) {
        final tile = _latLngToTile(lat, lon, zoom);
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            final x = tile.x + dx;
            final y = tile.y + dy;
            final key = '$zoom/$x/$y';
            
            if (!tileKeys.contains(key)) {
              tileKeys.add(key);
              final subdomain = ['a', 'b', 'c', 'd'][(x + y) % 4];
              String url = ApiConstants.cartoDbLightUrl
                  .replaceAll('{s}', subdomain)
                  .replaceAll('{z}', zoom.toString())
                  .replaceAll('{x}', x.toString())
                  .replaceAll('{y}', y.toString())
                  .replaceAll('{r}', '');
              futures.add(_fetchTileSafely(url));
            }
          }
        }
      }
    }

    if (futures.isEmpty) return;

    // Show initial notification
    const int notificationId = 999;
    await _notificationsPlugin.show(
      notificationId,
      'Map Preparation',
      'Downloading map tiles for your route...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'map_download_channel',
          'Map Downloads',
          channelDescription: 'Showing progress of offline map caching',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: 0,
        ),
      ),
    );

    // Batch download with progress updates
    final int total = futures.length;
    for (int i = 0; i < total; i += 15) {
      final end = (i + 15 < total) ? i + 15 : total;
      await Future.wait(futures.sublist(i, end));
      
      // Update notification every batch
      final progress = ((i / total) * 100).toInt();
      await _notificationsPlugin.show(
        notificationId,
        'Map Preparation',
        'Cached $i of $total tiles...',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'map_download_channel',
            'Map Downloads',
            importance: Importance.low,
            priority: Priority.low,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: 100,
            progress: progress,
          ),
        ),
      );
    }
    
    // Hide notification after a short delay
    await Future.delayed(const Duration(seconds: 2));
    await _notificationsPlugin.cancel(notificationId);
    debugPrint('[MapCacheManager] Finished preloading route tiles.');
  }
  
  Future<void> _fetchTileSafely(String url) async {
    try {
      await _dio!.get(
        url,
        options: Options(
          responseType: ResponseType.bytes, // FIX: Avoids Utf8 decoding crash for images
          headers: {'User-Agent': 'com.example.locami'},
        ),
      );
    } catch (e) {
      // Skip failed tiles
    }
  }
}
