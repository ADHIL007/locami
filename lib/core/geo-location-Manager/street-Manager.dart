import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class StreetManager {
  StreetManager._();
  static final StreetManager instance = StreetManager._();

  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _cacheTTL = Duration(minutes: 100);

  List<String>? _nearbyCache;
  DateTime? _nearbyCacheTime;

  final Map<String, _CacheEntry> _searchCache = {};

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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  bool _isExpired(DateTime time) {
    return DateTime.now().difference(time) > _cacheTTL;
  }

  // ----------------------------
  // Nearby streets (cached)
  // ----------------------------
  Position? _lastKnownPosition;

  // ----------------------------
  // Nearby streets (cached)
  // ----------------------------
  Future<List<String>> getNearbyStreets({int limit = 8}) async {
    if (_nearbyCache != null &&
        _nearbyCacheTime != null &&
        !_isExpired(_nearbyCacheTime!)) {
      return _nearbyCache!;
    }

    try {
      final position = await _getCurrentLocation();
      _lastKnownPosition = position;

      // Search for generic interesting places nearby
      // We use a viewbox with bounded=1 to strictly find things nearby
      final offset = 0.01; // ~1km
      final viewbox =
          '${position.longitude - offset},${position.latitude + offset},${position.longitude + offset},${position.latitude - offset}';

      final url = Uri.parse(
        '$_baseUrl/search'
        '?q=highway' // Generic query to find streets/roads
        '&format=json'
        '&limit=$limit'
        '&viewbox=$viewbox'
        '&bounded=1'
        '&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'locami-app'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final result = data.map<String>((e) => _formatDisplayName(e)).toList();

        // Deduplicate
        final uniqueResult = result.toSet().toList();

        _nearbyCache = uniqueResult;
        _nearbyCacheTime = DateTime.now();

        return uniqueResult;
      }
    } catch (e) {
      print('Error fetching nearby: $e');
    }

    return [];
  }

  // ----------------------------
  // Search streets (cached)
  // ----------------------------
  // ----------------------------
  // Reverse Geocoding (Get Address & Country)
  // ----------------------------
  Future<Map<String, String>?> getCurrentLocationDetails() async {
    try {
      final position = await _getCurrentLocation();
      _lastKnownPosition = position;

      final url = Uri.parse(
        '$_baseUrl/reverse'
        '?lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&format=json',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'locami-app'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addressMap = data['address'];

        final formattedAddress = _formatDisplayName(data);
        final countryCode = addressMap['country_code']?.toString() ?? '';

        return {'address': formattedAddress, 'countryCode': countryCode};
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
    return null;
  }

  // ----------------------------
  // Search streets (cached)
  // ----------------------------
  Future<List<String>> searchStreets(
    String query, {
    String? countryCode, // Make optional
    int limit = 6,
  }) async {
    if (query.isEmpty) return [];

    // Prioritize passed countryCode, then detect if null
    if (countryCode == null) {
      // Try to use last known position's country if we have it, or fetch it?
      // For now, let's rely on viewbox if countryCode is missing
    }

    final key = '${query.toLowerCase()}_${countryCode ?? 'global'}';

    final cached = _searchCache[key];
    if (cached != null && !_isExpired(cached.time)) {
      return cached.data;
    }

    // Prepare Viewbox
    String viewboxParam = '';
    try {
      _lastKnownPosition ??= await _getCurrentLocation();
      if (_lastKnownPosition != null) {
        final p = _lastKnownPosition!;
        // Bias ~50km around user
        final offset = 0.5;
        // bounded=0 means "prefer inside results, but also return outside results if matches are better"
        viewboxParam =
            '&viewbox=${p.longitude - offset},${p.latitude + offset},${p.longitude + offset},${p.latitude - offset}&bounded=0';
      }
    } catch (e) {
      // Ignore location error
    }

    // Build URL
    String params = '?q=$query&format=json&limit=$limit&addressdetails=1';

    // logic: If we have a viewbox (local search), bounded=1 usually does the trick for "local locations"
    // If we have a countryCode, add it.
    if (countryCode != null && countryCode.isNotEmpty) {
      params += '&countrycodes=$countryCode';
    }

    // Append viewbox (crucial for "local" results)
    params += viewboxParam;

    final url = Uri.parse('$_baseUrl/search$params');

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'locami-app'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final result = data.map<String>((e) => _formatDisplayName(e)).toList();

        _searchCache[key] = _CacheEntry(data: result, time: DateTime.now());

        return result;
      }
    } catch (e) {
      print('Search error: $e');
    }

    return [];
  }

  String _formatDisplayName(Map<dynamic, dynamic> item) {
    if (item['address'] == null) return item['display_name'] ?? '';

    // Construct a simpler name: Name/Road, City/Suburb
    final address = item['address'];
    final name = item['name'] ?? '';

    // Prefer specific names over just generic roads if possible, but fallback to road
    String mainPart = name;
    if (mainPart.isEmpty) mainPart = address['road'] ?? '';
    if (mainPart.isEmpty) mainPart = address['suburb'] ?? '';
    if (mainPart.isEmpty) mainPart = address['city'] ?? '';
    if (mainPart.isEmpty) return item['display_name'];

    // Add context (City > Suburb > State)
    String secondPart =
        address['city'] ?? address['town'] ?? address['village'] ?? '';
    if (secondPart.isEmpty) secondPart = address['suburb'] ?? '';
    if (secondPart.isEmpty) secondPart = address['state'] ?? '';

    // Avoid duplication aka "New York, New York"
    if (secondPart.isNotEmpty && !mainPart.contains(secondPart)) {
      return '$mainPart, $secondPart';
    }

    return mainPart;
  }

  // Optional manual clear
  void clearCache() {
    _nearbyCache = null;
    _nearbyCacheTime = null;
    _searchCache.clear();
  }
}

// ----------------------------
// Cache model
// ----------------------------
class _CacheEntry {
  final List<String> data;
  final DateTime time;

  _CacheEntry({required this.data, required this.time});
}
