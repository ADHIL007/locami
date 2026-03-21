import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:locami/core/constants/api_constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/db_manager/app_status_manager.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/core/db_helper/trip_db.dart';

class RouteData {
  final List<LatLng> points;
  final double distance; // in meters
  final double duration; // in seconds

  RouteData({
    required this.points,
    required this.distance,
    required this.duration,
  });
}

class RoutingService {
  RoutingService._();
  static final RoutingService instance = RoutingService._();

  static const _baseUrl = '${ApiConstants.osrmRouteUrl}driving';

  Future<RouteData> getRoute(LatLng start, LatLng end, {String? destinationName}) async {
    final cacheId = destinationName ?? '${end.latitude},${end.longitude}';
    final AppStatus appStatus = await AppStatusManager.instance.status;
    final bool isOnline = appStatus.isInternetOn;

    if (!isOnline) {
      final cached = await TripDbHelper.instance.getCachedRoute(cacheId);
      if (cached != null) {
        final List pointsData = json.decode(cached['points']);
        final points = pointsData.map((p) => LatLng(p[0], p[1])).toList();
        return RouteData(
          points: points,
          distance: cached['distance'],
          duration: cached['duration'],
        );
      }
    }

    final url = Uri.parse(
      '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final List coordinates = route['geometry']['coordinates'];
          final double osrmDist = (route['distance'] as num).toDouble();
          final double duration = (route['duration'] as num).toDouble();
          
          final points = coordinates.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          
          // Cache the successful route
          final pointsJson = json.encode(points.map((p) => [p.latitude, p.longitude]).toList());
          await TripDbHelper.instance.saveCachedRoute(cacheId, pointsJson, osrmDist, duration);

          return RouteData(
            points: points,
            distance: osrmDist,
            duration: duration,
          );
        }
      }
    } catch (_) {}
    
    // Fallback to straight line (Haversine) if internet/routing fails and no cache
    final fallbackDistance = Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    );
    
    return RouteData(
      points: [start, end],
      distance: fallbackDistance,
      duration: fallbackDistance / 12.0, // Slow down estimate for offline
    );
  }
}
