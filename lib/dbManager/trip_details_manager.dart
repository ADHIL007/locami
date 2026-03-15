import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locami/core/dbHelper/trip_db.dart';
import 'package:locami/core/geo-location-Manager/street_manager.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/core/model/user_model.dart';
import 'package:locami/dbManager/user_model_manager.dart';

import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class TripDetailsManager {
  TripDetailsManager._internal();
  static final TripDetailsManager instance = TripDetailsManager._internal();

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

  double? get alertDistance => _alertDistance;
  double? get totalTripDistance => _totalTripDistance;

  double? _alertDistance;
  bool _alertTriggered = false;

  Future<void> startTracking({double alertDistance = 500.0}) async {
    if (_isTracking) return;

    // Check for Notification Permission (Android 13+) — MUST be granted
    // before starting the foreground service, otherwise Android throws
    // CannotPostForegroundServiceNotificationException.
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint("Notification permission not granted, cannot start foreground service.");
        throw Exception('Notification permission is required to track your trip in the background.');
      }
    }

    _isTracking = true;
    isTrackingNotifier.value = true;
    _currentTripId = DateTime.now().millisecondsSinceEpoch.toString();

    // Reset the current trip detail so the UI doesn't show stale data
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

    // Start background service AFTER all permissions are confirmed.
    // The foreground notification requires POST_NOTIFICATIONS (checked above)
    // and location permissions to be granted.
    try {
      await FlutterBackgroundService().startService();
      // Give Android time to post the foreground notification
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint("Error starting background service: $e");
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

    // Stop background service
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
    );
  }

  Future<void> simulateLocationUpdate(Position position) async {
    if (!_isTracking) return;
    await _handlePositionUpdate(position);
  }

  Future<void> _handlePositionUpdate(Position position) async {
    double distance = 0.0;

    final lastPoint = await TripDbHelper.instance.getLastPointForTrip(_currentTripId);
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

    _updateForegroundNotification(newDetail);
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
      // Notification visual styling matching dark theme requests
      color: const Color(0xFF16171B), // Dark aesthetic
      colorized: true, // Forces background if Android supports it for this channel
      // Adds a native button to reopen the app directly from notification
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'view_trip_action',
          'VIEW TRIP',
          showsUserInterface: true, // Bringing app to foreground
        ),
      ],
      // showWhen sets the timestamp in notification
      showWhen: false,
    );

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

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

  Future<List<TripDetailsModel>> getLogs() async {
    final allLogs = await TripDbHelper.instance.getAllTripDetails();
    if (allLogs.isEmpty) return [];

    // Group logs by trip_id
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

    // Process grouped trips
    groups.forEach((tripId, points) {
      if (points.isNotEmpty) {
        // Sort by timestamp just in case
        points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final latest = points.last;
        final earliest = points.first;
        
        distinctTrips.add(
          latest.copyWith(
            street: earliest.street ?? "Unknown Location",
            timestamp: earliest.timestamp, // Use start time for history
          ),
        );
      }
    });

    // Handle logs without tripId using the old heuristic (if any exist from old version)
    if (untrackedLogs.isNotEmpty) {
      untrackedLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Reversed
      TripDetailsModel currentTripLatest = untrackedLogs.first;
      TripDetailsModel currentTripEarliest = untrackedLogs.first;
      String? firstKnownStreet = untrackedLogs.first.street;

      for (int i = 1; i < untrackedLogs.length; i++) {
        final log = untrackedLogs[i];
        final timeGap = currentTripEarliest.timestamp.difference(log.timestamp).abs();

        if (log.destination != currentTripLatest.destination || timeGap.inMinutes > 30) {
          distinctTrips.add(
            currentTripLatest.copyWith(
              street: firstKnownStreet ?? currentTripEarliest.street ?? "Unknown Location",
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
          street: firstKnownStreet ?? currentTripEarliest.street ?? "Unknown Location",
          timestamp: currentTripEarliest.timestamp,
        ),
      );
    }

    // Sort all summarized trips by timestamp descending
    distinctTrips.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return distinctTrips;
  }

  Future<void> clearLogs() async {
    await TripDbHelper.instance.clearAll();
    currentTripDetail.value = null;
  }
}
