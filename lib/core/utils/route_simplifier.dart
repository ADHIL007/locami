import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Route simplification utility using Douglas-Peucker algorithm
/// Reduces thousands of points to hundreds while preserving shape
class RouteSimplifier {
  RouteSimplifier._();

  /// Simplify route using Douglas-Peucker algorithm
  /// [tolerance] controls how much simplification (higher = fewer points)
  /// Typical values: 0.0001 (high detail) to 0.001 (low detail)
  static List<LatLng> simplifyDouglasPeucker(
    List<LatLng> points, {
    double tolerance = 0.0003,
  }) {
    if (points.length <= 2) return points;

    final result = <LatLng>[];
    _douglasPeucker(points, 0, points.length - 1, tolerance, result);
    
    // Ensure start and end points are preserved
    if (result.isEmpty || result.first != points.first) {
      result.insert(0, points.first);
    }
    if (result.last != points.last) {
      result.add(points.last);
    }
    
    return result;
  }

  static void _douglasPeucker(
    List<LatLng> points,
    int start,
    int end,
    double tolerance,
    List<LatLng> result,
  ) {
    if (end <= start + 1) {
      if (start == end) result.add(points[start]);
      return;
    }

    // Find the point with maximum distance from line
    double maxDistance = 0;
    int index = start;

    final startPoint = points[start];
    final endPoint = points[end];

    for (int i = start + 1; i < end; i++) {
      final distance = _perpendicularDistance(
        points[i],
        startPoint,
        endPoint,
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      _douglasPeucker(points, start, index, tolerance, result);
      _douglasPeucker(points, index, end, tolerance, result);
    } else {
      // Just add the endpoints
      if (!result.contains(startPoint)) result.add(startPoint);
      if (!result.contains(endPoint)) result.add(endPoint);
    }
  }

  /// Calculate perpendicular distance from point to line
  static double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final lat1 = _toRadians(lineStart.latitude);
    final lon1 = _toRadians(lineStart.longitude);
    final lat2 = _toRadians(lineEnd.latitude);
    final lon2 = _toRadians(lineEnd.longitude);
    final lat3 = _toRadians(point.latitude);
    final lon3 = _toRadians(point.longitude);

    // Convert to Cartesian for simpler calculation (approximation for small distances)
    final x1 = math.cos(lat1) * math.cos(lon1);
    final y1 = math.cos(lat1) * math.sin(lon1);
    final z1 = math.sin(lat1);

    final x2 = math.cos(lat2) * math.cos(lon2);
    final y2 = math.cos(lat2) * math.sin(lon2);
    final z2 = math.sin(lat2);

    final x3 = math.cos(lat3) * math.cos(lon3);
    final y3 = math.cos(lat3) * math.sin(lon3);
    final z3 = math.sin(lat3);

    // Cross product to find distance
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dz = z2 - z1;

    final t = ((x3 - x1) * dx + (y3 - y1) * dy + (z3 - z1) * dz) /
              (dx * dx + dy * dy + dz * dz);

    final closestX = x1 + t * dx;
    final closestY = y1 + t * dy;
    final closestZ = z1 + t * dz;

    final dist = math.sqrt(
      math.pow(x3 - closestX, 2) +
      math.pow(y3 - closestY, 2) +
      math.pow(z3 - closestZ, 2),
    );

    // Convert back to approximate meters (Earth radius ~6371km)
    return dist * 6371000;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Simple sampling-based simplification (faster, less accurate)
  /// Takes every Nth point
  static List<LatLng> simplifyBySampling(List<LatLng> points, {int step = 10}) {
    if (points.length <= 2) return points;
    if (step <= 1) return points;

    final result = <LatLng>[points.first];
    
    for (int i = 1; i < points.length - 1; i += step) {
      result.add(points[i]);
    }
    
    // Always include the last point
    if (points.last != result.last) {
      result.add(points.last);
    }

    return result;
  }

  /// Adaptive simplification based on total route length
  /// Longer routes get more aggressive simplification
  static List<LatLng> simplifyAdaptive(
    List<LatLng> points, {
    double baseTolerance = 0.0001,
  }) {
    if (points.length < 100) return points;

    // Estimate route length implicitly by scaling points
    // Scale factor based on estimated length
    final scaleFactor = points.length / 100.0;
    final tolerance = baseTolerance * math.sqrt(scaleFactor);
    
    return simplifyDouglasPeucker(points, tolerance: tolerance.clamp(0.0001, 0.001));
  }

}
