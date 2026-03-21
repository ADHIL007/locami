import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/db_helper/trip_db.dart';
import 'package:locami/core/geo_location_manager/street_manager.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/core/model/user_model.dart';
import 'package:locami/db_manager/user_model_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';
import 'package:locami/core/utils/routing_service.dart';
import 'package:locami/core/utils/widget_helper.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter/services.dart';

class TripDetailsManager {
  TripDetailsManager._internal();
  static final TripDetailsManager instance = TripDetailsManager._internal();

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    _listenToBackgroundService();
    _checkAndResumeTracking();
  }

  Future<void> _checkAndResumeTracking() async {
    final user = await UserModelManager.instance.user;
    if (user.isTravelStarted) {
      _isTracking = true;
      isTrackingNotifier.value = true;
      _destinationLat = user.destinationLatitude;
      _destinationLon = user.destinationLongitude;
      _alertDistance = user.alertDistance;
      _currentTripId = user.currentTripId;
      _totalTripDistance = user.totalTripDistance;
      _distanceRatio = user.distanceRatio;
    }
  }

  StreamSubscription<Position>? _positionStreamSubscription;

  final ValueNotifier<TripDetailsModel?> currentTripDetail = ValueNotifier(null);
  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);
  final ValueNotifier<double?> alertTriggeredNotifier = ValueNotifier(null);

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  String? _lastKnownCountry;
  String? _lastKnownStreet;
  double? _destinationLat;
  double? _destinationLon;
  double? _totalTripDistance;
  double _distanceRatio = 1.0; // Ratio between road and haversine distance
  String? _currentTripId;
  ServiceInstance? _backgroundService;
  bool _isInitialized = false;
  bool _isListeningToBackground = false;

  double? get alertDistance => _alertDistance;
  double? get totalTripDistance => _totalTripDistance;

  double? _alertDistance;
  bool _alertTriggered = false;
  bool _isSimulationMode = false;

  void setSimulationMode(bool value) {
    _isSimulationMode = value;
  }

  Future<void> startTracking({double alertDistance = 500.0}) async {
    if (_isTracking) return;

    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        throw Exception('Notification permission required');
      }
    }

    _isTracking = true;
    isTrackingNotifier.value = true;
    _currentTripId = DateTime.now().millisecondsSinceEpoch.toString();
    currentTripDetail.value = null;

    _alertDistance = alertDistance;
    _alertTriggered = false;
    alertTriggeredNotifier.value = null;

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

    UserModel user = await UserModelManager.instance.user;
    
    if (user.destinationStreet != null && user.destinationStreet!.isNotEmpty) {
      if (user.destinationLatitude == null || user.destinationLongitude == null) {
        final coords = await StreetManager.instance.getCoordinates(user.destinationStreet!);
        if (coords != null) {
          _destinationLat = coords['lat'];
          _destinationLon = coords['lon'];
          await UserModelManager.instance.patchUser(
            destinationLatitude: _destinationLat,
            destinationLongitude: _destinationLon,
          );
        }
      } else {
        _destinationLat = user.destinationLatitude;
        _destinationLon = user.destinationLongitude;
      }
    }

    if (!(await FlutterBackgroundService().isRunning())) {
      await FlutterBackgroundService().startService();
    }

    // Initialize total distance for progress bar (use road distance if possible)
    try {
      final startPos = await Geolocator.getCurrentPosition();
      if (_destinationLat != null && _destinationLon != null) {
        final haversine = Geolocator.distanceBetween(
          startPos.latitude, startPos.longitude,
          _destinationLat!, _destinationLon!,
        );
        
        final routeData = await RoutingService.instance.getRoute(
          LatLng(startPos.latitude, startPos.longitude),
          LatLng(_destinationLat!, _destinationLon!),
        );
        
        _totalTripDistance = routeData.distance;
        
        // Calculate ratio to keep remaining distance consistent with road distance
        if (haversine > 0) {
          _distanceRatio = _totalTripDistance! / haversine;
        }
      }
    } catch (e) {
      debugPrint("Error getting initial road distance: $e");
    }

    await UserModelManager.instance.patchUser(
      isTravelStarted: true,
      isTravelEnded: false,
      startTime: DateTime.now(),
      alertDistance: _alertDistance,
      currentTripId: _currentTripId,
      totalTripDistance: _totalTripDistance,
      distanceRatio: _distanceRatio,
    );

    _listenToBackgroundService();
    FlutterBackgroundService().invoke('start_tracking');
  }

  void _listenToBackgroundService() {
    if (_isListeningToBackground) return;
    _isListeningToBackground = true;

    FlutterBackgroundService().on('on_position_update').listen((data) {
      if (data != null) {
        final detail = TripDetailsModel.fromJson(data);
        currentTripDetail.value = detail;
        _isTracking = true;
        isTrackingNotifier.value = true;
      }
    });

    FlutterBackgroundService().on('on_alert_triggered').listen((data) {
      if (data != null) {
        final double? distance = (data['distance'] as num?)?.toDouble();
        alertTriggeredNotifier.value = distance;
      }
    });
  }

  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    FlutterBackgroundService().invoke("stopService");

    _isTracking = false;
    isTrackingNotifier.value = false;
    _destinationLat = null;
    _destinationLon = null;
    _alertTriggered = false;
    alertTriggeredNotifier.value = null;

    WidgetHelper.updateWidget(
      remainingDistance: null,
      isTracking: false,
      currentLoc: "Ready to track",
      destName: "Select a destination",
      progress: 0,
      statusInfo: "Setup a destination to start",
      alertDist: "500m",
      speed: 0,
    );

    await UserModelManager.instance.patchUser(
      isTravelStarted: false,
      isTravelEnded: true,
      endTime: DateTime.now(),
      currentTripId: null,
      clearDestination: true,
    );
  }

  Future<void> simulateLocationUpdate(Position position) async {
    if (!_isTracking) return;

    if (_backgroundService == null && await FlutterBackgroundService().isRunning()) {
      FlutterBackgroundService().invoke('simulate_location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'altitude': position.altitude,
        'accuracy': position.accuracy,
      });
      return;
    }
    await _handlePositionUpdate(position);
  }

  void handleSimulatedPosition(Map<String, dynamic> data) {
    final position = Position(
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      timestamp: DateTime.now(),
      accuracy: (data['accuracy'] as num? ?? 0.0).toDouble(),
      altitude: (data['altitude'] as num? ?? 0.0).toDouble(),
      heading: (data['heading'] as num? ?? 0.0).toDouble(),
      speed: (data['speed'] as num? ?? 0.0).toDouble(),
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    _handlePositionUpdate(position);
  }

  Future<void> _handlePositionUpdate(Position position) async {
    double distance = 0.0;
    final lastPoint = await TripDbHelper.instance.getLastPointForTrip(_currentTripId);
    if (lastPoint != null) {
      distance = Geolocator.distanceBetween(lastPoint.latitude, lastPoint.longitude, position.latitude, position.longitude);
    }

    if (_lastKnownStreet == null || (lastPoint != null && distance > 100)) {
      await _updateAddressCacheAt(position.latitude, position.longitude);
    }

    final user = await UserModelManager.instance.user;
    double? remainingDist;
    if (_destinationLat != null && _destinationLon != null) {
      final rawHaversine = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        _destinationLat!, _destinationLon!,
      );
      
      // Use the road/haversine ratio to estimate actual road remaining
      remainingDist = rawHaversine * _distanceRatio;
      
      // Fallback: Initialize total distance if it's still null
      if (_totalTripDistance == null || _totalTripDistance == 0) {
        _totalTripDistance = remainingDist;
      }

      if (!_alertTriggered && _alertDistance != null && rawHaversine <= _alertDistance!) {
        _alertTriggered = true;
        _triggerAlert(rawHaversine);
      }
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
      acceleration: 0.0,
      destination: user.destinationStreet,
      remainingDistance: remainingDist,
      totalDistance: _totalTripDistance,
      totalDuration: user.startTime != null
          ? DateTime.now().difference(user.startTime!).inSeconds.toDouble()
          : (lastPoint?.totalDuration ?? 0.0),
      destinationLatitude: _destinationLat,
      destinationLongitude: _destinationLon,
      tripId: _currentTripId,
      alertDistance: _alertDistance,
    );

    await TripDbHelper.instance.insertTripDetail(newDetail);
    currentTripDetail.value = newDetail;

    if (_backgroundService != null) {
      _backgroundService!.invoke('on_position_update', newDetail.toJson());
      _updateForegroundNotification(newDetail);
    }
  }

  void _updateForegroundNotification(TripDetailsModel details) async {
    final remaining = details.remainingDistance ?? 0.0;
    final traveled = details.distanceTraveled ?? 0.0;
    final totalDist = _totalTripDistance ?? (traveled + remaining);
    int progress = totalDist > 0 ? ((traveled / totalDist) * 100).toInt().clamp(0, 100) : 0;
    final remainingKm = (remaining / 1000).toStringAsFixed(1);

    String formatPlace(String name) => name.split(',').first.trim().length > 20 ? '${name.split(',').first.trim().substring(0, 17)}...' : name.split(',').first.trim();

    final fromStr = formatPlace(details.street ?? "Current Location");
    final toStr = formatPlace(details.destination ?? "Destination");

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'locami_tracking_channel', 'Locami Tracking Service',
      importance: Importance.low, priority: Priority.low,
      ongoing: true, autoCancel: false, silent: true,
      showProgress: true, maxProgress: 100, progress: progress,
      icon: '@mipmap/ic_launcher', color: const Color(0xFF16171B), colorized: true,
    );
    await flutterLocalNotificationsPlugin.show(888, '$fromStr → $toStr', '$remainingKm km remaining', NotificationDetails(android: androidDetails));
    
    // Status matching InfoDisplay logic
    String etaText = '--';
    double speed = details.speed;
    String statusInfo = speed > 0.5 ? 'Moving' : 'Waiting for movement';
    
    if (speed > 0.5 && remaining > 0) {
      final etaSeconds = remaining / speed;
      if (etaSeconds < 60) {
        etaText = 'Less than 1 min';
      } else if (etaSeconds < 3600) {
        final mins = (etaSeconds / 60).ceil();
        etaText = '$mins mins';
      } else {
        final hours = (etaSeconds / 3600).floor();
        final mins = ((etaSeconds % 3600) / 60).round();
        etaText = '$hours hr $mins min';
      }
      statusInfo = "Moving | ~ $etaText";
    }

    // Update Home Screen Widget
    WidgetHelper.updateWidget(
      remainingDistance: remaining / 1000,
      isTracking: true,
      currentLoc: fromStr,
      destName: toStr,
      progress: progress,
      statusInfo: statusInfo,
      alertDist: "${_alertDistance?.toInt() ?? 500}m",
      speed: (speed * 3.6).round(),
    );
  }

  void _triggerAlert(double distance) async {
    alertTriggeredNotifier.value = distance;
    UserModelManager.instance.patchUser(isAlarmActive: true);
    if (_backgroundService != null) {
      _backgroundService!.invoke('on_alert_triggered', {'distance': distance});
      FlutterRingtonePlayer().playAlarm(looping: true);
      _showFullScreenAlert(distance);
      
      // Background vibration (will only work if enabled in user model/settings)
      final user = await UserModelManager.instance.user;
      if (user.enableVibration) {
        Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
      }
    }
  }

  void stopAlertSound() {
    FlutterRingtonePlayer().stop();
    Vibration.cancel();
    _alertTriggered = false;
    FlutterLocalNotificationsPlugin().cancel(999);
    UserModelManager.instance.patchUser(isAlarmActive: false);
    if (_backgroundService != null) _backgroundService!.invoke('stop_alarm');
  }

  void _showFullScreenAlert(double distance) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'locami_alarm_channel_v2', 'Locami Alarm',
      importance: Importance.max, priority: Priority.max,
      fullScreenIntent: true, category: AndroidNotificationCategory.alarm,
      ongoing: true, autoCancel: false,
    );
    await FlutterLocalNotificationsPlugin().show(999, 'Destination Reached!', "You've arrived at your destination.", const NotificationDetails(android: androidDetails));
  }

  Future<void> _updateAddressCacheAt(double lat, double lon) async {
    try {
      final details = await StreetManager.instance.getLocationDetailsAt(lat, lon);
      if (details != null) {
        _lastKnownCountry = details['countryCode'];
        _lastKnownStreet = details['address'];
      }
    } catch (_) {}
  }

  Future<void> startBackgroundTracking(ServiceInstance service) async {
    _backgroundService = service;
    _isTracking = true;
    isTrackingNotifier.value = true;
    UserModel user = await UserModelManager.instance.user;
    if (user.isTravelStarted) {
      await _positionStreamSubscription?.cancel();
      _destinationLat = user.destinationLatitude;
      _destinationLon = user.destinationLongitude;
      _alertDistance = user.alertDistance ?? 500.0;
      _currentTripId = user.currentTripId;
      _totalTripDistance = user.totalTripDistance;
      _distanceRatio = user.distanceRatio;
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).listen((pos) {
        if (!_isSimulationMode) _handlePositionUpdate(pos);
      });
    }
  }
}
