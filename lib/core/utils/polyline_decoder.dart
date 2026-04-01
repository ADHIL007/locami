import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Isolate-based polyline decoding and processing
/// All heavy computation runs off the main thread
class PolylineDecoder {
  PolylineDecoder._();

  /// Decode and simplify route points in an isolate
  /// Returns simplified points ready for rendering
  static Future<List<LatLng>> decodeAndSimplify({
    required List<List<double>> rawCoordinates,
    double tolerance = 0.0003,
    int maxPoints = 1000,
  }) async {
    // Convert to LatLng list
    final points = rawCoordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    if (points.length <= maxPoints) {
      return points;
    }

    // Run simplification in isolate
    return compute(_simplifyRoute, SimplifyParams(
      points: points,
      tolerance: tolerance,
      maxPoints: maxPoints,
    ));
  }

  /// Simplify route points using Douglas-Peucker algorithm
  /// Runs in isolate via compute()
  static Future<List<LatLng>> simplifyRoute({
    required List<LatLng> points,
    double tolerance = 0.0003,
    int? maxPoints,
  }) async {
    if (points.isEmpty) return points;
    
    final params = SimplifyParams(
      points: points,
      tolerance: tolerance,
      maxPoints: maxPoints ?? points.length,
    );

    return compute(_simplifyRoute, params);
  }

  /// Internal function that runs in isolate
  static List<LatLng> _simplifyRoute(SimplifyParams params) {
    final points = params.points;
    
    if (points.length <= 2 || points.length <= params.maxPoints) {
      return points;
    }

    // Apply Douglas-Peucker algorithm
    final result = <LatLng>[];
    _douglasPeuckerRecursive(points, 0, points.length - 1, params.tolerance, result);

    // Ensure endpoints are preserved
    if (result.isEmpty || result.first != points.first) {
      result.insert(0, points.first);
    }
    if (result.last != points.last) {
      result.add(points.last);
    }

    // If still too many points, apply sampling as fallback
    if (result.length > params.maxPoints && params.maxPoints > 0) {
      final step = (result.length / params.maxPoints).ceil();
      return _samplePoints(result, step);
    }

    return result;
  }

  static void _douglasPeuckerRecursive(
    List<LatLng> points,
    int start,
    int end,
    double tolerance,
    List<LatLng> result,
  ) {
    if (end <= start + 1) {
      if (start == end && !result.contains(points[start])) {
        result.add(points[start]);
      }
      return;
    }

    double maxDistance = 0;
    int index = start;

    final startPoint = points[start];
    final endPoint = points[end];

    for (int i = start + 1; i < end; i++) {
      final distance = _perpendicularDistance(points[i], startPoint, endPoint);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    if (maxDistance > tolerance) {
      _douglasPeuckerRecursive(points, start, index, tolerance, result);
      _douglasPeuckerRecursive(points, index, end, tolerance, result);
    } else {
      if (!result.contains(startPoint)) result.add(startPoint);
      if (!result.contains(endPoint)) result.add(endPoint);
    }
  }

  static double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    // Use simple planar approximation for performance
    final dx = lineEnd.longitude - lineStart.longitude;
    final dy = lineEnd.latitude - lineStart.latitude;
    
    if (dx == 0 && dy == 0) {
      return _haversineDistance(point, lineStart);
    }

    final t = ((point.longitude - lineStart.longitude) * dx +
               (point.latitude - lineStart.latitude) * dy) /
              (dx * dx + dy * dy);

    final closestX = lineStart.longitude + t * dx;
    final closestY = lineStart.latitude + t * dy;

    return _haversineDistance(point, LatLng(closestY, closestX));
  }

  static double _haversineDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000; // meters
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLon = _toRadians(p2.longitude - p1.longitude);
    final lat1 = _toRadians(p1.latitude);
    final lat2 = _toRadians(p2.latitude);

    final a = _sinHalf(dLat) * _sinHalf(dLat) +
              _sinHalf(dLon) * _sinHalf(dLon) * 
              _cos(lat1) * _cos(lat2);
    
    final c = 2 * _atan2Safe(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double deg) => deg * 0.017453292519943295;
  static double _sinHalf(double x) {
    final half = x / 2;
    return _sin(half);
  }
  
  // Approximate sin for small angles
  static double _sin(double x) {
    // Taylor series approximation for small angles
    final x2 = x * x;
    return x - (x * x2) / 6 + (x * x2 * x2) / 120;
  }
  
  static double _cos(double x) {
    final x2 = x * x;
    return 1 - (x2 / 2) + (x2 * x2) / 24;
  }
  
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    var guess = x / 2;
    for (int i = 0; i < 5; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  
  static double _atan2Safe(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0) {
      if (y >= 0) return _atan(y / x) + 3.141592653589793;
      return _atan(y / x) - 3.141592653589793;
    }
    if (y > 0) return 3.141592653589793 / 2;
    if (y < 0) return -3.141592653589793 / 2;
    return 0;
  }
  
  static double _atan(double x) {
    // Approximation using polynomial
    final x2 = x * x;
    return x * (1 - 0.333333 * x2 + 0.2 * x2 * x2 - 0.142857 * x2 * x2 * x2);
  }

  static List<LatLng> _samplePoints(List<LatLng> points, int step) {
    if (step <= 1) return points;
    
    final result = <LatLng>[points.first];
    for (int i = 1; i < points.length - 1; i += step) {
      result.add(points[i]);
    }
    if (points.last != result.last) {
      result.add(points.last);
    }
    return result;
  }

  /// Batch process multiple routes in parallel isolates
  static Future<List<List<LatLng>>> decodeMultipleRoutes(
    List<List<List<double>>> allRoutes, {
    double tolerance = 0.0003,
    int maxPoints = 1000,
  }) async {
    final futures = allRoutes.map((route) => decodeAndSimplify(
      rawCoordinates: route,
      tolerance: tolerance,
      maxPoints: maxPoints,
    )).toList();

    return Future.wait(futures);
  }
}

/// Parameters for isolate-based simplification
/// Must be serializable for isolate communication
class SimplifyParams {
  final List<LatLng> points;
  final double tolerance;
  final int maxPoints;

  SimplifyParams({
    required this.points,
    required this.tolerance,
    required this.maxPoints,
  });
}
