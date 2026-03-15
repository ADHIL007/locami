import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/modules/trip/views/trip_details_view.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:locami/core/utils/map_utils.dart';
import 'package:locami/core/widgets/glass_container.dart';

class TripHistoryCard extends StatelessWidget {
  final TripDetailsModel trip;
  final VoidCallback? onRestart;

  const TripHistoryCard({Key? key, required this.trip, this.onRestart})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(trip.timestamp);
    final isDark = ThemeProvider.instance.theme == AppThemeMode.dark;
    final accentColor = ThemeProvider.instance.accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: accentColor.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: GlassContainer(
        opacity: isDark ? 0.1 : 0.6,
        blur: 20,
        borderRadius: 16,
        color: isDark ? Colors.white : Colors.white.withOpacity(0.95),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          width: 1.5,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (onRestart != null) {
              Get.to(() => TripDetailsView(trip: trip, onStartAgain: onRestart!));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 100,
                    child: _buildMapPreview(trip),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            color: customColors().textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                          children: [
                            TextSpan(
                              text: (trip.street?.split(',').first ?? "Unknown Location").trim(),
                            ),
                            TextSpan(
                              text: " → ",
                              style: TextStyle(
                                color: customColors().textPrimary.withOpacity(0.6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: (trip.destination?.split(',').first ?? "Unknown Destination").trim(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: customColors().textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: customColors().textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: "${(((trip.totalDistance ?? trip.distanceTraveled) ?? 0) / 1000).toStringAsFixed(1)} km",
                                ),
                                TextSpan(
                                  text: " • ",
                                  style: TextStyle(
                                    color: customColors().textSecondary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: "${((trip.speed < 0 ? 0.0 : trip.speed) * 3.6).toStringAsFixed(0)} km/h",
                                ),
                              ],
                            ),
                          ),
                          if (onRestart != null)
                            Row(
                              children: [
                                Text(
                                  "View Trip",
                                  style: TextStyle(
                                    color: customColors().textSecondary.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 14,
                                  color: customColors().textSecondary.withOpacity(0.8),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMapPreview(TripDetailsModel trip) {
    if (trip.destinationLatitude == null || trip.destinationLongitude == null) {
      return _fallbackMapImage();
    }

    final double startLat = trip.latitude;
    final double startLon = trip.longitude;
    final double endLat = trip.destinationLatitude!;
    final double endLon = trip.destinationLongitude!;

    final double centerLat = (startLat + endLat) / 2;
    final double centerLon = (startLon + endLon) / 2;

    double distance = MapUtils.distanceInKm(startLat, startLon, endLat, endLon);
    int zoom = MapUtils.calculateZoom(distance);

    final String url =
        "https://static-maps.yandex.ru/1.x/"
        "?l=map"
        "&lang=en_US"
        "&size=450,220"
        "&z=$zoom"
        "&ll=$centerLon,$centerLat"
        "&pt=$startLon,$startLat,pm2blm~$endLon,$endLat,pm2rdm"
        "&pl=c:1A73E8,w:4,$startLon,$startLat,$endLon,$endLat";

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder:
          (context, url) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (context, url, error) => _fallbackMapImage(),
    );
  }

  Widget _fallbackMapImage() {
    return Container(
      color: customColors().background.withOpacity(0.3),
      child: Center(
        child: Icon(
          Icons.map_outlined,
          color: customColors().textSecondary.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }
}
