import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:locami/core/db_helper/location_cache_db.dart';
import 'package:locami/core/constants/api_constants.dart';
import 'package:locami/db_manager/app_status_manager.dart';
import 'package:locami/core/model/appstatus_model.dart';

class StreetManager {
  StreetManager._();
  static final StreetManager instance = StreetManager._();
  RxList<String> locations = <String>[].obs;
  RxBool isLoading = false.obs;
  static const _baseUrl = 'https://${ApiConstants.nominatimDomain}';
  int _totalLocationRequests = 0;
  int _apiCallsMade = 0;
  int _cacheHits = 0;
  Map<String, String>? _cachedLocationDetails;
  List<double>? _cachedBoundingBox;

  bool _isWithinBoundingBox(double lat, double lon) {
    if (_cachedBoundingBox == null || _cachedBoundingBox!.length != 4)
      return false;
      
    // Add ~20 meters of GPS jitter padding (0.0002 degrees)
    const double padding = 0.0002;
    
    final minLat = _cachedBoundingBox![0] - padding;
    final maxLat = _cachedBoundingBox![1] + padding;
    final minLon = _cachedBoundingBox![2] - padding;
    final maxLon = _cachedBoundingBox![3] + padding;
    
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }

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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<Map<String, String>?> getCurrentLocationDetails() async {
    try {
      final position = await _getCurrentLocation();
      return getLocationDetailsAt(position.latitude, position.longitude);
    } catch (_) {}
    return null;
  }

  bool _isFetchingLocation = false;

  Future<Map<String, String>?> getLocationDetailsAt(
    double lat,
    double lon,
  ) async {
    _totalLocationRequests++;

    if (_isWithinBoundingBox(lat, lon) && _cachedLocationDetails != null) {
      _cacheHits++;
      debugPrint("GEO: ✅ CACHE HIT ($lat, $lon)");
      return _cachedLocationDetails;
    }

    if (_isFetchingLocation) {
      debugPrint("GEO: ⚡ Skipped request, another is already in flight ($lat, $lon)");
      return _cachedLocationDetails;
    }

    _isFetchingLocation = true;
    _apiCallsMade++;
    debugPrint("GEO: 🔄 API CALL ($lat, $lon)");

    try {
      final url = Uri.parse('$_baseUrl/reverse?lat=$lat&lon=$lon&format=json');

      final response = await http
          .get(url, headers: {'User-Agent': 'locami-app'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};

        final bboxRaw = data['boundingbox'] as List?;
        if (bboxRaw != null && bboxRaw.length == 4) {
          _cachedBoundingBox =
              bboxRaw.map((e) => double.tryParse(e.toString()) ?? 0.0).toList();
        }

        final details = {
          'address': _formatDisplayName(data),
          'suburb':
              address['suburb']?.toString() ??
              address['village']?.toString() ??
              address['town']?.toString() ??
              '',
          'countryCode': address['country_code']?.toString() ?? '',
        };

        _cachedLocationDetails = details;

        return details;
      }
    } catch (e) {
      debugPrint("GEO ERROR: $e");
    } finally {
      _isFetchingLocation = false;
    }

    return null;
  }

  void printMetrics() {
    if (_totalLocationRequests == 0) return;

    final hitRate = (_cacheHits / _totalLocationRequests * 100).toStringAsFixed(
      1,
    );

    debugPrint('════════════════════════════════════');
    debugPrint(' STREET MANAGER METRICS');
    debugPrint('Total Requests: $_totalLocationRequests');
    debugPrint('API Calls: $_apiCallsMade');
    debugPrint('Cache Hits: $_cacheHits');
    debugPrint('Hit Rate: $hitRate%');
    debugPrint('════════════════════════════════════');
  }

  Future<List<String>> getNearbyStreets() async {
    final details = await getCurrentLocationDetails();
    if (details != null && details['address'] != null) {
      return [details['address']!];
    }
    return [];
  }

