import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:locami/core/widgets/glass_container.dart';
import 'package:get/get.dart';
import 'package:locami/core/controllers/map_controller.dart';
import 'package:locami/theme/theme_provider.dart';

class ArrivalAlert extends StatelessWidget {
  final String destination;
  final VoidCallback onDone;
  final VoidCallback onThanks;

  const ArrivalAlert({
    super.key,
    required this.destination,
    required this.onDone,
    required this.onThanks,
  });

  @override
  Widget build(BuildContext context) {
    final trip = TripDetailsManager.instance.currentTripDetail.value;
    final themeProvider = ThemeProvider.instance;
    final isDark = themeProvider.theme == AppThemeMode.dark;
    final accentColor = themeProvider.accentColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        padding: const EdgeInsets.all(28),
        opacity: isDark ? 0.9 : 0.85,
        blur: 30,
        borderRadius: 32,
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          width: 1.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                SolarIconsBold.checkCircle,
                color: Color(0xFF4CAF50),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Reached Text
            Text(
              "$destination Reached!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: customColors().textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              "You've arrived at your destination",
              style: TextStyle(
                color: customColors().textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),

            // Map Clip
            if (trip != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: customColors().textPrimary.withValues(alpha: 0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: _buildMapSnippet(trip),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: TextButton(
                      onPressed: onThanks,
                      style: TextButton.styleFrom(
                        backgroundColor: customColors().textPrimary.withValues(alpha: 0.05),
                        foregroundColor: customColors().textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "THANKS!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "DONE",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSnippet(trip) {
    if (trip.destinationLatitude == null || trip.destinationLongitude == null) {
      return Container(color: Colors.grey.withValues(alpha: 0.05));
    }

    final mapController = Get.find<MapController>();
    final String url = mapController.getUrlForTrip(
      trip,
      width: 450,
      height: 200,
      mapLayer: 'sat',
      pathWidth: 5,
    );

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder:
          (context, url) =>
              Container(color: Colors.grey.withValues(alpha: 0.05)),
      errorWidget:
          (context, url, e) =>
              Container(color: Colors.grey.withValues(alpha: 0.05)),
    );
  }
}

