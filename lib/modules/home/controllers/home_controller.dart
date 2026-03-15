import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/geo-location-Manager/street_manager.dart';
import 'package:locami/dbManager/user_model_manager.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:locami/screens/widgets/arrival_alert.dart';
import 'package:locami/core/utils/trip_simulator.dart';

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


  Timer? _transmissionTimer;
  Timer? _simulationTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    // Initialize addresses
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


    loadUserCountryFromProfile();
    loadNearbyStreets();
    loadTripHistory();
    checkTrackingStatus();
    getInitialLocation();

    TripDetailsManager.instance.isTrackingNotifier.addListener(_onTrackingStatusChanged);
    TripDetailsManager.instance.alertTriggeredNotifier.addListener(_onAlertTriggered);
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
    final themeProvider = ThemeProvider.instance;
    final soundKey = themeProvider.alertSound;
    final isCustom = themeProvider.isCustomSound;
    final customPath = themeProvider.customSoundPath;

    stopAllSounds();

    if (isCustom && customPath != null) {
      _audioPlayer.play(DeviceFileSource(customPath));
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } else {
      if (soundKey == 'alarm') {
        FlutterRingtonePlayer().playAlarm(looping: true);
      } else if (soundKey == 'ringtone') {
        FlutterRingtonePlayer().playRingtone(looping: true);
      } else {
        FlutterRingtonePlayer().playNotification(looping: true);
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
    );
  }

  void stopAllSounds() {
    FlutterRingtonePlayer().stop();
    _audioPlayer.stop();
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
    if (TripDetailsManager.instance.isTracking) {
      isTracking.value = true;
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
      _simulationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
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
    } catch (e) {
      // Error handling
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
          destinationLatitude: null,
          destinationLongitude: null,
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
}
