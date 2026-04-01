import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/geo_location_manager/street_manager.dart';
import 'package:locami/db_manager/user_model_manager.dart';
import 'package:locami/core/db_helper/saved_location_db.dart';
import 'package:locami/core/db_helper/location_cache_db.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:locami/screens/widgets/arrival_alert.dart';
import 'package:vibration/vibration.dart';
import 'package:locami/core/utils/trip_simulator.dart';
import 'package:locami/core/utils/routing_service.dart';
import 'package:locami/core/utils/optimized_route_renderer.dart';
import 'package:locami/core/utils/route_lod_manager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:locami/core/utils/location_utils.dart';
import 'package:locami/core/utils/map_cache_manager.dart';
import 'package:locami/db_manager/app_status_manager.dart';
import 'package:locami/core/utils/background_service.dart';

class HomeController extends GetxController {
  final fromController = TextEditingController();
  final toController = TextEditingController();

  final userCountry = 'India'.obs;
  final isTracking = false.obs;
  final isTrackingLoading = false.obs;
  final currentPosition = Rx<Position?>(null);
  final initialPosition = Rx<LatLng?>(null);
  final showLocami = true.obs;
  final alertDistance = 500.obs;
  final isInitialized = false.obs;
  final initStatus = 'Starting up...'.obs;
  final locations = <String>[].obs;
  final fromAddress = "".obs;
  final toAddress = "".obs;
  final destinationLatitude = Rx<double?>(null);
  final destinationLongitude = Rx<double?>(null);
  final currentRoute = <LatLng>[].obs;
  final fetchedAlternatives = <SingleRoute>[].obs;
  final traveledRouteIndex = 0.obs;
  final useSatelliteMap = false.obs;
  final isMapDark = false.obs;
  final currentLocationName = "Locating...".obs;
  final isPinSelectionMode = false.obs;
  final currentHeading = 0.0.obs;
  final smoothedSpeed = 0.0.obs; // m/s, smoothed
  final savedLocations = <SavedLocation>[].obs;
  final isDestinationSaved = false.obs;
  final bearingToDestination = 0.0.obs;
  final mapRotation = 0.0.obs;
  final isDestinationInView = true.obs;
  final isOnline = true.obs;

  StreamSubscription<Position>? _positionSubscription;
  Position? _previousPosition;
  DateTime? _previousTimestamp;
  Position? _lastPreloadPosition;
  final List<double> _speedBuffer = [];
  Timer? _transmissionTimer;
  Timer? _simulationTimer;
  Timer? _geocodeTimer;
  Timer? _destTrackingTimer;
  StreamSubscription? _mapEventSubscription;
  bool _isGeocodingInProgress = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final mapController = fm.MapController();
  bool _isAlertShown = false;
  
  // Optimized route rendering system
  OptimizedRouteRenderer? _routeRenderer;
  double _currentMapZoom = 5.0;

