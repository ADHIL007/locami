import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'route_simplifier.dart';
import 'route_lod_manager.dart';
import 'polyline_decoder.dart';

/// High-performance route renderer with:
/// - Isolate-based processing
/// - Route simplification
/// - Level of Detail (LOD)
/// - Segmented rendering
/// - Progressive loading
/// - Debouncing/throttling
class OptimizedRouteRenderer {
  final Function(List<LatLng>) _onRouteUpdated;
  final Function()? _onRenderComplete;
  
  // LOD Manager
  final _lodManager = LodManager();
  
  // Current state
  List<LatLng> _fullRoute = [];
  List<LatLng> _renderedRoute = [];
  List<RouteSegment> _segments = [];
  double _currentZoom = 5.0;
  
  // Debounce/Throttle
  Timer? _debounceTimer;
  Timer? _throttleTimer;
  bool _isProcessing = false;
  bool _hasPendingUpdate = false;
  
  // Progressive loading
  ProgressiveRouteLoader? _progressiveLoader;
  
  // Cache
  final Map<String, List<LatLng>> _simplifiedCache = {};
  
  static const Duration _debounceDuration = Duration(milliseconds: 100);

  OptimizedRouteRenderer({
    required Function(List<LatLng>) onRouteUpdated,
    Function()? onRenderComplete,
  }) : _onRouteUpdated = onRouteUpdated,
       _onRenderComplete = onRenderComplete;

  /// Update zoom level for LOD adjustments
  void updateZoom(double zoom) {
    if ((_currentZoom - zoom).abs() < 0.1) return;
    
    _currentZoom = zoom;
    _lodManager.updateZoom(zoom);
    
    // Re-simplify based on new zoom level
    _applyLodAndUpdate();
  }

  /// Set new route with automatic optimization
  /// Uses debounce to prevent rapid updates
  Future<void> setRoute(List<LatLng> points, {bool immediate = false}) async {
    _debounceTimer?.cancel();
    
    if (immediate) {
      await _processRoute(points);
    } else {
      _debounceTimer = Timer(_debounceDuration, () => _processRoute(points));
    }
  }

  /// Force immediate route update (bypass debounce)
  Future<void> setRouteImmediate(List<LatLng> points) async {
    await _processRoute(points);
  }

  /// Process route with all optimizations
  Future<void> _processRoute(List<LatLng> points) async {
    if (_isProcessing) {
      _hasPendingUpdate = true;
      _pendingPoints = points;
      return;
    }

    _isProcessing = true;
    _hasPendingUpdate = false;
    _fullRoute = points;
    
    try {
      // Step 1: Quick initial render with heavy simplification
      final quickSimplified = await _quickSimplify(points);
      _renderedRoute = quickSimplified;
      _onRouteUpdated(quickSimplified);

      // Step 2: Segment and load progressively
      _segments = RouteSegmenter.createProgressiveSegments(
        points,
        baseSegmentSize: 500,
        initialTolerance: _lodManager.getCurrentConfig().simplificationTolerance,
      );

      // Step 3: Start progressive loading if multiple segments
      if (_segments.length > 1) {
        await _startProgressiveLoading();
      } else {
        // Single segment - apply full LOD simplification
        final lodSimplified = _lodManager.simplifyForCurrentZoom(points);
        _renderedRoute = lodSimplified;
        _onRouteUpdated(lodSimplified);
        _onRenderComplete?.call();
      }
    } finally {
      _isProcessing = false;
      
      // Process pending update if any
      if (_hasPendingUpdate && _pendingPoints != null) {
        _processRoute(_pendingPoints!);
      }
    }
  }

  List<LatLng>? _pendingPoints;

  /// Quick simplification for immediate feedback
  Future<List<LatLng>> _quickSimplify(List<LatLng> points) async {
    if (points.length < 500) return points;

    // Use sampling for fastest initial render
    final step = (points.length / 500).ceil();
    return RouteSimplifier.simplifyBySampling(points, step: step);
  }

  /// Start progressive loading of route segments
  Future<void> _startProgressiveLoading() async {
    _progressiveLoader?.cancel();
    
    _progressiveLoader = ProgressiveRouteLoader(
      segments: _segments,
      onSegmentLoaded: (updatedPoints) {
        _renderedRoute = updatedPoints;
        _onRouteUpdated(updatedPoints);
      },
      onComplete: (finalPoints) {
        // Apply final LOD simplification
        final lodSimplified = _lodManager.simplifyForCurrentZoom(finalPoints);
        _renderedRoute = lodSimplified;
        _onRouteUpdated(lodSimplified);
        _onRenderComplete?.call();
      },
    );

    await _progressiveLoader!.load();
  }

  /// Apply current LOD settings and update render
  void _applyLodAndUpdate() {
    if (_fullRoute.isEmpty) return;
    
    final simplified = _lodManager.simplifyForCurrentZoom(_fullRoute);
    if (simplified.length != _renderedRoute.length || 
        !_listsEqual(simplified, _renderedRoute)) {
      _renderedRoute = simplified;
      _onRouteUpdated(simplified);
    }
  }

  bool _listsEqual(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].latitude != b[i].latitude || 
          a[i].longitude != b[i].longitude) {
        return false;
      }
    }
    return true;
  }

  /// Get cached simplified route or compute and cache
  Future<List<LatLng>> getCachedOrCompute(
    String cacheKey,
    List<LatLng> points,
  ) async {
    if (_simplifiedCache.containsKey(cacheKey)) {
      return _simplifiedCache[cacheKey]!;
    }

    final simplified = _lodManager.simplifyForCurrentZoom(points);
    _simplifiedCache[cacheKey] = simplified;
    return simplified;
  }

  /// Clear cache
  void clearCache() {
    _simplifiedCache.clear();
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();
    _progressiveLoader?.cancel();
    _fullRoute.clear();
    _renderedRoute.clear();
    _segments.clear();
    _simplifiedCache.clear();
  }

  // Getters for debugging
  List<LatLng> get renderedRoute => List.unmodifiable(_renderedRoute);
  List<LatLng> get fullRoute => List.unmodifiable(_fullRoute);
  int get segmentCount => _segments.length;
  double get currentZoom => _currentZoom;
  bool get isProcessing => _isProcessing;
}

/// Lightweight version for simple use cases
class SimpleRouteOptimizer {
  SimpleRouteOptimizer._();

  /// One-shot optimization: simplify route for given zoom level
  static Future<List<LatLng>> optimizeForZoom({
    required List<LatLng> points,
    required double zoom,
    int? maxPoints,
  }) async {
    if (points.isEmpty) return points;

    final lodManager = LodManager();
    lodManager.updateZoom(zoom);

    // Use isolate for heavy computation
    final config = lodManager.getCurrentConfig();
    final limit = maxPoints ?? config.maxPoints;
    
    if (points.length <= limit || limit < 0) {
      return points;
    }

    return PolylineDecoder.simplifyRoute(
      points: points,
      tolerance: config.simplificationTolerance,
      maxPoints: limit,
    );
  }

  /// Batch optimize multiple routes
  static Future<List<List<LatLng>>> batchOptimize({
    required List<List<LatLng>> routes,
    required double zoom,
  }) async {
    return Future.wait(routes.map((route) => 
      optimizeForZoom(points: route, zoom: zoom),
    ));
  }
}

// Import the other utilities at the top of the file instead
