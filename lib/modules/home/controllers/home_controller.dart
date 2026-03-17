import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/geo_location_manager/street_manager.dart';
import 'package:locami/db_manager/user_model_manager.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:locami/screens/widgets/arrival_alert.dart';
import 'package:locami/core/utils/trip_simulator.dart';
import 'package:locami/core/utils/routing_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class HomeController extends GetxController {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  
  final userCountry = 'India'.obs;
  final isTracking = false.obs;
  final isTrackingLoading = false.obs;
  final currentPosition = Rx<Position?>(null);
  final showLocami = true.obs;
  final alertDistance = 500.obs;
  final locations = <String>[].obs;
  final fromAddress = "".obs;
  final toAddress = "".obs;
  final destinationLatitude = Rx<double?>(null);
  final destinationLongitude = Rx<double?>(null);
  final currentRoute = <LatLng>[].obs;
  final useSatelliteMap = false.obs;
  final isMapDark = true.obs;
  final currentLocationName = "Locating...".obs;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _transmissionTimer;
  Timer? _simulationTimer;
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 2),
    ).listen((position) async {
      currentPosition.value = position;
      mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      
      final details = await StreetManager.instance.getLocationDetailsAt(position.latitude, position.longitude);
      if (details != null && details['address'] != null) {
        currentLocationName.value = _formatAddressToTwoCommas(details['address']!);
      }

      if (destinationLatitude.value != null && destinationLongitude.value != null) {
        _updateRouteIfNeeded(position);
      }
    });
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

  Future<void> _initAsync() async {
    await getInitialLocation();
    _startLocationStream();
    checkTrackingStatus();
    loadUserCountryFromProfile();
    loadNearbyStreets();
  }

  @override
  void onClose() {
    fromController.dispose();
    toController.dispose();
    _transmissionTimer?.cancel();
    _simulationTimer?.cancel();
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
        centerMap(lastKnown.latitude, lastKnown.longitude, 15.0);
      }
      final accurate = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      currentPosition.value = accurate;
      centerMap(accurate.latitude, accurate.longitude, 15.0);
      
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

  void focusCurrentLocation() {
    final pos = currentPosition.value;
    if (pos != null) {
      centerMap(pos.latitude, pos.longitude, 15.0);
    } else {
      getInitialLocation();
    }
  }

  void toggleMapTheme() {
    isMapDark.value = !isMapDark.value;
    update();
  }
}
