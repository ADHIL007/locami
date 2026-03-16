import 'package:geolocator/geolocator.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
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
    if (!TripDetailsManager.instance.isTracking) return;

    final manager = TripDetailsManager.instance;
    final lastDetail = manager.currentTripDetail.value;

    if (lastDetail == null || lastDetail.destinationLatitude == null) return;

    final currentLat = lastDetail.latitude;
    final currentLon = lastDetail.longitude;
    final destLat = lastDetail.destinationLatitude!;
    final destLon = lastDetail.destinationLongitude!;

    final newLat = currentLat + (destLat - currentLat) * 0.1;
    final newLon = currentLon + (destLon - currentLon) * 0.1;

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
}
