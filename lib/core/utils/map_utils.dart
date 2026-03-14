import 'dart:math';

class MapUtils {
  static double distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static int calculateZoom(double distanceKm) {
    if (distanceKm < 1) return 14;
    if (distanceKm < 5) return 13;
    if (distanceKm < 20) return 11;
    if (distanceKm < 50) return 10;
    if (distanceKm < 200) return 8;
    if (distanceKm < 500) return 6;
    return 4;
  }
}
