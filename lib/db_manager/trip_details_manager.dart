import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/db_helper/trip_db.dart';
import 'package:locami/core/geo_location_manager/street_manager.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/core/model/user_model.dart';
import 'package:locami/db_manager/user_model_manager.dart';

import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
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
      debugPrint('QWERTYUIOP: Resuming tracking state in main isolate');
      _isTracking = true;
      isTrackingNotifier.value = true;
      _destinationLat = user.destinationLatitude;
      _destinationLon = user.destinationLongitude;
      _alertDistance = user.alertDistance;
      _currentTripId = user.currentTripId;
    }
  }

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelStreamSubscription;

  final ValueNotifier<TripDetailsModel?> currentTripDetail = ValueNotifier(
    null,
  );

  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);
  final ValueNotifier<double?> alertTriggeredNotifier = ValueNotifier(null);

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
    debugPrint("QWERTYUIOP: Simulation mode set to $value");
  }

  Future<void> startTracking({double alertDistance = 500.0}) async {
    if (_isTracking) return;

    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        throw Exception(
          'Notification permission is required to track your trip in the background.',
        );
      }
    }

    _isTracking = true;
    isTrackingNotifier.value = true;
    _currentTripId = DateTime.now().millisecondsSinceEpoch.toString();

    currentTripDetail.value = null;

    _alertDistance = alertDistance;
    _alertTriggered = false;
    alertTriggeredNotifier.value = null;

    _sourceLat = null;
    _sourceLon = null;
    _destinationLat = null;
    _destinationLon = null;
    _totalTripDistance = null;

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

    // Initial address cache using current device position
    try {
      final details = await StreetManager.instance.getCurrentLocationDetails();
      if (details != null) {
        _lastKnownCountry = details['countryCode'];
        _lastKnownStreet = details['address'];
      }
    } catch (_) {}

    if (!(await FlutterBackgroundService().isRunning())) {
      try {
        await FlutterBackgroundService().startService();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint("Error starting background service: $e");
      }
    }

    /* 
    The main isolate should NOT start its own position stream if the background service is used.
    The UI will receive updates via the on('on_position_update') listener in _listenToBackgroundService().
    */
    /*
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
    */

    await UserModelManager.instance.patchUser(
      isTravelStarted: true,
      isTravelEnded: false,
      startTime: DateTime.now(),
      alertDistance: _alertDistance,
      currentTripId: _currentTripId,
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

    await _accelStreamSubscription?.cancel();
    _accelStreamSubscription = null;

    FlutterBackgroundService().invoke("stopService");

    _isTracking = false;
    isTrackingNotifier.value = false;
    _destinationLat = null;
    _destinationLon = null;
    _alertTriggered = false;
    alertTriggeredNotifier.value = null;

    await UserModelManager.instance.patchUser(
      isTravelStarted: false,
      isTravelEnded: true,
      endTime: DateTime.now(),
      currentTripId: null,
    );
  }

  Future<void> simulateLocationUpdate(Position position) async {
    if (!_isTracking) return;

    if (_backgroundService == null &&
        await FlutterBackgroundService().isRunning()) {
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

    final lastPoint = await TripDbHelper.instance.getLastPointForTrip(
      _currentTripId,
    );
    if (lastPoint != null) {
      distance = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        position.latitude,
        position.longitude,
      );
    }

    // Update street name using the tracked position (not device GPS)
    // Update every 100m or on first position
    if (_lastKnownStreet == null || (lastPoint != null && distance > 100)) {
      await _updateAddressCacheAt(position.latitude, position.longitude);
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

      if (!_alertTriggered &&
          _alertDistance != null &&
          remainingDist <= _alertDistance!) {
        _alertTriggered = true;
        _triggerAlert(remainingDist);
      }
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
      tripId: _currentTripId,
    );

    await TripDbHelper.instance.insertTripDetail(newDetail);
    currentTripDetail.value = newDetail;

    if (_backgroundService != null) {
      _backgroundService!.invoke('on_position_update', newDetail.toJson());
    }

    if (_backgroundService != null) {
      _updateForegroundNotification(newDetail);
    }
  }

  void _updateForegroundNotification(TripDetailsModel details) async {
    final remaining = details.remainingDistance ?? 0.0;
    final traveled = details.distanceTraveled ?? 0.0;
    final totalDist = _totalTripDistance ?? (traveled + remaining);

    double progressDouble = totalDist > 0 ? (traveled / totalDist) * 100 : 0.0;
    int progress = progressDouble.clamp(0, 100).toInt();

    final remainingKm = (remaining / 1000).toStringAsFixed(1);
    String formatPlaceName(String name) {
      final beforeComma = name.split(',').first.trim();
      if (beforeComma.length > 20) {
        return '${beforeComma.substring(0, 17)}...';
      }
      return beforeComma;
    }

    final fromStr = formatPlaceName(details.street ?? "Current Location");
    final toStr = formatPlaceName(details.destination ?? "Destination");

    final speedKmh = details.speed * 3.6;
    String timeStr = "";
    if (speedKmh > 1.0 && remainingKm != "0.0") {
      final hoursRaw = (remaining / 1000) / speedKmh;
      int h = hoursRaw.floor();
      int m = ((hoursRaw - h) * 60).round();
      timeStr = h > 0 ? " • ${h}h ${m}m elapsed" : " • ${m}m elapsed";
    }

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'locami_tracking_channel',
      'Locami Tracking Service',
      channelDescription: 'Ongoing notification for location tracking',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      silent: true,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.service,

      color: const Color(0xFF16171B),
      colorized: true,

      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'view_trip_action',
          'VIEW TRIP',
          showsUserInterface: true,
        ),
      ],

      showWhen: false,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      888,
      '$fromStr → $toStr',
      '$remainingKm km$timeStr',
      notificationDetails,
    );
  }

  void _triggerAlert(double distance) {
    debugPrint(
      'QWERTYUIOP: ALERT TRIGGERED! Distance remaining: $distance meters',
    );
    alertTriggeredNotifier.value = distance;
    
    // Persist alarm state
    UserModelManager.instance.patchUser(isAlarmActive: true);

    if (_backgroundService != null) {
      _backgroundService!.invoke('on_alert_triggered', {'distance': distance});

      try {
        FlutterRingtonePlayer().playAlarm(looping: true);
      } catch (e) {
        debugPrint("Error playing alarm in background: $e");
      }

      _showFullScreenAlert(distance);
    }
  }

  void stopAlertSound() {
    FlutterRingtonePlayer().stop();
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();
    notifications.cancel(999);
    
    // Clear persisted alarm state
    UserModelManager.instance.patchUser(isAlarmActive: false);

    if (_backgroundService != null) {
      _backgroundService!.invoke('stop_alarm');
    }
  }

  void _showFullScreenAlert(double distance) async {
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'locami_alarm_channel_v2',
      'Locami Alarm',
      channelDescription: 'Alarm notification when destination is reached',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(
      999,
      'Destination Reached!',
      "You've arrived at your destination.",
      notificationDetails,
    );
  }

  Future<void> _updateAddressCacheAt(double lat, double lon) async {
    try {
      final details = await StreetManager.instance.getLocationDetailsAt(lat, lon);
      if (details != null) {
        _lastKnownCountry = details['countryCode'];
        _lastKnownStreet = details['address'];
      }
    } catch (e) {
      debugPrint('Error updating address cache: $e');
    }
  }

  Future<List<TripDetailsModel>> getLogs() async {
    final allLogs = await TripDbHelper.instance.getAllTripDetails();
    if (allLogs.isEmpty) return [];

    Map<String, List<TripDetailsModel>> groups = {};
    List<TripDetailsModel> untrackedLogs = [];

    for (var log in allLogs) {
      if (log.tripId != null) {
        groups.putIfAbsent(log.tripId!, () => []).add(log);
      } else {
        untrackedLogs.add(log);
      }
    }

    List<TripDetailsModel> distinctTrips = [];

    groups.forEach((tripId, points) {
      if (points.isNotEmpty) {
        points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final latest = points.last;
        final earliest = points.first;

        distinctTrips.add(
          latest.copyWith(
            street: earliest.street ?? "Unknown Location",
            timestamp: earliest.timestamp,
          ),
        );
      }
    });

    if (untrackedLogs.isNotEmpty) {
      untrackedLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      TripDetailsModel currentTripLatest = untrackedLogs.first;
      TripDetailsModel currentTripEarliest = untrackedLogs.first;
      String? firstKnownStreet = untrackedLogs.first.street;

      for (int i = 1; i < untrackedLogs.length; i++) {
        final log = untrackedLogs[i];
        final timeGap =
            currentTripEarliest.timestamp.difference(log.timestamp).abs();

        if (log.destination != currentTripLatest.destination ||
            timeGap.inMinutes > 30) {
          distinctTrips.add(
            currentTripLatest.copyWith(
              street:
                  firstKnownStreet ??
                  currentTripEarliest.street ??
                  "Unknown Location",
              timestamp: currentTripEarliest.timestamp,
            ),
          );
          currentTripLatest = log;
          currentTripEarliest = log;
          firstKnownStreet = log.street;
        } else {
          currentTripEarliest = log;
          if (log.street != null) firstKnownStreet = log.street;
        }
      }
      distinctTrips.add(
        currentTripLatest.copyWith(
          street:
              firstKnownStreet ??
              currentTripEarliest.street ??
              "Unknown Location",
          timestamp: currentTripEarliest.timestamp,
        ),
      );
    }

    distinctTrips.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return distinctTrips;
  }

  Future<void> clearLogs() async {
    await TripDbHelper.instance.clearAll();
    currentTripDetail.value = null;
  }

  Future<void> startBackgroundTracking(ServiceInstance service) async {
    _backgroundService = service;
    _isTracking = true;
    isTrackingNotifier.value = true;

    UserModel user = await UserModelManager.instance.user;
    if (user.isTravelStarted) {
      await _positionStreamSubscription?.cancel();
      await _accelStreamSubscription?.cancel();

      _destinationLat = user.destinationLatitude;
      _destinationLon = user.destinationLongitude;
      _alertDistance = user.alertDistance ?? 500.0;
      _currentTripId = user.currentTripId;

      if (_currentTripId == null) {
        final lastLogs = await TripDbHelper.instance.getAllTripDetails();
        if (lastLogs.isNotEmpty) {
          _currentTripId = lastLogs.last.tripId;
        }
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        if (_isSimulationMode) return;
        debugPrint('QWERTYUIOP: Background Position: ${position.latitude}, ${position.longitude}');
        _handlePositionUpdate(position);
      });

      _accelStreamSubscription = userAccelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen((event) {
        _currentAcceleration = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
      });
    }
  }
}
