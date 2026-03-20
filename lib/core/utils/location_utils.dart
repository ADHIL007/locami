import 'package:geolocator/geolocator.dart';

class LocationUtils {
  /// Calculate smoothed speed combining GPS and distance calculation
  static double calculateSmoothedSpeed({
    required Position currentPos,
    required DateTime now,
    Position? previousPos,
    DateTime? previousTime,
    required double currentSpeedBufferAvg,
    required double candidateSpeed,
  }) {
    double speedToUse = candidateSpeed;

    if (previousPos != null && previousTime != null) {
      final dt = now.difference(previousTime).inMilliseconds / 1000.0;
      if (dt > 0.1) {
        final dist = Geolocator.distanceBetween(
          previousPos.latitude,
          previousPos.longitude,
          currentPos.latitude,
          currentPos.longitude,
        );

        if (dist > 3.0) {
          final calcSpeed = dist / dt;
          if (speedToUse > 0) {
            speedToUse = (speedToUse + calcSpeed) / 2.0;
          } else {
            speedToUse = calcSpeed;
          }
        } else if (speedToUse == 0) {
          speedToUse = 0.0;
        }
      }
    }

    return speedToUse;
  }

  /// Calculate smoothly interpolated bearing
  static double calculateResponsiveBearing({
    required Position currentPos,
    Position? previousPos,
    required double currentHeading,
    required double smoothedSpeed,
  }) {
    if (previousPos != null && smoothedSpeed > 1.0) {
      final double newBearing = Geolocator.bearingBetween(
        previousPos.latitude,
        previousPos.longitude,
        currentPos.latitude,
        currentPos.longitude,
      );

      double diff = (newBearing - currentHeading).remainder(360.0);
      if (diff > 180.0) diff -= 360.0;
      if (diff < -180.0) diff += 360.0;

      return (currentHeading + diff * 0.5).remainder(360.0);
    } else if (currentPos.heading != 0.0) {
      return currentPos.heading;
    }
    return currentHeading;
  }
}
