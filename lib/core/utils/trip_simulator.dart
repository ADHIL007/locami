import 'package:geolocator/geolocator.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:locami/db_manager/user_model_manager.dart';
import 'package:flutter/foundation.dart';

class TripSimulator {
  static Future<void> simulateArrival() async {
    if (!TripDetailsManager.instance.isTracking) {
      debugPrint('Simulator: Tracking is not active.');
      return;
    }

    final manager = TripDetailsManager.instance;

    final lastDetail = manager.currentTripDetail.value;

    if (lastDetail == null ||
        lastDetail.destinationLatitude == null ||
        lastDetail.destinationLongitude == null) {
      debugPrint('Simulator: Destination coordinates not available.');
      return;
    }

    final destLat = lastDetail.destinationLatitude!;
    final destLon = lastDetail.destinationLongitude!;
    final alertDist = manager.alertDistance ?? 500.0;

    final offset = (alertDist - 50) / 111111.0;

    final simulatedPosition = Position(
      latitude: destLat + offset,
      longitude: destLon,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 15.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );

    debugPrint('Simulator: Injecting simulated position near destination.');
    await manager.simulateLocationUpdate(simulatedPosition);
  }

  static Future<void> simulateMoveTowards() async {
    if (!TripDetailsManager.instance.isTracking) {
      debugPrint('QWERTYUIOP: Simulator - Tracking is not active, skipping.');
      return;
    }

    final manager = TripDetailsManager.instance;
    final lastDetail = manager.currentTripDetail.value;

    double currentLat;
    double currentLon;
    double destLat;
    double destLon;

    if (lastDetail != null && lastDetail.destinationLatitude != null) {
      currentLat = lastDetail.latitude;
      currentLon = lastDetail.longitude;
      destLat = lastDetail.destinationLatitude!;
      destLon = lastDetail.destinationLongitude!;
    } else {
      // First tick — no trip detail yet. Use real GPS as starting point.
      debugPrint('QWERTYUIOP: Simulator - No trip detail yet, fetching current GPS for initial position.');
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        );
        currentLat = position.latitude;
        currentLon = position.longitude;

        // Get destination from saved user model
        final user = await UserModelManager.instance.user;
        if (user.destinationLatitude == null || user.destinationLongitude == null) {
          debugPrint('QWERTYUIOP: Simulator - No destination coordinates saved, skipping.');
          return;
        }
        destLat = user.destinationLatitude!;
        destLon = user.destinationLongitude!;
      } catch (e) {
        debugPrint('QWERTYUIOP: Simulator - Failed to get GPS: $e');
        return;
      }
    }

    // Move 40% closer to destination each tick (reaches alert zone in ~5 seconds)
    final newLat = currentLat + (destLat - currentLat) * 0.4;
    final newLon = currentLon + (destLon - currentLon) * 0.4;

    debugPrint('QWERTYUIOP: Simulator - Moving from ($currentLat, $currentLon) towards ($destLat, $destLon)');
    debugPrint('QWERTYUIOP: Simulator - New position: ($newLat, $newLon)');

    final simulatedPosition = Position(
      latitude: newLat,
      longitude: newLon,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 20.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );

    await manager.simulateLocationUpdate(simulatedPosition);
  }

  static Future<void> simulateNearAlert() async {
    if (!TripDetailsManager.instance.isTracking) {
      debugPrint('Simulator: Tracking is not active.');
      return;
    }

    final manager = TripDetailsManager.instance;
    final lastDetail = manager.currentTripDetail.value;

    if (lastDetail == null ||
        lastDetail.destinationLatitude == null ||
        lastDetail.destinationLongitude == null) {
      debugPrint('Simulator: Destination coordinates not available.');
      return;
    }

    // 505 meters is roughly 0.00454 degrees
    const double offset = 505 / 111111.0;

    final simulatedPosition = Position(
      latitude: lastDetail.destinationLatitude! + offset,
      longitude: lastDetail.destinationLongitude!,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 10.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );

    debugPrint('Simulator: Injecting position 505m away.');
    await manager.simulateLocationUpdate(simulatedPosition);
  }
}