  @override
  void onInit() {
    super.onInit();
    // NOTE: TripDetailsManager.init() is deferred to _initAsync() to avoid blocking first frame
    fromAddress.value = fromController.text;
    toAddress.value = toController.text;

    fromController.addListener(() {
      fromAddress.value = fromController.text;
      update();
    });
    toController.addListener(() {
      toAddress.value = toController.text;
      update();
    });

    TripDetailsManager.instance.isTrackingNotifier.addListener(
      _onTrackingStatusChanged,
    );
    TripDetailsManager.instance.alertTriggeredNotifier.addListener(
      _onAlertTriggered,
    );
    TripDetailsManager.instance.currentTripDetail.addListener(_onTripDetailUpdate);

    // Initialize optimized route renderer
    _routeRenderer = OptimizedRouteRenderer(
      onRouteUpdated: (optimizedPoints) {
        // Update route on UI thread without full rebuild
        currentRoute.assignAll(optimizedPoints);
      },
      onRenderComplete: () {
        debugPrint('Route rendering complete with ${currentRoute.length} points');
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAsync();
    });

    // Re-fetch route when internet is back
    AppStatusManager.instance.isOnlineNotifier.addListener(() {
      final bool nowOnline = AppStatusManager.instance.isOnlineNotifier.value;
      
      // If we just got internet back and have a destination, definitively refetch
      if (nowOnline && !isOnline.value && destinationLatitude.value != null) {
        if (currentPosition.value != null) {
           _updateRouteIfNeeded(currentPosition.value!, force: true);
        }
      }
      isOnline.value = nowOnline;
    });

    isOnline.value = AppStatusManager.instance.isOnlineNotifier.value;
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();
    _previousPosition = null;
    _previousTimestamp = null;
    _speedBuffer.clear();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(
      (position) {
        currentPosition.value = position;
        final now = DateTime.now();
        double candidateSpeed = 0.0;
        if (position.speed >= 1.0) {
          candidateSpeed = position.speed;
        }
        candidateSpeed = LocationUtils.calculateSmoothedSpeed(
          currentPos: position,
          now: now,
          previousPos: _previousPosition,
          previousTime: _previousTimestamp,
          currentSpeedBufferAvg:
              _speedBuffer.isEmpty
                  ? 0
                  : _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length,
          candidateSpeed: candidateSpeed,
        );
        _speedBuffer.add(candidateSpeed);
        if (_speedBuffer.length > 8) _speedBuffer.removeAt(0);
        final avgSpeed = _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;
        smoothedSpeed.value = avgSpeed < 1.0 ? 0.0 : avgSpeed;
        currentHeading.value = LocationUtils.calculateResponsiveBearing(
          currentPos: position,
          previousPos: _previousPosition,
          currentHeading: currentHeading.value,
          smoothedSpeed: smoothedSpeed.value,
        );
        _previousPosition = position;
        _previousTimestamp = now;
        _updateTraveledIndex(position);
        _geocodeTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
          _updateLocationName();
        });
        if (destinationLatitude.value != null && destinationLongitude.value != null) {
          _updateRouteIfNeeded(position);
        }
        _checkAndPreloadMap(position);
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  Future<void> _updateLocationName() async {
    if (_isGeocodingInProgress) return;
    final pos = currentPosition.value;
    if (pos == null) return;
    _isGeocodingInProgress = true;
    try {
      final details = await StreetManager.instance.getLocationDetailsAt(
        pos.latitude,
        pos.longitude,
      );
      if (details != null && details['address'] != null) {
        currentLocationName.value = _formatAddressToTwoCommas(details['address']!);
      }
    } finally {
      _isGeocodingInProgress = false;
    }
  }

  String _formatAddressToTwoCommas(String address) {
    final parts = address.split(',');
    if (parts.length <= 2) return address.trim();
    return "${parts[0].trim()}, ${parts[1].trim()}";
  }

  Future<void> _updateRouteIfNeeded(Position current, {bool force = false}) async {
    if (destinationLatitude.value == null || destinationLongitude.value == null) return;
    final dest = LatLng(destinationLatitude.value!, destinationLongitude.value!);
    final start = LatLng(current.latitude, current.longitude);
    
    // 1. Check if we are still on the active route
    bool onCurrentRoute = false;
    if (!force && currentRoute.isNotEmpty) {
      int bestIdx = traveledRouteIndex.value;
      int maxCheck = (bestIdx + 30 < currentRoute.length) ? bestIdx + 30 : currentRoute.length;
      double minD = double.infinity;
      for (int i = bestIdx; i < maxCheck; i++) {
         final d = Geolocator.distanceBetween(start.latitude, start.longitude, currentRoute[i].latitude, currentRoute[i].longitude);
         if (d < minD) minD = d;
      }
      if (minD < 50) {
         onCurrentRoute = true;
      }
    }

    if (onCurrentRoute && !force) {
       return; // Perfectly on track, keep slicing grey tail
    }

    // 2. See if we can slice an off-the-shelf alternative from our fetched cache
    bool nearExisting = false;
    if (!force && fetchedAlternatives.isNotEmpty) {
      final sliced = _getSlicedAlternative(start, dest, fetchedAlternatives);
      if (sliced != null) {
        currentRoute.assignAll(sliced);
        traveledRouteIndex.value = 0;
        nearExisting = true;
      }
    }

    // 3. Fallback to network or DB routing if no slice matched
    if (currentRoute.isEmpty || force || (!onCurrentRoute && !nearExisting)) {
      // Use optimized route renderer for smooth rendering
      final routeData = await RoutingService.instance.getRoute(
        start, dest, 
        destinationName: toAddress.value,
        simplifyLongRoutes: true,
        maxPoints: 2000, // Limit points to prevent UI freeze
      );
      
      if (routeData.alternatives.isNotEmpty) {
          fetchedAlternatives.assignAll(routeData.alternatives);
      }
      
      final sliced = _getSlicedAlternative(start, dest, routeData.alternatives);
      List<LatLng> routePoints;
      
      if (sliced != null) {
        routePoints = sliced;
      } else {
        routePoints = routeData.points;
      }
      
      // Use optimized renderer for progressive, LOD-aware rendering
      if (_routeRenderer != null) {
        await _routeRenderer!.setRoute(routePoints, immediate: force);
      } else {
        currentRoute.assignAll(routePoints);
      }
      
      traveledRouteIndex.value = 0;
      
      // PRELOAD: If online, background cache the main route's tiles
      if (isOnline.value && currentRoute.isNotEmpty) {
        MapCacheManager.instance.preloadRouteTiles(currentRoute.toList());
      }
    }
  }

  void _updateTraveledIndex(Position position) {
    if (currentRoute.isEmpty) return;
    
    int bestIndex = traveledRouteIndex.value;
    double minDistance = double.infinity;
    
    int maxCheck = (bestIndex + 50 < currentRoute.length) ? bestIndex + 50 : currentRoute.length;
    for (int i = bestIndex; i < maxCheck; i++) {
        final point = currentRoute[i];
        final dist = Geolocator.distanceBetween(position.latitude, position.longitude, point.latitude, point.longitude);
        if (dist < minDistance) {
           minDistance = dist;
           bestIndex = i;
        }
    }
    
    if (bestIndex > traveledRouteIndex.value && minDistance < 150) {
       traveledRouteIndex.value = bestIndex;
    }
  }

  List<LatLng>? _getSlicedAlternative(LatLng start, LatLng dest, List<SingleRoute> routes) {
    for (var route in routes) {
      if (route.points.isEmpty) continue;
      
      int startIdx = -1;
      int destIdx = -1;
      double minStartDist = double.infinity;
      double minDestDist = double.infinity;
      
      for (int i = 0; i < route.points.length; i++) {
        final dist = Geolocator.distanceBetween(
          start.latitude, start.longitude,
          route.points[i].latitude, route.points[i].longitude,
        );
        if (dist < minStartDist && dist < 120) {
          minStartDist = dist;
          startIdx = i;
        }
      }
      
      if (startIdx != -1) {
        for (int i = startIdx; i < route.points.length; i++) {
          final dist = Geolocator.distanceBetween(
            dest.latitude, dest.longitude,
            route.points[i].latitude, route.points[i].longitude,
          );
          if (dist < minDestDist && dist < 250) { // More tolerance for destination
            minDestDist = dist;
            destIdx = i;
          }
        }
      }
      
      // Found both on the same route!
      if (startIdx != -1 && destIdx != -1 && destIdx >= startIdx) {
        return route.points.sublist(startIdx, destIdx + 1);
      }
    }
    return null;
  }

  Future<void> reInitialize() async {
    isInitialized.value = false;
    currentRoute.clear();
    fetchedAlternatives.clear();
    traveledRouteIndex.value = 0;
    destinationLatitude.value = null;
    destinationLongitude.value = null;
    isTracking.value = false;
    fromController.clear();
    toController.clear();
    _lastPreloadPosition = null;
    await _initAsync();
  }

  Future<void> _initAsync() async {
    try {
      // Deferred heavy init — runs after first frame so no frame drops
      debugPrint('INIT_TRACE: Initializing background service');
      initStatus.value = 'Preparing...';
      await initializeService();
      await Future.delayed(Duration.zero); // Yield to let frame render

      // Init trip manager (was in onInit, moved here to avoid blocking first frame)
      TripDetailsManager.instance.init();
      await Future.delayed(Duration.zero); // Yield

      debugPrint('INIT_TRACE: Starting Permission Check');
      initStatus.value = 'Checking GPS...';
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        initStatus.value = 'GPS is disabled';
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
             debugPrint('INIT_TRACE: GPS still disabled, proceeding anyway');
        }
      }
      
      debugPrint('INIT_TRACE: Requesting Location Permission');
      initStatus.value = 'Checking Permissions...';
      final permissionGranted = await _requestLocationPermission();
      if (!permissionGranted) {
        initStatus.value = 'Permission needed';
        debugPrint('INIT_TRACE: Permission not granted, but proceeding');
      }
      
      debugPrint('INIT_TRACE: Fetching Last Known Position');
      // 1. Get last known location immediately if available
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          currentPosition.value = lastKnown;
          initialPosition.value = LatLng(lastKnown.latitude, lastKnown.longitude);
        }
      } catch (_) {}

      // 2. Start location updates in background
      _startLocationStream();

      // 3. Parallelize data loading to reduce wait time
      debugPrint('INIT_TRACE: Starting Parallel Data Load');
      initStatus.value = 'Preparing Data...';
      await Future.wait([
        // If we don't have a location, give GPS 3 seconds to find one
        if (currentPosition.value == null)
          getInitialLocation().timeout(const Duration(seconds: 3)).catchError((e) {
            debugPrint('INIT_TRACE: getInitialLocation timed out or failed: $e');
            return null;
          }),
        
        // Critical data
        checkTrackingStatus().timeout(const Duration(seconds: 3)).catchError((e) {
            debugPrint('INIT_TRACE: checkTrackingStatus timed out or failed: $e');
            return null;
        }),
        loadUserCountryFromProfile().timeout(const Duration(seconds: 2)).catchError((e) {
            debugPrint('INIT_TRACE: loadUserCountry timed out or failed: $e');
            return null;
        }),
        loadSavedLocations().timeout(const Duration(seconds: 2)).catchError((e) {
            debugPrint('INIT_TRACE: loadSavedLocations timed out or failed: $e');
            return null;
        }),
      ]).timeout(const Duration(seconds: 10), onTimeout: () {
         debugPrint('INIT_TRACE: Future.wait global timeout hit!');
         return [];
      });
      
      debugPrint('INIT_TRACE: Initialization almost complete');
      // 4. Non-critical data (background)
      loadNearbyStreets();
      if (isOnline.value) {
        MapCacheManager.instance.preloadWorldMap();
      }
      if (currentPosition.value != null) {
        _preloadAsync(currentPosition.value!);
      }

      // 5. Ready to show map
      initStatus.value = 'Ready';
      isInitialized.value = true;
      
      // Listen to map events (rotation, etc.)
      _listenToMapEvents();
      
    } catch (e) {
      debugPrint('Init error: $e');
      initStatus.value = 'Error: $e';
      await Future.delayed(const Duration(seconds: 1));
      isInitialized.value = true;
    }
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      initStatus.value = 'Location permanently denied.\nPlease enable in Settings.';
      await Geolocator.openAppSettings();
      return false;
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  @override
  void onClose() {
    fromController.dispose();
    toController.dispose();
    _transmissionTimer?.cancel();
    _simulationTimer?.cancel();
    _geocodeTimer?.cancel();
    _destTrackingTimer?.cancel();
    _mapEventSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
    _routeRenderer?.dispose();
    TripDetailsManager.instance.isTrackingNotifier.removeListener(_onTrackingStatusChanged);
    TripDetailsManager.instance.alertTriggeredNotifier.removeListener(_onAlertTriggered);
    super.onClose();
  }

  void _onAlertTriggered() {
    final distance = TripDetailsManager.instance.alertTriggeredNotifier.value;
    if (distance != null) {
      showArrivalAlert(distance);
    }
  }

  void showArrivalAlert(double distance) {
    if (_isAlertShown) return;
    _isAlertShown = true; 
    
    // UI popup only. Sound is handled fully by the background isolate now.
    try {
      Get.dialog(
        ArrivalAlert(
          destination: toAddress.value,
          onDone: () {
            Get.back(); // close popup first
            toggleTracking(); // ends tracking and clears dest
            stopAllSounds();
          },
          onThanks: () {
            Get.back(); // snooze/dismiss popup
            stopAllSounds(); // stop sounds, trip remains active
          },
        ),
        barrierDismissible: false,
        useSafeArea: false,
      );
    } catch (_) {}
  }

  void stopAllSounds() {
    FlutterRingtonePlayer().stop();
    _audioPlayer.stop();
    Vibration.cancel();
    TripDetailsManager.instance.stopAlertSound();
    FlutterBackgroundService().invoke('stop_alarm');
  }

  Future<void> loadSavedLocations() async {
    try {
      final locs = await SavedLocationDb.instance.getAll();
      savedLocations.assignAll(locs);
    } catch (e) {
      debugPrint('Error loading saved locations: $e');
    }
  }

  Future<SavedLocation?> saveTaggedLocation({
    required String label,
    required String displayName,
    required double latitude,
    required double longitude,
    String icon = 'place',
  }) async {
    try {
      final id = await SavedLocationDb.instance.saveLocation(
        label: label, displayName: displayName,
        latitude: latitude, longitude: longitude, icon: icon,
      );
      await LocationCacheDb.instance.cacheLocation(
        displayName: displayName, searchQuery: label.toLowerCase(),
        latitude: latitude, longitude: longitude,
      );
      await loadSavedLocations();
      return SavedLocation(
        id: id, label: label, displayName: displayName,
        latitude: latitude, longitude: longitude, icon: icon,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error saving tagged location: $e');
      return null;
    }
  }

  Future<void> deleteSavedLocation(int id) async {
    await SavedLocationDb.instance.deleteLocation(id);
    await loadSavedLocations();
  }

  void startTrackingToSaved(SavedLocation loc) {
    toController.text = loc.displayName;
    toAddress.value = loc.displayName;
    destinationLatitude.value = loc.latitude;
    destinationLongitude.value = loc.longitude;
    currentRoute.clear();
    isDestinationSaved.value = true;
    if (currentPosition.value != null) {
      final midLat = (currentPosition.value!.latitude + loc.latitude) / 2;
      final midLon = (currentPosition.value!.longitude + loc.longitude) / 2;
      centerMap(midLat, midLon, 12.0);
    } else {
      centerMap(loc.latitude, loc.longitude, 15.0);
    }
  }

  void _onTrackingStatusChanged() {
    final isTrackingNow = TripDetailsManager.instance.isTracking;
    if (isTracking.value != isTrackingNow) {
      isTracking.value = isTrackingNow;
      if (isTracking.value) {
        startTransmission();
        startSimulation();
      } else {
        stopTransmission();
        stopSimulation();
      }
    }
  }

  Future<void> getInitialLocation() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && currentPosition.value == null) {
        currentPosition.value = lastKnown;
        initialPosition.value ??= LatLng(lastKnown.latitude, lastKnown.longitude);
      }
      final accurate = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      currentPosition.value = accurate;
      initialPosition.value ??= LatLng(accurate.latitude, accurate.longitude);
      final details = await StreetManager.instance.getLocationDetailsAt(accurate.latitude, accurate.longitude);
      if (details != null && details['address'] != null) {
        currentLocationName.value = _formatAddressToTwoCommas(details['address']!);
      }
    } catch (_) {}
  }

  void toggleMapStyle() {
    useSatelliteMap.value = !useSatelliteMap.value;
  }

  Future<void> checkTrackingStatus() async {
    final user = await UserModelManager.instance.user;
    if (user.isTravelStarted) {
      isTracking.value = true;
      if (user.fromStreet != null && user.fromStreet!.isNotEmpty) {
        fromController.text = user.fromStreet!;
        fromAddress.value = user.fromStreet!;
      }
      if (user.destinationStreet != null && user.destinationStreet!.isNotEmpty) {
        toController.text = user.destinationStreet!;
        toAddress.value = user.destinationStreet!;
      }
      destinationLatitude.value = user.destinationLatitude;
      destinationLongitude.value = user.destinationLongitude;
      if (user.alertDistance != null) {
        alertDistance.value = user.alertDistance!.toInt();
      }
      startTransmission();
      startSimulation();
      if (currentPosition.value != null && destinationLatitude.value != null) {
        _updateRouteIfNeeded(currentPosition.value!, force: true);
      }
      if (user.isAlarmActive) showArrivalAlert(user.alertDistance ?? 0.0);
      _startDestTrackingTimer();
    }
  }

  void _onTripDetailUpdate() {
    final detail = TripDetailsManager.instance.currentTripDetail.value;
    if (detail != null) {
      final pos = Position(
        latitude: detail.latitude,
        longitude: detail.longitude,
        timestamp: detail.timestamp,
        accuracy: detail.accuracy,
        altitude: detail.altitude,
        heading: detail.heading,
        speed: detail.speed,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
      
      // Update UI observables
      currentPosition.value = pos;
      smoothedSpeed.value = detail.speed;
      currentHeading.value = detail.heading;
      
      // Calculate bearing to destination if needed
      if (destinationLatitude.value != null && destinationLongitude.value != null) {
        bearingToDestination.value = Geolocator.bearingBetween(
          pos.latitude, pos.longitude,
          destinationLatitude.value!, destinationLongitude.value!,
        );
      }
      
      _checkAndPreloadMap(pos);
    }
  }

  Future<void> _preloadAsync(Position pos) async {
    try {
      _lastPreloadPosition = pos;
      await MapCacheManager.instance.preloadSurroundingMap(
        pos.latitude,
        pos.longitude,
        isDark: isMapDark.value,
        isSatellite: useSatelliteMap.value,
      );
    } catch (e) {
      debugPrint('Map preload error: $e');
    }
  }

  void _checkAndPreloadMap(Position pos) {
    if (_lastPreloadPosition == null) {
      _preloadAsync(pos);
      return;
    }

    final distance = Geolocator.distanceBetween(
      _lastPreloadPosition!.latitude,
      _lastPreloadPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );

    // If moved more than 3km from last preload center, preload again.
    if (distance > 3000) {
      _preloadAsync(pos);
    }
  }

  void startTransmission() {
    _transmissionTimer?.cancel();
    _transmissionTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (isTracking.value) showLocami.value = !showLocami.value;
      else stopTransmission();
    });
  }

  void stopTransmission() {
    _transmissionTimer?.cancel();
    showLocami.value = true;
  }

  void startSimulation() {
    // We now let the background service handle the simulation timer
    // to ensure it works consistently in both forground and background.
    // We only need to tell it to start if enabled in settings.
    FlutterBackgroundService().invoke(
      'set_simulation_mode', 
      {'enabled': ThemeProvider.instance.enableSimulation}
    );
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    FlutterBackgroundService().invoke('set_simulation_mode', {'enabled': false});
  }

  Future<void> loadNearbyStreets() async {
    final result = await StreetManager.instance.getNearbyStreets();
    locations.assignAll(result);
  }

  Future<void> loadUserCountryFromProfile() async {
    final user = await UserModelManager.instance.user;
    userCountry.value = user.country.isNotEmpty ? user.country : 'in';
  }

  Future<void> toggleTracking() async {
    if (isTrackingLoading.value) return;
    isTrackingLoading.value = true;
    if (isTracking.value) {
      try {
        await TripDetailsManager.instance.stopTracking();
        isTracking.value = false;
        _destTrackingTimer?.cancel();
        _destTrackingTimer = null;
        destinationLatitude.value = null;
        destinationLongitude.value = null;
        toAddress.value = "";
        toController.clear();
        currentRoute.clear();
        stopTransmission();
      } catch (e) {
        Get.snackbar('Error', 'Error stopping tracking: $e');
      } finally {
        isTrackingLoading.value = false;
      }
    } else {
      try {
        _isAlertShown = false;
        await UserModelManager.instance.patchUser(
          fromStreet: fromController.text,
          destinationStreet: toController.text,
          destinationLatitude: destinationLatitude.value,
          destinationLongitude: destinationLongitude.value,
        );
        await TripDetailsManager.instance.startTracking(alertDistance: alertDistance.value.toDouble());
        isTracking.value = true;
        _startDestTrackingTimer();
        startSimulation();
      } catch (e) {
        Get.snackbar('Error', 'Error starting tracking: $e');
      } finally {
        isTrackingLoading.value = false;
      }
    }
  }

  bool validateIsTracking() => toAddress.value.isNotEmpty && destinationLatitude.value != null;

  void setAlertDistance(int distance) {
    if (!isTracking.value) alertDistance.value = distance;
  }

  Future<void> setNearbyTestLocation() async {
    final position = currentPosition.value ?? await Geolocator.getCurrentPosition();
    currentPosition.value = position;
    final double distanceInMeters = alertDistance.value.toDouble() + 2.0;
    final double deltaLat = distanceInMeters / 111111.0;
    destinationLatitude.value = position.latitude + deltaLat;
    destinationLongitude.value = position.longitude;
    toAddress.value = "Test Destination (Nearby)";
    toController.text = "Test Destination (Nearby)";
    centerMap(destinationLatitude.value!, destinationLongitude.value!);
    update();
  }

  void centerMap(double lat, double lon, [double zoom = 14.0]) {
    try {
      mapController.move(LatLng(lat, lon), zoom);
    } catch (e) {
      debugPrint("Error moving map: $e");
    }
  }


  void animatedMapMove(double targetLat, double targetLon, double targetZoom) {
    try {
      final startLat = mapController.camera.center.latitude;
      final startLon = mapController.camera.center.longitude;
      final startZoom = mapController.camera.zoom;
      const steps = 40;
      const duration = Duration(milliseconds: 1200);
      final stepDuration = Duration(microseconds: duration.inMicroseconds ~/ steps);
      int step = 0;
      Timer.periodic(stepDuration, (timer) {
        step++;
        final t = step / steps;
        final ease = t * t * (3 - 2 * t);
        final lat = startLat + (targetLat - startLat) * ease;
        final lon = startLon + (targetLon - startLon) * ease;
        final zoom = startZoom + (targetZoom - startZoom) * ease;
        try {
          mapController.move(LatLng(lat, lon), zoom);
        } catch (_) {}
        if (step >= steps) timer.cancel();
      });
    } catch (_) {
      centerMap(targetLat, targetLon, targetZoom);
    }
  }

  void clearDestination() {
    toController.clear();
    toAddress.value = '';
    destinationLatitude.value = null;
    destinationLongitude.value = null;
    currentRoute.clear();
    traveledRouteIndex.value = 0;
    isDestinationSaved.value = false;
  }

  Future<void> selectDestination(String address, {double? lat, double? lon}) async {
    toController.text = address;
    toAddress.value = address;
    currentRoute.clear();

    if (lat != null && lon != null) {
      destinationLatitude.value = lat;
      destinationLongitude.value = lon;
    } else {
      final coords = await StreetManager.instance.getCoordinates(address);
      if (coords != null) {
        destinationLatitude.value = coords['lat'];
        destinationLongitude.value = coords['lon'];
      }
    }

    if (destinationLatitude.value != null && destinationLongitude.value != null) {
      centerMap(destinationLatitude.value!, destinationLongitude.value!);
      if (currentPosition.value != null) _updateRouteIfNeeded(currentPosition.value!);
      _checkIfDestinationSaved();
    }
    update();
  }

  Future<void> _checkIfDestinationSaved() async {
    if (destinationLatitude.value == null) {
      isDestinationSaved.value = false;
      return;
    }
    final saved = await SavedLocationDb.instance.findByCoordinates(destinationLatitude.value!, destinationLongitude.value!);
    isDestinationSaved.value = saved != null;
  }

  Future<void> setDestinationFromCoords(LatLng coords) async {
    if (isTracking.value) return;
    destinationLatitude.value = coords.latitude;
    destinationLongitude.value = coords.longitude;
    currentRoute.clear();
    traveledRouteIndex.value = 0;
    centerMap(coords.latitude, coords.longitude);
    final details = await StreetManager.instance.getLocationDetailsAt(coords.latitude, coords.longitude);
    if (details != null && details['address'] != null) {
      final String address = details['address']!;
      toAddress.value = address;
      toController.text = address;
    } else {
      toAddress.value = "${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}";
      toController.text = toAddress.value;
    }
    if (currentPosition.value != null) _updateRouteIfNeeded(currentPosition.value!);
    _checkIfDestinationSaved();
    update();
  }

  void focusCurrentLocation() {
    final pos = currentPosition.value;
    if (pos != null) {
      animatedMapMove(pos.latitude, pos.longitude, 16.0);
    } else {
      getInitialLocation();
    }
  }

  void selectCenterLocation() {
    if (isTracking.value) return;
    try {
      final center = mapController.camera.center;
      setDestinationFromCoords(center);
    } catch (_) {}
  }

  void _startDestTrackingTimer() {
    _destTrackingTimer?.cancel();
    _destTrackingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _updateDestStatus());
  }

  void _updateDestStatus() {
    if (destinationLatitude.value == null) return;
    try {
      final camera = mapController.camera;
      final center = camera.center;
      final dest = LatLng(destinationLatitude.value!, destinationLongitude.value!);
      bearingToDestination.value = Geolocator.bearingBetween(center.latitude, center.longitude, dest.latitude, dest.longitude);
      isDestinationInView.value = camera.visibleBounds.contains(dest);
    } catch (_) {}
  }

  void _listenToMapEvents() {
    _mapEventSubscription?.cancel();
    _mapEventSubscription = mapController.mapEventStream.listen((event) {
      mapRotation.value = mapController.camera.rotation;
      
      // Update LOD based on zoom level for optimized rendering
      final newZoom = mapController.camera.zoom;
      if ((_currentMapZoom - newZoom).abs() > 0.5) {
        _currentMapZoom = newZoom;
        _routeRenderer?.updateZoom(newZoom);
      }
      
      if (isTracking.value) _updateDestStatus();
    });
  }

  void animateToDestination() {
    if (destinationLatitude.value == null) return;
    animatedMapMove(destinationLatitude.value!, destinationLongitude.value!, 14.5);
  }

  void toggleMapTheme() {
    isMapDark.value = !isMapDark.value;
    update();
  }
}
