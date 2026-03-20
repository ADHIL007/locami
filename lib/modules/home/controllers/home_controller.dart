import 'dart:async';
import 'dart:math' as math;
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
import 'package:locami/core/utils/trip_simulator.dart';
import 'package:locami/core/utils/routing_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:locami/core/utils/location_utils.dart';
import 'package:locami/core/utils/map_cache_manager.dart';

class HomeController extends GetxController {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  
  final userCountry = 'India'.obs;
  final isTracking = false.obs;
  final isTrackingLoading = false.obs;
  final currentPosition = Rx<Position?>(null);
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
  final useSatelliteMap = false.obs;
  final isMapDark = true.obs;
  final currentLocationName = "Locating...".obs;
  final isPinSelectionMode = false.obs;
  final currentHeading = 0.0.obs;
  final smoothedSpeed = 0.0.obs; // m/s, smoothed
  final savedLocations = <SavedLocation>[].obs;

  StreamSubscription<Position>? _positionSubscription;
  Position? _previousPosition;
  DateTime? _previousTimestamp;
  Position? _lastPreloadPosition;
  final List<double> _speedBuffer = [];
  Timer? _transmissionTimer;
  Timer? _simulationTimer;
  Timer? _geocodeTimer;
  bool _isGeocodingInProgress = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final mapController = fm.MapController();

