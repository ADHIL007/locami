import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class StreetManager {
  StreetManager._();
  static final StreetManager instance = StreetManager._();
  RxList<String> locations = <String>[].obs;
  RxBool isLoading = false.obs;
  static const _baseUrl = 'https://nominatim.openstreetmap.org';

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<Map<String, String>?> getCurrentLocationDetails() async {
    try {
      final position = await _getCurrentLocation();

      final url = Uri.parse(
        '$_baseUrl/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'locami-app'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};

        return {
          'address': _formatDisplayName(data),
          'countryCode': address['country_code']?.toString() ?? '',
        };
      }
    } catch (_) {}

    return null;
  }

  Future<List<String>> getNearbyStreets() async {
    final details = await getCurrentLocationDetails();
    if (details != null && details['address'] != null) {
      return [details['address']!];
    }
    return [];
  }

  Future<List<String>> searchStreets(
    String query, {
    String? countryCode = 'IN',
    int limit = 10,
    double? lat,
    double? lon,
  }) async {
    if (query.trim().isEmpty) {
      locations.clear();
      return [];
    }
    isLoading.value = true;

    final params = {
      'q': query,
      'format': 'json',
      'limit': '$limit',
      'addressdetails': '1',
      'countrycodes': countryCode ?? '',
      'accept-language': 'en',
    };

    if (lat != null && lon != null) {
      params['viewbox'] = '${lon - 0.1},${lat + 0.1},${lon + 0.1},${lat - 0.1}';
      params['bounded'] = '0';
    }

    final url = Uri.https('nominatim.openstreetmap.org', '/search', params);

    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'locami-app'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final results = data.map<String>((e) => _formatDisplayName(e)).toList();
        locations.assignAll(results);
        return results;
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      isLoading.value = false;
    }

    return [];
  }

  Future<Map<String, double>?> getCoordinates(String query) async {
    final params = {
      'q': query,
      'format': 'json',
      'limit': '1',
      'accept-language': 'en',
    };

    final url = Uri.https('nominatim.openstreetmap.org', '/search', params);

    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'locami-app'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {
            'lat': double.parse(data[0]['lat']),
            'lon': double.parse(data[0]['lon']),
          };
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return null;
  }

  String _formatDisplayName(Map item) {
    final address = item['address'];
    if (address == null) return item['display_name'] ?? '';

    String main =
        item['name'] ??
        address['road'] ??
        address['suburb'] ??
        address['city'] ??
        '';

    if (main.isEmpty) return item['display_name'] ?? '';

    String second =
        address['city'] ??
        address['town'] ??
        address['village'] ??
        address['state'] ??
        '';

    if (second.isNotEmpty && !main.contains(second)) {
      return '$main, $second';
    }

    return main;
  }
}
