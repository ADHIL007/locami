import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'route_simplifier.dart';

/// Level of Detail configuration for route rendering
/// Determines how many points to show based on zoom level
class LodConfig {
  final double zoomLevel;
  final int maxPoints;
  final double simplificationTolerance;

  const LodConfig({
    required this.zoomLevel,
    required this.maxPoints,
    required this.simplificationTolerance,
  });

  /// Default LOD configurations from low to high zoom
  static const List<LodConfig> defaults = [
    LodConfig(zoomLevel: 0, maxPoints: 50, simplificationTolerance: 0.001),
    LodConfig(zoomLevel: 5, maxPoints: 100, simplificationTolerance: 0.0008),
    LodConfig(zoomLevel: 8, maxPoints: 200, simplificationTolerance: 0.0005),
    LodConfig(zoomLevel: 10, maxPoints: 400, simplificationTolerance: 0.0003),
    LodConfig(zoomLevel: 12, maxPoints: 800, simplificationTolerance: 0.0002),
    LodConfig(zoomLevel: 14, maxPoints: 1500, simplificationTolerance: 0.0001),
    LodConfig(zoomLevel: 16, maxPoints: 3000, simplificationTolerance: 0.00005),
    LodConfig(zoomLevel: 18, maxPoints: -1, simplificationTolerance: 0), // Full detail
  ];
}

/// Manages Level of Detail (LOD) for route rendering
/// Selects appropriate simplification based on current zoom level
class LodManager {
  final List<LodConfig> _configs;
  double _currentZoom = 5.0;
  
  LodManager({List<LodConfig>? configs}) 
    : _configs = configs ?? LodConfig.defaults;

  /// Update current zoom level
  void updateZoom(double zoom) {
    _currentZoom = zoom;
  }

  /// Get the appropriate LOD config for current zoom
  LodConfig getCurrentConfig() {
    LodConfig? bestConfig;
    
    for (final config in _configs) {
      if (config.zoomLevel <= _currentZoom) {
        bestConfig = config;
      } else {
        break;
      }
    }
    
    return bestConfig ?? _configs.first;
  }

  /// Simplify route points based on current zoom level
  List<LatLng> simplifyForCurrentZoom(List<LatLng> points) {
    if (points.isEmpty) return points;
    
    final config = getCurrentConfig();
    
    // No simplification needed
    if (config.maxPoints < 0 || points.length <= config.maxPoints) {
      return points;
    }

    // Use Douglas-Peucker with tolerance-based simplification
    final simplified = RouteSimplifier.simplifyDouglasPeucker(
      points,
      tolerance: config.simplificationTolerance,
    );

    // If still too many points, fall back to sampling
    if (simplified.length > config.maxPoints && config.maxPoints > 0) {
      final step = (simplified.length / config.maxPoints).ceil();
      return RouteSimplifier.simplifyBySampling(simplified, step: step);
    }

    return simplified;
  }

  /// Get target point count for current zoom
  int getTargetPointCount() {
    return getCurrentConfig().maxPoints;
  }
}

/// Represents a segment of a route for progressive rendering
class RouteSegment {
  final List<LatLng> points;
  final int segmentIndex;
  final int totalSegments;
  final bool isSimplified;

  RouteSegment({
    required this.points,
    required this.segmentIndex,
    required this.totalSegments,
    this.isSimplified = false,
  });

  /// Create a simplified copy of this segment
  RouteSegment simplify(double tolerance) {
    if (isSimplified || points.length < 10) {
      return this;
    }

    final simplifiedPoints = RouteSimplifier.simplifyDouglasPeucker(
      points,
      tolerance: tolerance,
    );

    return RouteSegment(
      points: simplifiedPoints,
      segmentIndex: segmentIndex,
      totalSegments: totalSegments,
      isSimplified: true,
    );
  }
}

/// Splits a route into manageable segments for progressive rendering
class RouteSegmenter {
  RouteSegmenter._();

  /// Split route into segments of approximately [maxPointsPerSegment]
  static List<RouteSegment> segmentRoute(
    List<LatLng> points, {
    int maxPointsPerSegment = 500,
  }) {
    if (points.isEmpty) return [];
    if (points.length <= maxPointsPerSegment) {
      return [
        RouteSegment(
          points: points,
          segmentIndex: 0,
          totalSegments: 1,
        ),
      ];
    }

    final segments = <RouteSegment>[];
    final totalSegments = (points.length / maxPointsPerSegment).ceil();
    
    for (int i = 0; i < points.length; i += maxPointsPerSegment) {
      final end = (i + maxPointsPerSegment < points.length) 
          ? i + maxPointsPerSegment 
          : points.length;
      
      // Include overlap point for continuity between segments
      final segmentPoints = points.sublist(i, end);
      if (end < points.length && segmentPoints.isNotEmpty) {
        // Add one point from next segment for visual continuity
        segmentPoints.add(points[end]);
      }

      segments.add(RouteSegment(
        points: segmentPoints,
        segmentIndex: segments.length,
        totalSegments: totalSegments,
      ));
    }

    return segments;
  }

  /// Create simplified segments for initial render
  static List<RouteSegment> createProgressiveSegments(
    List<LatLng> points, {
    int baseSegmentSize = 500,
    double initialTolerance = 0.0005,
  }) {
    final segments = segmentRoute(points, maxPointsPerSegment: baseSegmentSize);
    
    // First segment gets highest priority and lowest simplification
    return segments.map((segment) {
      if (segment.segmentIndex == 0) {
        // Keep first segment more detailed for immediate display
        return segment.simplify(initialTolerance * 0.5);
      }
      return segment.simplify(initialTolerance);
    }).toList();
  }
}

/// Handles progressive loading of route details
/// Loads high-priority segments first, then fills in details
class ProgressiveRouteLoader {
  final List<RouteSegment> _segments;
  final Function(List<LatLng>) _onSegmentLoaded;
  final Function(List<LatLng>) _onComplete;
  bool _isLoading = false;
  int _loadedIndex = 0;
  
  ProgressiveRouteLoader({
    required List<RouteSegment> segments,
    required Function(List<LatLng>) onSegmentLoaded,
    required Function(List<LatLng>) onComplete,
  }) : _segments = segments,
       _onSegmentLoaded = onSegmentLoaded,
       _onComplete = onComplete;

  /// Start progressive loading
  Future<void> load() async {
    if (_isLoading || _segments.isEmpty) return;
    _isLoading = true;
    _loadedIndex = 0;

    final allPoints = <LatLng>[];

    // Load segments with decreasing priority
    for (int i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      
      // Load segment asynchronously to avoid blocking UI
      await compute(_processSegment, segment);
      
      allPoints.addAll(segment.points);
      _onSegmentLoaded(List.from(allPoints));
      _loadedIndex = i + 1;

      // Small delay between segments to prevent frame drops
      if (i < _segments.length - 1) {
        await Future.delayed(const Duration(milliseconds: 16)); // ~1 frame
      }
    }

    _isLoading = false;
    _onComplete(allPoints);
  }

  /// Cancel loading
  void cancel() {
    _isLoading = false;
  }

  /// Process a single segment (runs in isolate)
  static RouteSegment _processSegment(RouteSegment segment) {
    // Additional processing can be done here if needed
    return segment;
  }

  /// Get loading progress (0.0 to 1.0)
  double get progress => _segments.isEmpty 
      ? 1.0 
      : _loadedIndex / _segments.length;
}
