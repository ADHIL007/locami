import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/geo_location_manager/street_manager.dart';
import 'package:locami/db_manager/user_model_manager.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:locami/screens/widgets/arrival_alert.dart';
import 'package:locami/modules/alarm/views/alarm_view.dart';
import 'package:locami/core/utils/trip_simulator.dart';
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
  final tripHistory = <TripDetailsModel>[].obs;
  final isLoadingHistory = false.obs;
  final locations = <String>[].obs;
  final fromAddress = "".obs;
  final toAddress = "".obs;
  final destinationLatitude = Rx<double?>(null);
  final destinationLongitude = Rx<double?>(null);


  Timer? _transmissionTimer;
  Timer? _simulationTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
      if (toAddress.value != toController.text) {
        destinationLatitude.value = null;
        destinationLongitude.value = null;
      }
      toAddress.value = toController.text;
      update();
    });

    TripDetailsManager.instance.isTrackingNotifier.addListener(_onTrackingStatusChanged);
    TripDetailsManager.instance.alertTriggeredNotifier.addListener(_onAlertTriggered);

    // Defer heavy async work until after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAsync();
    });
  }

  Future<void> _initAsync() async {
    await checkTrackingStatus();
    loadUserCountryFromProfile();
    loadNearbyStreets();
    loadTripHistory();
    getInitialLocation();
  }

  @override
  void onClose() {
    fromController.dispose();
    toController.dispose();
    _transmissionTimer?.cancel();
    _simulationTimer?.cancel();
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
      // Just in case, if not resumed, we already have AppController listener,
      // but let's be safe.
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
      // If dialog is dismissed somehow (though barrierDismissible is false), stop sound
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
        loadTripHistory();
      }
    }
  }

  Future<void> getInitialLocation() async {
    try {
      currentPosition.value = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
    } catch (_) {}
  }

  Future<void> checkTrackingStatus() async {
    // Read directly from DB to avoid race condition with TripDetailsManager async init
    final user = await UserModelManager.instance.user;
    
    if (user.isTravelStarted) {
      isTracking.value = true;
      
      // Restore saved trip data into UI fields
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
      // Tell the background service to ignore real GPS
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
    // Tell the background service to resume real GPS
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

  Future<void> loadTripHistory() async {
    isLoadingHistory.value = true;
    try {
      final history = await TripDetailsManager.instance.getLogs();
      tripHistory.assignAll(history);
    } finally {
      isLoadingHistory.value = false;
    }
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
    return fromAddress.value.isNotEmpty && toAddress.value.isNotEmpty;
  }


  void setAlertDistance(int distance) {
    if (!isTracking.value) {
      alertDistance.value = distance;
    }
  }

  Future<void> setNearbyTestLocation() async {
    final position = currentPosition.value ?? await Geolocator.getCurrentPosition();
    currentPosition.value = position;
    
    // Calculate a point that is (alertDistance + 2) meters away
    // 1 degree latitude is approximately 111,111 meters
    final double distanceInMeters = alertDistance.value.toDouble() + 2.0;
    final double deltaLat = distanceInMeters / 111111.0;
    
    destinationLatitude.value = position.latitude + deltaLat;
    destinationLongitude.value = position.longitude;
    toAddress.value = "Test Destination (Nearby)";
    toController.text = "Test Destination (Nearby)";
    update();
  }
}
