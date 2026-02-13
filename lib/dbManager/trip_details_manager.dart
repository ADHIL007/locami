import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/dbHelper/trip_db.dart';
import 'package:locami/core/geo-location-Manager/street-Manager.dart';
import 'package:locami/core/model/trip_details_model.dart';

import 'package:locami/dbManager/userModel_manager.dart';

import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class TripDetailsManager {
  TripDetailsManager._internal();
  static final TripDetailsManager instance = TripDetailsManager._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelStreamSubscription;

  final ValueNotifier<TripDetailsModel?> currentTripDetail = ValueNotifier(
    null,
  );

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  // Cache last known country to avoid excessive API calls
  String? _lastKnownCountry;
  String? _lastKnownStreet;
  double _currentAcceleration = 0.0;

  Future<void> startTracking() async {
    if (_isTracking) return;
    _isTracking = true;

    // Ensure permissions are granted
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isTracking = false;
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _isTracking = false;
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _isTracking = false;
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // Initial fetch of address details to seed cache
    await _updateAddressCache();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _handlePositionUpdate(position);
    });

    // Start Accelerometer listener
    _accelStreamSubscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      // specific gravity is removed by userAccelerometerEventStream
      // Calculate magnitude
      _currentAcceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
    });

    // Update user status
    await UserModelManager.instance.patchUser(
      isTravelStarted: true,
      isTravelEnded: false,
      startTime: DateTime.now(),
    );
  }

  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    await _accelStreamSubscription?.cancel();
    _accelStreamSubscription = null;

    _isTracking = false;

    await UserModelManager.instance.patchUser(
      isTravelStarted: false,
      isTravelEnded: true,
      endTime: DateTime.now(),
    );
  }

  Future<void> _handlePositionUpdate(Position position) async {
    // calculate distance from last point
    double distance = 0.0;

    final lastPoint = await TripDbHelper.instance.getLastPoint();
    if (lastPoint != null) {
      distance = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        position.latitude,
        position.longitude,
      );
    }

    // Refresh address cache if distance is significant (e.g. > 500m) or if not set
    if (_lastKnownCountry == null || (lastPoint != null && distance > 500)) {
      await _updateAddressCache();
    }

    // Get current destination from user model
    final user = await UserModelManager.instance.user;
    final destination = user.destinationStreet;

    final newDetail = TripDetailsModel(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      speed: position.speed, // Speed in m/s
      heading: position.heading,
      altitude: position.altitude,
      accuracy: position.accuracy,
      distanceTraveled: (lastPoint?.distanceTraveled ?? 0) + distance,
      country: _lastKnownCountry,
      street: _lastKnownStreet,
      acceleration: _currentAcceleration,
      destination: destination,
    );

    await TripDbHelper.instance.insertTripDetail(newDetail);
    currentTripDetail.value = newDetail;
  }

  Future<void> _updateAddressCache() async {
    try {
      final details = await StreetManager.instance.getCurrentLocationDetails();
      if (details != null) {
        _lastKnownCountry = details['countryCode'];
        _lastKnownStreet = details['address'];
      }
    } catch (e) {
      debugPrint('Error updating address cache: $e');
    }
  }

  // Get all logs
  Future<List<TripDetailsModel>> getLogs() =>
      TripDbHelper.instance.getAllTripDetails();

  Future<void> clearLogs() async {
    await TripDbHelper.instance.clearAll();
    currentTripDetail.value = null;
  }
}
