import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:get/get.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:locami/core/utils/map_utils.dart';
import 'package:locami/core/widgets/glass_container.dart';
import 'package:locami/modules/trip/controllers/trip_details_controller.dart';

class TripDetailsView extends GetView<TripDetailsController> {
  final TripDetailsModel trip;
  final VoidCallback onStartAgain;

  const TripDetailsView({
    super.key,
    required this.trip,
    required this.onStartAgain,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TripDetailsController());
    final themeProvider = ThemeProvider.instance;
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(trip.timestamp);
    final distance = (((trip.totalDistance ?? trip.distanceTraveled) ?? 0) / 1000).toStringAsFixed(1);
    final speed = ((trip.speed < 0 ? 0.0 : trip.speed) * 3.6).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: BackButton(color: customColors().textPrimary),
        title: Text(
          'Trip Details',
          style: TextStyle(color: customColors().textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large Map Header
            SizedBox(
              height: 300,
              width: double.infinity,
              child: _buildMapBanner(trip),
            ),
            const SizedBox(height: 24),
            // Trip info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: customColors().textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLocationRow(
                    icon: SolarIconsOutline.gps,
                    title: "From",
                    subtitle: trip.street ?? "Unknown Location",
                    color: Colors.green,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 11.0, top: 4, bottom: 4),
                    child: Container(
                      width: 2,
                      height: 30,
                      color: customColors().textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                  _buildLocationRow(
                    icon: SolarIconsBold.mapPoint,
                    title: "To",
                    subtitle: trip.destination ?? "Unknown Destination",
                    color: Colors.red,
                  ),
                  const SizedBox(height: 32),
                  Divider(color: customColors().textPrimary.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox(
                        SolarIconsOutline.map,
                        "Distance",
                        "$distance km",
                      ),
                      _buildStatBox(SolarIconsOutline.speedometerMiddle, "Avg Speed", "$speed km/h"),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isStarting.value 
                          ? null 
                          : () => controller.startTripAgain(onStartAgain),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.accentColor,
                        foregroundColor: customColors().textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isStarting.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(SolarIconsBold.play, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "Start Trip Again",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    )),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBanner(TripDetailsModel trip) {
    if (trip.destinationLatitude == null || trip.destinationLongitude == null) {
      return Container(
        color: customColors().background.withValues(alpha: 0.3),
        child: Center(
          child: Icon(
            SolarIconsOutline.map,
            color: customColors().textSecondary.withValues(alpha: 0.5),
            size: 48,
          ),
        ),
      );
    }

    final double startLat = trip.latitude;
    final double startLon = trip.longitude;
    final double endLat = trip.destinationLatitude!;
    final double endLon = trip.destinationLongitude!;

    final double centerLat = (startLat + endLat) / 2;
    final double centerLon = (startLon + endLon) / 2;

    final double distance = MapUtils.distanceInKm(startLat, startLon, endLat, endLon);
    final int zoom = MapUtils.calculateZoom(distance);

    final String url =
        "https://static-maps.yandex.ru/1.x/"
        "?l=map"
        "&lang=en_US"
        "&size=600,300"
        "&scale=2"
        "&z=$zoom"
        "&ll=$centerLon,$centerLat"
        "&pt=$startLon,$startLat,pm2blm~$endLon,$endLat,pm2rdm"
        "&pl=c:1A73E8,w:5,$startLon,$startLat,$endLon,$endLat";

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: customColors().background.withValues(alpha: 0.1),
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: customColors().background.withValues(alpha: 0.3),
        child: Center(
          child: Icon(
            SolarIconsOutline.map,
            color: customColors().textSecondary.withValues(alpha: 0.5),
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: customColors().textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: customColors().textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(IconData icon, String title, String value) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      opacity: 0.05,
      blur: 10,
      borderRadius: 20,
      child: Column(
        children: [
          Icon(icon, color: customColors().textSecondary, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: customColors().textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: customColors().textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