  @override
  void onInit() {
    super.onInit();
    TripDetailsManager.instance.init();
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

    TripDetailsManager.instance.isTrackingNotifier.addListener(_onTrackingStatusChanged);
    TripDetailsManager.instance.alertTriggeredNotifier.addListener(_onAlertTriggered);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAsync();
    });
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((position) {
      // ── INSTANT: Update position (triggers UI rebuild immediately) ──
      currentPosition.value = position;

      // ── INSTANT: Speed Calculation (smoothed) ──
      final now = DateTime.now();
      double candidateSpeed = 0.0;

      // Only trust GPS speed if it's clearly above noise floor
      if (position.speed >= 1.0) {
        candidateSpeed = position.speed;
      }

      // Cross-check with distance-based speed if we have a previous position
      candidateSpeed = LocationUtils.calculateSmoothedSpeed(
        currentPos: position,
        now: now,
        previousPos: _previousPosition,
        previousTime: _previousTimestamp,
        currentSpeedBufferAvg: _speedBuffer.isEmpty ? 0 : _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length,
        candidateSpeed: candidateSpeed,
      );

      // Moving average (last 8 samples for stability)
      _speedBuffer.add(candidateSpeed);
      if (_speedBuffer.length > 8) _speedBuffer.removeAt(0);
      final avgSpeed = _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;

      // Dead-zone: under 1.0 m/s (~3.6 km/h) = stationary
      smoothedSpeed.value = avgSpeed < 1.0 ? 0.0 : avgSpeed;

      // ── INSTANT: Direction (Bearing) Calculation ──
      currentHeading.value = LocationUtils.calculateResponsiveBearing(
        currentPos: position,
        previousPos: _previousPosition,
        currentHeading: currentHeading.value,
        smoothedSpeed: smoothedSpeed.value,
      );
      _previousPosition = position;
      _previousTimestamp = now;

      // ── DEBOUNCED: Reverse Geocoding (every 3 seconds, non-blocking) ──
      _geocodeTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
        _updateLocationName();
      });

      // ── THROTTLED: Route Update (only when needed, non-blocking) ──
      if (destinationLatitude.value != null && destinationLongitude.value != null) {
        _updateRouteIfNeeded(position);
      }

      // ── MAP PRELOAD: Preload surrounding area if moved significantly (e.g. 5km) ──
      _checkAndPreloadMap(position);
    }, onError: (error) {
      debugPrint('Location stream error: $error');
    });
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

  Future<void> _updateRouteIfNeeded(Position current) async {
    if (destinationLatitude.value == null || destinationLongitude.value == null) return;
    
    final dest = LatLng(destinationLatitude.value!, destinationLongitude.value!);
    final start = LatLng(current.latitude, current.longitude);
    
    if (currentRoute.isEmpty) {
      currentRoute.assignAll(await RoutingService.instance.getRoute(start, dest));
    } else {
      final firstPoint = currentRoute.first;
      final dist = Geolocator.distanceBetween(current.latitude, current.longitude, firstPoint.latitude, firstPoint.longitude);
      if (dist > 50) {
        currentRoute.assignAll(await RoutingService.instance.getRoute(start, dest));
      }
    }
  }

  /// Full reset and re-initialization of the controller state
  Future<void> reInitialize() async {
    isInitialized.value = false;
    currentRoute.clear();
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
      // Step 1: Check location services
      initStatus.value = 'Checking location services...';
      await Future.delayed(const Duration(milliseconds: 400));

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        initStatus.value = 'Please enable Location Services';
        // Wait for user to enable location
        while (!await Geolocator.isLocationServiceEnabled()) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // Step 2: Request permissions
      initStatus.value = 'Requesting location access...';
      await Future.delayed(const Duration(milliseconds: 300));

      final permissionGranted = await _requestLocationPermission();
      if (!permissionGranted) {
        initStatus.value = 'Location permission required';
        // Keep retrying
        while (!await _requestLocationPermission()) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      // Step 3: Calibrating sensors
      initStatus.value = 'Calibrating sensors...';
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Get GPS fix
      initStatus.value = 'Acquiring GPS signal...';
      await getInitialLocation();

      // Step 5: Start stream
      initStatus.value = 'Fetching location data...';
      _startLocationStream();
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 6: Load data
      initStatus.value = 'Loading your data...';
      checkTrackingStatus();
      loadUserCountryFromProfile();
      loadSavedLocations();
      loadNearbyStreets();
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 7: Preload map cache
      initStatus.value = 'Preloading surrounding map...';
      if (currentPosition.value != null) {
        // We only await half a second to not block forever, map preloading continues in background
        _preloadAsync(currentPosition.value!);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Done!
      initStatus.value = 'Ready';
      isInitialized.value = true;

      // Animate map to current location after the map widget renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToCurrentLocation();
      });
    } catch (e) {
      debugPrint('Init error: $e');
      initStatus.value = 'Error: $e';
      // Still try to show the map
      await Future.delayed(const Duration(seconds: 2));
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
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  void onClose() {
    fromController.dispose();
    toController.dispose();
    _transmissionTimer?.cancel();
    _simulationTimer?.cancel();
    _geocodeTimer?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
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
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final themeProvider = ThemeProvider.instance;
    final soundKey = themeProvider.alertSound;
    final isCustom = themeProvider.isCustomSound;
    final customPath = themeProvider.customSoundPath;
    final loop = themeProvider.loopAlarm;

    stopAllSounds();

    if (isCustom && customPath != null) {
      _audioPlayer.play(DeviceFileSource(customPath));
      if (loop) _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } else {
      if (soundKey == 'alarm') {
        FlutterRingtonePlayer().playAlarm(looping: loop);
      } else if (soundKey == 'ringtone') {
        FlutterRingtonePlayer().playRingtone(looping: loop);
      } else {
        FlutterRingtonePlayer().playNotification(looping: loop);
      }
    }

    final destination = TripDetailsManager.instance.currentTripDetail.value?.destination ?? "Destination";

    Get.dialog(
      ArrivalAlert(
        destination: destination,
        onDone: () {
          stopAllSounds();
          Get.back();
          toggleTracking();
        },
        onThanks: () {
          stopAllSounds();
          Get.back();
        },
      ),
      barrierDismissible: false,
    ).then((_) {
      stopAllSounds();
    });
  }

  void stopAllSounds() {
    FlutterRingtonePlayer().stop();
    _audioPlayer.stop();
    TripDetailsManager.instance.stopAlertSound();
    FlutterBackgroundService().invoke('stop_alarm');
  }

  /// Load all saved/tagged locations from DB.
  Future<void> loadSavedLocations() async {
    try {
      final locs = await SavedLocationDb.instance.getAll();
      savedLocations.assignAll(locs);
    } catch (e) {
      debugPrint('Error loading saved locations: $e');
    }
  }

  /// Save current pin/destination as a tagged location.
  Future<SavedLocation?> saveTaggedLocation({
    required String label,
    required String displayName,
    required double latitude,
    required double longitude,
    String icon = 'place',
  }) async {
    try {
      final id = await SavedLocationDb.instance.saveLocation(
        label: label,
        displayName: displayName,
        latitude: latitude,
        longitude: longitude,
        icon: icon,
      );

      // Also cache in location search DB
      await LocationCacheDb.instance.cacheLocation(
        displayName: displayName,
        searchQuery: label.toLowerCase(),
        latitude: latitude,
        longitude: longitude,
      );

      await loadSavedLocations();

      final saved = SavedLocation(
        id: id,
        label: label,
        displayName: displayName,
        latitude: latitude,
        longitude: longitude,
        icon: icon,
        createdAt: DateTime.now(),
      );
      return saved;
    } catch (e) {
      debugPrint('Error saving tagged location: $e');
      return null;
    }
  }

  /// Delete a saved location.
  Future<void> deleteSavedLocation(int id) async {
    await SavedLocationDb.instance.deleteLocation(id);
    await loadSavedLocations();
  }

  /// Start tracking to a saved location.
  void startTrackingToSaved(SavedLocation loc) {
    toController.text = loc.displayName;
    toAddress.value = loc.displayName;
    destinationLatitude.value = loc.latitude;
    destinationLongitude.value = loc.longitude;
    currentRoute.clear();

    // Zoom to show both current and destination
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
      }
      final accurate = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      currentPosition.value = accurate;
      
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

      if (user.isAlarmActive) {
        showArrivalAlert(user.alertDistance ?? 0.0);
      }
    }
  }

  void startTransmission() {
    _transmissionTimer?.cancel();
    _transmissionTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (isTracking.value) {
        showLocami.value = !showLocami.value;
      } else {
        stopTransmission();
      }
    });
  }

  void stopTransmission() {
    _transmissionTimer?.cancel();
    showLocami.value = true;
  }

  void startSimulation() {
    _simulationTimer?.cancel();
    final themeProvider = ThemeProvider.instance;
    if (themeProvider.enableTimerSimulation) {
      FlutterBackgroundService().invoke('set_simulation_mode', {'enabled': true});
      _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (isTracking.value && themeProvider.enableTimerSimulation) {
          TripSimulator.simulateMoveTowards();
        } else {
          stopSimulation();
        }
      });
    }
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    FlutterBackgroundService().invoke('set_simulation_mode', {'enabled': false});
  }

  Future<void> loadNearbyStreets() async {
    final result = await StreetManager.instance.getNearbyStreets();
    locations.assignAll(result);
  }

  void loadUserCountryFromProfile() async {
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
        
        // Reset destination and clear route
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
        await UserModelManager.instance.patchUser(
          fromStreet: fromController.text,
          destinationStreet: toController.text,
          destinationLatitude: destinationLatitude.value,
          destinationLongitude: destinationLongitude.value,
        );

        await TripDetailsManager.instance.startTracking(
          alertDistance: alertDistance.value.toDouble(),
        );
        isTracking.value = true;
        startTransmission();
        startSimulation();
      } catch (e) {
        Get.snackbar('Error', 'Error starting tracking: $e');
      } finally {
        isTrackingLoading.value = false;
      }
    }
  }

  bool validateIsTracking() {
    return toAddress.value.isNotEmpty && destinationLatitude.value != null;
  }

  void setAlertDistance(int distance) {
    if (!isTracking.value) {
      alertDistance.value = distance;
    }
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

  /// Smoothly animate the map to the user's current GPS location.
  void _animateToCurrentLocation() {
    final pos = currentPosition.value;
    if (pos == null) return;

    final targetLat = pos.latitude;
    final targetLon = pos.longitude;
    const targetZoom = 16.0;

    try {
      final startLat = mapController.camera.center.latitude;
      final startLon = mapController.camera.center.longitude;
      final startZoom = mapController.camera.zoom;

      const steps = 30;
      const duration = Duration(milliseconds: 800);
      final stepDuration = Duration(
        microseconds: duration.inMicroseconds ~/ steps,
      );

      int step = 0;
      Timer.periodic(stepDuration, (timer) {
        step++;
        // Ease-out cubic curve
        final t = step / steps;
        final ease = 1.0 - math.pow(1.0 - t, 3);

        final lat = startLat + (targetLat - startLat) * ease;
        final lon = startLon + (targetLon - startLon) * ease;
        final zoom = startZoom + (targetZoom - startZoom) * ease;

        try {
          mapController.move(LatLng(lat, lon), zoom);
        } catch (_) {}

        if (step >= steps) {
          timer.cancel();
        }
      });
    } catch (e) {
      // Fallback: just jump
      centerMap(targetLat, targetLon, targetZoom);
    }
  }

  void clearDestination() {
    toController.clear();
    toAddress.value = '';
    destinationLatitude.value = null;
    destinationLongitude.value = null;
    currentRoute.clear();
  }

  Future<void> selectDestination(String address) async {
    toController.text = address;
    toAddress.value = address;
    currentRoute.clear();
    final coords = await StreetManager.instance.getCoordinates(address);
    if (coords != null) {
      destinationLatitude.value = coords['lat'];
      destinationLongitude.value = coords['lon'];
      centerMap(destinationLatitude.value!, destinationLongitude.value!);
      if (currentPosition.value != null) {
        _updateRouteIfNeeded(currentPosition.value!);
      }
    }
    update();
  }

  Future<void> setDestinationFromCoords(LatLng coords) async {
    if (isTracking.value) return;

    destinationLatitude.value = coords.latitude;
    destinationLongitude.value = coords.longitude;
    currentRoute.clear();
    centerMap(coords.latitude, coords.longitude);

    final details = await StreetManager.instance.getLocationDetailsAt(
      coords.latitude,
      coords.longitude,
    );
    if (details != null && details['address'] != null) {
      final String address = details['address']!;
      toAddress.value = address;
      toController.text = address;
    } else {
      toAddress.value =
          "${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}";
      toController.text = toAddress.value;
    }

    if (currentPosition.value != null) {
      _updateRouteIfNeeded(currentPosition.value!);
    }
    update();
  }

  void focusCurrentLocation() {
    final pos = currentPosition.value;
    if (pos != null) {
      centerMap(pos.latitude, pos.longitude, 15.0);
    } else {
      getInitialLocation();
    }
  }

  void selectCenterLocation() {
    if (isTracking.value) return;
    try {
      final center = mapController.camera.center;
      setDestinationFromCoords(center);
    } catch (e) {
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

  void toggleMapTheme() {
    isMapDark.value = !isMapDark.value;
    update();
  }
}
