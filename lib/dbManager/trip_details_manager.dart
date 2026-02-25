import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/dbHelper/trip_db.dart';
import 'package:locami/core/geo-location-Manager/street-Manager.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/core/model/user_model.dart';
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

  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  String? _lastKnownCountry;
  String? _lastKnownStreet;
  double _currentAcceleration = 0.0;
  double? _destinationLat;
  double? _destinationLon;
  double? _sourceLat;
  double? _sourceLon;
  double? _totalTripDistance;

  Future<void> startTracking() async {
    if (_isTracking) return;

    await clearLogs();

    _isTracking = true;
    isTrackingNotifier.value = true;

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

    UserModel user = await UserModelManager.instance.user;
    debugPrint('QWERTYUIOP: startTracking');
    debugPrint('QWERTYUIOP: fromStreet: ${user.fromStreet}');
    debugPrint('QWERTYUIOP: destinationStreet: ${user.destinationStreet}');

    if (user.fromStreet != null && user.fromStreet!.isNotEmpty) {
      final sourceCoords = await StreetManager.instance.getCoordinates(
        user.fromStreet!,
      );
      if (sourceCoords != null) {
        _sourceLat = sourceCoords['lat'];
        _sourceLon = sourceCoords['lon'];
        debugPrint(
          'QWERTYUIOP: Source Geocoded - lat: $_sourceLat, lon: $_sourceLon',
        );
      }
    }

    if (user.destinationStreet != null && user.destinationStreet!.isNotEmpty) {
      if (user.destinationLatitude == null ||
          user.destinationLongitude == null) {
        debugPrint('QWERTYUIOP: Geocoding destination address...');
        final coords = await StreetManager.instance.getCoordinates(
          user.destinationStreet!,
        );
        if (coords != null) {
          _destinationLat = coords['lat'];
          _destinationLon = coords['lon'];
          debugPrint(
            'QWERTYUIOP: Destination Geocoded - lat: $_destinationLat, lon: $_destinationLon',
          );

          await UserModelManager.instance.patchUser(
            destinationLatitude: _destinationLat,
            destinationLongitude: _destinationLon,
          );
        } else {
          debugPrint('QWERTYUIOP: Destination geocoding failed');
        }
      } else {
        _destinationLat = user.destinationLatitude;
        _destinationLon = user.destinationLongitude;
        debugPrint(
          'QWERTYUIOP: Using existing destination coords - lat: $_destinationLat, lon: $_destinationLon',
        );
      }
    }

    if (_sourceLat != null &&
        _sourceLon != null &&
        _destinationLat != null &&
        _destinationLon != null) {
      _totalTripDistance = Geolocator.distanceBetween(
        _sourceLat!,
        _sourceLon!,
        _destinationLat!,
        _destinationLon!,
      );
      debugPrint(
        'QWERTYUIOP: Total Trip Distance calculated: $_totalTripDistance meters',
      );
    }

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

    _accelStreamSubscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _currentAcceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
    });

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
    isTrackingNotifier.value = false;
    _destinationLat = null;
    _destinationLon = null;

    await UserModelManager.instance.patchUser(
      isTravelStarted: false,
      isTravelEnded: true,
      endTime: DateTime.now(),
    );
  }

  Future<void> _handlePositionUpdate(Position position) async {
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

    if (_lastKnownCountry == null || (lastPoint != null && distance > 500)) {
      await _updateAddressCache();
    }

    final user = await UserModelManager.instance.user;
    final destination = user.destinationStreet;

    double? remainingDist;
    if (_destinationLat != null && _destinationLon != null) {
      remainingDist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _destinationLat!,
        _destinationLon!,
      );
      debugPrint(
        'QWERTYUIOP: Position update - pos: ${position.latitude}, ${position.longitude}, dest: $_destinationLat, $_destinationLon, remainingDist: $remainingDist meters',
      );
    } else {
      debugPrint(
        'QWERTYUIOP: Remaining distance NOT calculated - destLat: $_destinationLat, destLon: $_destinationLon',
      );
    }

    final newDetail = TripDetailsModel(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      speed: position.speed,
      heading: position.heading,
      altitude: position.altitude,
      accuracy: position.accuracy,
      distanceTraveled: (lastPoint?.distanceTraveled ?? 0) + distance,
      country: _lastKnownCountry,
      street: _lastKnownStreet,
      acceleration: _currentAcceleration,
      destination: destination,
      remainingDistance: remainingDist,
      totalDistance: _totalTripDistance,
      totalDuration: lastPoint?.totalDuration,
      destinationLatitude: _destinationLat,
      destinationLongitude: _destinationLon,
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

  Future<List<TripDetailsModel>> getLogs() =>
      TripDbHelper.instance.getAllTripDetails();

  Future<void> clearLogs() async {
    await TripDbHelper.instance.clearAll();
    currentTripDetail.value = null;
  }
}