  /// Smart search: Cache-first, then Nominatim fallback.
  ///
  /// Flow:
  /// 1. Check SQLite cache for prefix match
  /// 2. If cache has ≥3 results → return them immediately (no network)
  /// 3. If cache has <3 results → fetch from Nominatim, cache results, return merged
  /// 4. Results always sorted by: nearby first → most used → most recent
  Future<List<String>> searchStreets(
    String query, {
    String? countryCode = 'IN',
    int limit = 15,
    double? lat,
    double? lon,
  }) async {
    if (query.trim().isEmpty) {
      locations.clear();
      return [];
    }
    isLoading.value = true;

    try {
      final cachedResults = await LocationCacheDb.instance.searchCache(
        query: query,
        userLat: lat,
        userLon: lon,
        limit: limit,
      );

      final cachedNames =
          cachedResults.map((r) => r['display_name'] as String).toList();

      if (cachedNames.length >= 3) {
        locations.assignAll(cachedNames);
        isLoading.value = false;
        return cachedNames;
      }

      final networkResults = await _fetchFromPhoton(
        query,
        countryCode: countryCode,
        limit: limit,
        lat: lat,
        lon: lon,
      );

      if (networkResults.isNotEmpty) {
        await LocationCacheDb.instance.cacheResults(
          searchQuery: query,
          results: networkResults,
        );
      }

      final networkNames =
          networkResults.map((r) => r['display_name'] as String).toList();

      final merged = <String>[...cachedNames];
      for (final name in networkNames) {
        if (!merged.contains(name)) {
          merged.add(name);
        }
      }

      final finalResults = merged.take(limit).toList();
      locations.assignAll(finalResults);
      return finalResults;
    } catch (e) {
      debugPrint('Search error: $e');
      final fallback = await LocationCacheDb.instance.searchCache(
        query: query,
        userLat: lat,
        userLon: lon,
      );
      final names = fallback.map((r) => r['display_name'] as String).toList();
      locations.assignAll(names);
      return names;
    } finally {
      isLoading.value = false;
    }
  }

  /// Primary search: Photon (Komoot) — excellent street/POI autocomplete.
  /// Falls back to Nominatim if Photon fails.
  Future<List<Map<String, dynamic>>> _fetchFromPhoton(
    String query, {
    String? countryCode,
    int limit = 15,
    double? lat,
    double? lon,
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'limit': '$limit',
        'lang': 'en',
      };

      // Location bias — Photon natively supports this
      if (lat != null && lon != null) {
        params['lat'] = '$lat';
        params['lon'] = '$lon';
      }

      final url = Uri.https(
        ApiConstants.photonSearchDomain,
        ApiConstants.photonSearchPath,
        params,
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'locami-app'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? [];

        return features
            .map<Map<String, dynamic>>((f) {
              final props = f['properties'] ?? {};
              final coords = f['geometry']?['coordinates'] as List?;

              // Filter by country if specified
              final itemCountry =
                  (props['country'] ?? '').toString().toLowerCase();
              final countryName = _countryCodeToName(countryCode);
              if (countryCode != null &&
                  countryName != null &&
                  itemCountry.isNotEmpty &&
                  !itemCountry.contains(countryName)) {
                return <String, dynamic>{};
              }

              return {
                'display_name': _formatPhotonResult(props),
                'latitude':
                    coords != null && coords.length >= 2
                        ? (coords[1] as num).toDouble()
                        : null,
                'longitude':
                    coords != null && coords.length >= 2
                        ? (coords[0] as num).toDouble()
                        : null,
              };
            })
            .where(
              (r) =>
                  r.isNotEmpty &&
                  r['display_name'] != null &&
                  (r['display_name'] as String).isNotEmpty,
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Photon search error: $e');
    }

    // Fallback to Nominatim
    return _fetchFromNominatim(
      query,
      countryCode: countryCode,
      limit: limit,
      lat: lat,
      lon: lon,
    );
  }

  /// Fallback: Nominatim search
  Future<List<Map<String, dynamic>>> _fetchFromNominatim(
    String query, {
    String? countryCode,
    int limit = 15,
    double? lat,
    double? lon,
  }) async {
    final params = {
      'q': query,
      'format': 'json',
      'limit': '$limit',
      'addressdetails': '1',
      'accept-language': 'en',
    };

    if (countryCode != null && countryCode.isNotEmpty) {
      params['countrycodes'] = countryCode;
    }

    if (lat != null && lon != null) {
      params['viewbox'] = '${lon - 0.5},${lat + 0.5},${lon + 0.5},${lat - 0.5}';
      params['bounded'] = '0';
    }

    final url = Uri.https(
      ApiConstants.nominatimDomain,
      ApiConstants.nominatimSearchPath,
      params,
    );

    final response = await http
        .get(url, headers: {'User-Agent': 'locami-app'})
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map<Map<String, dynamic>>(
            (e) => {
              'display_name': _formatDisplayName(e),
              'latitude': double.tryParse(e['lat']?.toString() ?? ''),
              'longitude': double.tryParse(e['lon']?.toString() ?? ''),
            },
          )
          .toList();
    }

    return [];
  }

