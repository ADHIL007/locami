import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  RoutingService._();
  static final RoutingService instance = RoutingService._();

  static const _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coordinates = data['routes'][0]['geometry']['coordinates'];
        return coordinates.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      }
    } catch (_) {}
    
    // Fallback to straight line if routing fails (basic "offline" behavior)
    return [start, end];
  }
}
