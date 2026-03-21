import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:locami/core/constants/api_constants.dart';
import 'package:geolocator/geolocator.dart';

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

  Future<RouteData> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final List coordinates = route['geometry']['coordinates'];
          final double osrmDist = (route['distance'] as num).toDouble();
          final double duration = (route['duration'] as num).toDouble();
          
          final haversineDist = Geolocator.distanceBetween(
            start.latitude, start.longitude,
            end.latitude, end.longitude,
          );

          print('DISTANCE: OSRM: $osrmDist m, Haversine: $haversineDist m');

          final points = coordinates.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          
          return RouteData(
            points: points,
            distance: osrmDist,
            duration: duration,
          );
        }
      }
    } catch (_) {}
    
    // Fallback to straight line (Haversine) if internet/routing fails
    final fallbackDistance = Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    );
    
    return RouteData(
      points: [start, end],
      distance: fallbackDistance,
      duration: fallbackDistance / 13.8, // Estimate duration based on ~50km/h
    );
  }
}
