import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'package:locami/core/constants/api_constants.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:http/http.dart' as http;

class MapCacheManager {
  MapCacheManager._();
  static final MapCacheManager instance = MapCacheManager._();

  static const int _maxStoreLength = 50000;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isPreloading = false;
  bool get isPreloading => _isPreloading;
  DateTime? _lastPreloadTime;

  late final http.Client _httpClient;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  final Map<String, FMTCTileProvider> _providers = {};

  String _getStoreName(bool isRoute, bool isDark, bool isSatellite) {
    final quality = ThemeProvider.instance.mapQuality;
    final suffix = quality == 'high' ? '_hq' : '';
    
    if (isRoute) {
      if (isSatellite) return 'routeSat$suffix';
      return isDark ? 'routeDark$suffix' : 'routeLight$suffix';
    } else {
      if (isSatellite) return 'mainSat$suffix';
      return isDark ? 'mainDark$suffix' : 'mainLight$suffix';
    }
  }

  Future<void> _initStore(String name) async {
    final store = FMTCStore(name);
    if (!await store.manage.ready) {
      await store.manage.create(maxLength: _maxStoreLength);
    } else {
      await store.manage.setMaxLength(_maxStoreLength);
    }
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      await FMTCObjectBoxBackend().initialise();

      final storeNames = [
        'mainLight',
        'mainDark',
        'mainSat',
        'routeLight',
        'routeDark',
        'routeSat',
        'mainLight_hq',
        'mainDark_hq',
        'mainSat_hq',
        'routeLight_hq',
        'routeDark_hq',
        'routeSat_hq',
      ];
      
      for (final name in storeNames) {
        await _initStore(name);
      }

      _httpClient = http.Client();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _notificationsPlugin.initialize(
        const InitializationSettings(android: androidInit),
      );

      _initialized = true;
      debugPrint('[MapCacheManager] FMTC initialized successfully with separate theme stores');
    } catch (e) {
      debugPrint('[MapCacheManager] FMTC init error: $e');

      rethrow;
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('MapCacheManager not initialized. Call init() first.');
    }
  }

  FMTCTileProvider getProvider({bool isDark = false, bool isSatellite = false}) {
    _ensureInitialized();
    final quality = ThemeProvider.instance.mapQuality;
    final name = _getStoreName(false, isDark, isSatellite);
    final key = 'main_${name}_$quality';
    
    if (!_providers.containsKey(key)) {
      _providers[key] = FMTCTileProvider(
        stores: {name: BrowseStoreStrategy.readUpdateCreate},
        loadingStrategy: BrowseLoadingStrategy.cacheFirst,
        useOtherStoresAsFallbackOnly: false,
        recordHitsAndMisses: false,
        httpClient: _httpClient,
        headers: {'User-Agent': 'com.example.locami'},
      );
    }
    return _providers[key]!;
  }

  FMTCTileProvider getRouteProvider({bool isDark = false, bool isSatellite = false}) {
    _ensureInitialized();
    final quality = ThemeProvider.instance.mapQuality;
    final routeName = _getStoreName(true, isDark, isSatellite);
    final mainName = _getStoreName(false, isDark, isSatellite);
    final key = 'route_${routeName}_$quality';
    
    if (!_providers.containsKey(key)) {
      _providers[key] = FMTCTileProvider(
        stores: {
          routeName: BrowseStoreStrategy.readUpdateCreate,
          mainName: BrowseStoreStrategy.read,
        },
        loadingStrategy: BrowseLoadingStrategy.cacheFirst,
        useOtherStoresAsFallbackOnly: false,
        recordHitsAndMisses: false,
        httpClient: _httpClient,
        headers: {'User-Agent': 'com.example.locami'},
      );
    }
    return _providers[key]!;
  }

  FMTCTileProvider getOfflineProvider({bool isDark = false, bool isSatellite = false}) {
    _ensureInitialized();
    final quality = ThemeProvider.instance.mapQuality;
    final name = _getStoreName(false, isDark, isSatellite);
    final key = 'offline_${name}_$quality';
    
    if (!_providers.containsKey(key)) {
      _providers[key] = FMTCTileProvider(
        stores: {name: BrowseStoreStrategy.read},
        otherStoresStrategy: BrowseStoreStrategy.read,
        loadingStrategy: BrowseLoadingStrategy.cacheOnly,
        useOtherStoresAsFallbackOnly: true,
        recordHitsAndMisses: false,
      );
    }
    return _providers[key]!;
  }

  Future<void> preloadSurroundingMap(
    double lat,
    double lon, {
    bool isDark = true,
    bool isSatellite = false,
  }) async {
    if (!_initialized || _isPreloading) return;

    if (_lastPreloadTime != null &&
        DateTime.now().difference(_lastPreloadTime!).inSeconds < 15) {
      return;
    }

    _isPreloading = true;
    _lastPreloadTime = DateTime.now();

    try {
      String urlTemplate;
      if (isSatellite) {
        urlTemplate = ApiConstants.esriSatelliteUrl;
      } else if (isDark) {
        urlTemplate = ApiConstants.cartoDbDarkUrl;
      } else {
        urlTemplate = ApiConstants.cartoDbLightUrl;
      }

      final region = CircleRegion(LatLng(lat, lon), 5.0);

      final downloadable = region.toDownloadable(
        minZoom: 12,
        maxZoom: 15,
        options: fm.TileLayer(
          urlTemplate: urlTemplate,
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: ThemeProvider.instance.mapQuality == 'high',
          userAgentPackageName: 'com.example.locami',
        ),
      );

      final storeName = _getStoreName(false, isDark, isSatellite);

      final (:tileEvents, :downloadProgress) = FMTCStore(storeName)
        .download
        .startForeground(
        region: downloadable,
        parallelThreads: 6,
        maxBufferLength: 100,
        skipExistingTiles: true,
        skipSeaTiles: true,
        rateLimit: 50,
        disableRecovery: true,
        instanceId: 'surrounding_$storeName',
      );

      final subscription = tileEvents.listen((event) {
        // debugPrint('[MapCacheManager] [$storeName - 6 Thread Activity] $event');
      }, onError: (e) {
        debugPrint('[MapCacheManager] [$storeName] TileEvent Error: $e');
      });

      int downloaded = 0;
      await for (final progress in downloadProgress) {
        downloaded = progress.attemptedTilesCount;
        debugPrint('[MapCacheManager] [$storeName Progress] ${progress.percentageProgress.toStringAsFixed(2)}% | Tiles: ${progress.attemptedTilesCount}');
        if (progress.percentageProgress >= 100) break;
      }
      
      await subscription.cancel();

      debugPrint('[MapCacheManager] Preloaded $downloaded surrounding tiles ($storeName)');
    } catch (e) {
      debugPrint('[MapCacheManager] Preload surrounding error: $e');
    } finally {
      _isPreloading = false;
    }
  }

  Future<void> preloadRouteTiles(
    List<dynamic> points, {
    bool isDark = true,
    bool isSatellite = false,
  }) async {
    if (!_initialized || points.isEmpty) return;
    if (!ThemeProvider.instance.enableBackgroundMapDownload) return;

    try {
      final routePoints = <LatLng>[];
      for (int i = 0; i < points.length; i += 5) {
         final p = points[i];
         routePoints.add(LatLng(p.latitude, p.longitude));
      }

      if (points.isNotEmpty) {
        final last = points.last;
        final lastLatLng = LatLng(last.latitude, last.longitude);
        if (routePoints.isEmpty || routePoints.last != lastLatLng) {
          routePoints.add(lastLatLng);
        }
      }

      if (routePoints.length < 2) return;

      final region = LineRegion(routePoints, 0.5);

      String urlTemplate;
      if (isSatellite) {
        urlTemplate = ApiConstants.esriSatelliteUrl;
      } else if (isDark) {
        urlTemplate = ApiConstants.cartoDbDarkUrl;
      } else {
        urlTemplate = ApiConstants.cartoDbLightUrl;
      }

      final downloadable = region.toDownloadable(
        minZoom: 13,
        maxZoom: 16,
        options: fm.TileLayer(
          urlTemplate: urlTemplate,
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: ThemeProvider.instance.mapQuality == 'high',
          userAgentPackageName: 'com.example.locami',
        ),
      );

      final routeStoreName = _getStoreName(true, isDark, isSatellite);

      final tileCount = await FMTCStore(routeStoreName).download.countTiles(downloadable);

      debugPrint('[MapCacheManager] Route caching: $tileCount tiles in $routeStoreName');

      const int notificationId = 999;
      await _notificationsPlugin.show(
        notificationId,
        'Map Preparation',
        'Downloading $tileCount map tiles for your route...',
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

      final (:tileEvents, :downloadProgress) = FMTCStore(routeStoreName)
        .download
        .startForeground(
        region: downloadable,
        parallelThreads: 6,
        maxBufferLength: 200,
        skipExistingTiles: true,
        skipSeaTiles: true,
        rateLimit: 80,
        disableRecovery: true,
        instanceId: 'route_$routeStoreName',
      );

      final subscription = tileEvents.listen((event) {
        // debugPrint('[MapCacheManager] [$routeStoreName - 6 Thread Activity] $event');
      }, onError: (e) {
        debugPrint('[MapCacheManager] [$routeStoreName] TileEvent Error: $e');
      });

      await for (final progress in downloadProgress) {
        final pct = progress.percentageProgress.toInt().clamp(0, 100);
        debugPrint('[MapCacheManager] [$routeStoreName Progress] $pct% | Tiles attempted: ${progress.attemptedTilesCount} / $tileCount');
        await _notificationsPlugin.show(
          notificationId,
          'Map Preparation',
          'Cached ${progress.attemptedTilesCount} of $tileCount tiles...',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'map_download_channel',
              'Map Downloads',
              importance: Importance.low,
              priority: Priority.low,
              onlyAlertOnce: true,
              showProgress: true,
              maxProgress: 100,
              progress: pct,
            ),
          ),
        );
        if (progress.percentageProgress >= 100) break;
      }
      
      await subscription.cancel();

      await Future.delayed(const Duration(seconds: 2));
      await _notificationsPlugin.cancel(notificationId);
      debugPrint('[MapCacheManager] Finished preloading route tiles for $routeStoreName.');
    } catch (e) {
      debugPrint('[MapCacheManager] Route preload error: $e');

      await _notificationsPlugin.cancel(999);
    }
  }

  Future<void> preloadWorldMap({
    bool isDark = true,
    bool isSatellite = false,
  }) async {
    if (!_initialized) return;

    try {
      final region = RectangleRegion(
        fm.LatLngBounds(const LatLng(-60, -180), const LatLng(80, 180)),
      );

      String urlTemplate;
      if (isSatellite) {
        urlTemplate = ApiConstants.esriSatelliteUrl;
      } else if (isDark) {
        urlTemplate = ApiConstants.cartoDbDarkUrl;
      } else {
        urlTemplate = ApiConstants.cartoDbLightUrl;
      }

      final downloadable = region.toDownloadable(
        minZoom: 0,
        maxZoom: 3,
        options: fm.TileLayer(
          urlTemplate: urlTemplate,
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: ThemeProvider.instance.mapQuality == 'high',
          userAgentPackageName: 'com.example.locami',
        ),
      );

      final storeName = _getStoreName(false, isDark, isSatellite);

      final (:tileEvents, :downloadProgress) = FMTCStore(storeName)
        .download
        .startForeground(
        region: downloadable,
        parallelThreads: 6,
        maxBufferLength: 100,
        skipExistingTiles: true,
        skipSeaTiles: false,
        rateLimit: 100,
        disableRecovery: true,
        instanceId: 'world_$storeName',
      );

      final subscription = tileEvents.listen((event) {
        // debugPrint('[MapCacheManager] [$storeName - 6 Thread Activity] $event');
      }, onError: (e) {
        debugPrint('[MapCacheManager] [$storeName] TileEvent Error: $e');
      });

      await for (final progress in downloadProgress) {
        debugPrint('[MapCacheManager] [$storeName Progress] ${progress.percentageProgress.toStringAsFixed(2)}% | Tiles: ${progress.attemptedTilesCount}');
        if (progress.percentageProgress >= 100) break;
      }
      
      await subscription.cancel();

      debugPrint('[MapCacheManager] World overview tiles cached for $storeName');
    } catch (e) {
      debugPrint('[MapCacheManager] World preload error: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    if (!_initialized) return {};

    try {
      final storeNames = [
        'mainLight', 'mainDark', 'mainSat',
        'routeLight', 'routeDark', 'routeSat'
      ];
      
      double totalSize = 0;
      int totalTiles = 0;
      
      for (final name in storeNames) {
         final stats = FMTCStore(name).stats;
         totalSize += await stats.size;
         totalTiles += await stats.length;
      }

      return {
        'totalTiles': totalTiles,
        'totalSizeKB': totalSize,
      };
    } catch (e) {
      debugPrint('[MapCacheManager] Stats error: $e');
      return {};
    }
  }

  Future<void> evictOldTiles({
    Duration maxAge = const Duration(days: 30),
  }) async {
    if (!_initialized) return;

    try {
      final expiry = DateTime.now().subtract(maxAge);
      final storeNames = [
        'mainLight', 'mainDark', 'mainSat',
        'routeLight', 'routeDark', 'routeSat'
      ];
      
      for (final name in storeNames) {
        await FMTCStore(name).manage.removeTilesOlderThan(expiry: expiry);
      }
      debugPrint('[MapCacheManager] Evicted tiles older than $maxAge');
    } catch (e) {
      debugPrint('[MapCacheManager] Eviction error: $e');
    }
  }

  Future<void> resetAllCaches() async {
    if (!_initialized) return;

    try {
      final storeNames = [
        'mainLight', 'mainDark', 'mainSat',
        'routeLight', 'routeDark', 'routeSat'
      ];
      for (final name in storeNames) {
        await FMTCStore(name).manage.reset();
      }
      debugPrint('[MapCacheManager] All caches reset');
    } catch (e) {
      debugPrint('[MapCacheManager] Reset error: $e');
    }
  }

  Future<void> cancelDownload() async {
    try {
      final storeNames = [
        'mainLight', 'mainDark', 'mainSat',
        'routeLight', 'routeDark', 'routeSat'
      ];
      for (final name in storeNames) {
        await FMTCStore(name).download.cancel();
      }
    } catch (_) {}
  }
}