  /// Format Photon result into a readable address
  String _formatPhotonResult(Map props) {
    final name = props['name']?.toString() ?? '';
    final street = props['street']?.toString() ?? '';
    final city =
        props['city']?.toString() ??
        props['town']?.toString() ??
        props['village']?.toString() ??
        '';
    final state = props['state']?.toString() ?? '';

    final parts = <String>[];

    if (name.isNotEmpty) parts.add(name);
    if (street.isNotEmpty && street != name) parts.add(street);
    if (city.isNotEmpty && city != name) parts.add(city);
    if (parts.isEmpty && state.isNotEmpty) parts.add(state);

    if (parts.isEmpty) return props['name']?.toString() ?? '';
    return parts.take(3).join(', ');
  }

  /// Simple country code to name mapping for filtering
  String? _countryCodeToName(String? code) {
    if (code == null) return null;
    const map = {
      'IN': 'india',
      'US': 'united states',
      'GB': 'united kingdom',
      'AE': 'united arab emirates',
      'SA': 'saudi arabia',
      'QA': 'qatar',
      'SG': 'singapore',
      'MY': 'malaysia',
      'AU': 'australia',
      'CA': 'canada',
      'DE': 'germany',
      'FR': 'france',
    };
    return map[code.toUpperCase()];
  }

  Future<Map<String, double>?> getCoordinates(String query) async {
    final AppStatus appStatus = await AppStatusManager.instance.status;
    final bool isOnline = appStatus.isInternetOn;

    // ── Step 1: Check Local Cache FIRST (especially if offline) ──
    try {
      final cached = await LocationCacheDb.instance.searchCache(
        query: query,
        limit: 1,
      );
      if (cached.isNotEmpty) {
        final double? lat = cached[0]['latitude'] as double?;
        final double? lon = cached[0]['longitude'] as double?;
        if (lat != null && lon != null) {
          debugPrint("GEO: Found in cache: $query");
          return {'lat': lat, 'lon': lon};
        }
      }
    } catch (_) {}

    if (!isOnline) {
      debugPrint("GEO: Offline and not in cache, skipping network...");
      return null;
    }

    // Try Photon first (faster, better autocomplete)
    try {
      final url = Uri.https(
        ApiConstants.photonSearchDomain,
        ApiConstants.photonSearchPath,
        {'q': query, 'limit': '1', 'lang': 'en'},
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'locami-app'})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          final coords = features[0]['geometry']?['coordinates'] as List?;
          if (coords != null && coords.length >= 2) {
            return {
              'lat': (coords[1] as num).toDouble(),
              'lon': (coords[0] as num).toDouble(),
            };
          }
        }
      }
    } catch (_) {}

    // Fallback to Nominatim
    final params = {
      'q': query,
      'format': 'json',
      'limit': '1',
      'accept-language': 'en',
    };

    final url = Uri.https(
      ApiConstants.nominatimDomain,
      ApiConstants.nominatimSearchPath,
      params,
    );

    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'locami-app'})
          .timeout(const Duration(seconds: 3));

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

  /// Cache a user-selected destination (bumps hit_count for ranking).
  Future<void> cacheSelectedLocation(
    String displayName, {
    double? lat,
    double? lon,
  }) async {
    await LocationCacheDb.instance.cacheLocation(
      displayName: displayName,
      searchQuery: displayName.toLowerCase(),
      latitude: lat,
      longitude: lon,
    );
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
