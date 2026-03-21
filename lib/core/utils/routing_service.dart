import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:locami/core/constants/api_constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/db_manager/app_status_manager.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/core/db_helper/trip_db.dart';

class SingleRoute {
  final List<LatLng> points;
  final double distance;
  final double duration;

  SingleRoute({
    required this.points,
    required this.distance,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => [p.latitude, p.longitude]).toList(),
    'distance': distance,
    'duration': duration,
  };

  factory SingleRoute.fromJson(Map<String, dynamic> json) {
    return SingleRoute(
      points: (json['points'] as List).map((p) => LatLng(p[0], p[1])).toList(),
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
    );
  }
}

class RouteData {
  final List<SingleRoute> alternatives;

  RouteData({required this.alternatives});

  List<LatLng> get points => alternatives.isNotEmpty ? alternatives.first.points : [];
  double get distance => alternatives.isNotEmpty ? alternatives.first.distance : 0.0;
  double get duration => alternatives.isNotEmpty ? alternatives.first.duration : 0.0;
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
        try {
          final decoded = json.decode(cached['points']);
          if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
             final alternatives = decoded.map((e) => SingleRoute.fromJson(e)).toList();
             if (alternatives.isNotEmpty) {
               return RouteData(alternatives: List<SingleRoute>.from(alternatives));
             }
          } else if (decoded is List) {
             final points = decoded.map((p) => LatLng(p[0], p[1])).toList();
             return RouteData(alternatives: [
               SingleRoute(points: points, distance: cached['distance'], duration: cached['duration'])
             ]);
          }
        } catch (_) {}
      }
    }

    final url = Uri.parse(
      '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&alternatives=true',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final List<SingleRoute> alts = [];
          for (var route in data['routes']) {
            final List coordinates = route['geometry']['coordinates'];
            final double osrmDist = (route['distance'] as num).toDouble();
            final double duration = (route['duration'] as num).toDouble();
            final points = coordinates.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
            alts.add(SingleRoute(points: points, distance: osrmDist, duration: duration));
          }
          
          if (alts.isNotEmpty) {
            // Save to cache asynchronously so failure doesn't block route rendering
            try {
              final routesJson = json.encode(alts.map((a) => a.toJson()).toList());
              TripDbHelper.instance.saveCachedRoute(cacheId, routesJson, alts.first.distance, alts.first.duration);
            } catch (_) {} // Ignore cache DB locking errors
            
            return RouteData(alternatives: alts);
          }
        }
      }
    } catch (e) {
      // Print error to console for debugging if needed
    }
    
    // Fallback to straight line (Haversine) if internet/routing fails and no cache
    final fallbackDistance = Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    );
    
    return RouteData(
      alternatives: [
        SingleRoute(
          points: [start, end],
          distance: fallbackDistance,
          duration: fallbackDistance / 12.0,
        )
      ]
    );
  }
}
