import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:locami/core/constants/api_constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/db_manager/app_status_manager.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/core/db_helper/trip_db.dart';
import 'package:flutter/foundation.dart';
import 'package:locami/core/utils/polyline_decoder.dart';
import 'package:locami/core/utils/route_simplifier.dart';

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
  
  // Cache for decoded routes to prevent re-decoding
  final Map<String, RouteData> _routeCache = {};
  
  // Debounce timer for route requests
  Timer? _debounceTimer;

  /// Get route with isolate-based decoding and simplification
  /// Automatically simplifies long routes to prevent UI freeze
  Future<RouteData> getRoute(
    LatLng start, 
    LatLng end, 
    {String? destinationName,
    bool simplifyLongRoutes = true,
    int maxPoints = 2000,
    Duration debounceDuration = const Duration(milliseconds: 50)} 
  ) async {
    // Cancel any pending request
    _debounceTimer?.cancel();
    
    final cacheId = destinationName ?? '${end.latitude},${end.longitude}';
    
    // Create a debounced future
    Future<RouteData> fetchRoute() async {
      return _fetchRouteInternal(
        start, end, 
        cacheId: cacheId,
        simplifyLongRoutes: simplifyLongRoutes,
        maxPoints: maxPoints,
      );
    }
    
    // Apply debounce
    if (debounceDuration.inMilliseconds > 0) {
      return _debounceTimer = Timer(debounceDuration, () {});
      await Future.delayed(debounceDuration);
    }
    
    return fetchRoute();
  }
  
  /// Internal method to fetch and process route
  Future<RouteData> _fetchRouteInternal(
    LatLng start, 
    LatLng end, 
    {required String cacheId,
    required bool simplifyLongRoutes,
    required int maxPoints}) async {
    
    final AppStatus appStatus = await AppStatusManager.instance.status;
    final bool isOnline = appStatus.isInternetOn;

    // Check memory cache first
    if (_routeCache.containsKey(cacheId)) {
      return _routeCache[cacheId]!;
    }

    // Check database cache if offline
    if (!isOnline) {
      final cached = await TripDbHelper.instance.getCachedRoute(cacheId);
      if (cached != null) {
        try {
          final decoded = json.decode(cached['points']);
          if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
             final alternatives = decoded.map((e) => SingleRoute.fromJson(e)).toList();
             if (alternatives.isNotEmpty) {
               final routeData = RouteData(alternatives: List<SingleRoute>.from(alternatives));
               _routeCache[cacheId] = routeData;
               return routeData;
             }
          } else if (decoded is List) {
             final points = decoded.map((p) => LatLng(p[0], p[1])).toList();
             final routeData = RouteData(alternatives: [
               SingleRoute(points: points, distance: cached['distance'], duration: cached['duration'])
             ]);
             _routeCache[cacheId] = routeData;
             return routeData;
          }
        } catch (_) {}
      }
    }

    // Fetch from network
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
            
            // Convert coordinates to LatLng
            var points = coordinates.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
            
            // Apply simplification for long routes using isolate
            if (simplifyLongRoutes && points.length > maxPoints) {
              points = await PolylineDecoder.simplifyRoute(
                points: points,
                tolerance: 0.0003, // ~30 meters
                maxPoints: maxPoints,
              );
            }
            
            alts.add(SingleRoute(points: points, distance: osrmDist, duration: duration));
          }
          
          if (alts.isNotEmpty) {
            // Save to cache asynchronously so failure doesn't block route rendering
            try {
              final routesJson = json.encode(alts.map((a) => a.toJson()).toList());
              TripDbHelper.instance.saveCachedRoute(cacheId, routesJson, alts.first.distance, alts.first.duration);
            } catch (_) {} // Ignore cache DB locking errors
            
            final routeData = RouteData(alternatives: alts);
            _routeCache[cacheId] = routeData;
            return routeData;
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
    
    final routeData = RouteData(
      alternatives: [
        SingleRoute(
          points: [start, end],
          distance: fallbackDistance,
          duration: fallbackDistance / 12.0,
        )
      ]
    );
    _routeCache[cacheId] = routeData;
    return routeData;
  }
  
  /// Clear the in-memory route cache
  void clearCache() {
    _routeCache.clear();
  }
  
  @override
  void close() {
    _debounceTimer?.cancel();
    clearCache();
  }
}
