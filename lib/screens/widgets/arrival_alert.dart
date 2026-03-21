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
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        opacity: isDark ? 0.25 : 0.65,
        blur: 40,
        borderRadius: 36,
        color: isDark ? Colors.black : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon with Glow
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                SolarIconsBold.checkCircle,
                color: Color(0xFF4CAF50),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),

            // Reached Text
            Text(
              "$destination Reached!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: customColors().textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              "You've arrived at your destination",
              style: TextStyle(
                color: customColors().textSecondary.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Map Clip with subtle glass border
            // if (trip != null)
            //   Container(
            //     height: 160,
            //     width: double.infinity,
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(24),
            //       border: Border.all(
            //         color: customColors().textPrimary.withValues(alpha: 0.08),
            //       ),
            //     ),
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(24),
            //       child: _buildMapSnippet(trip),
            //     ),
            //   ),

            // const SizedBox(height: 32),

            // Premium Glass-style Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: TextButton(
                      onPressed: onThanks,
                      style: TextButton.styleFrom(
                        backgroundColor: customColors().textPrimary.withValues(
                          alpha: 0.03,
                        ),
                        foregroundColor: customColors().textPrimary,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: customColors().textPrimary.withValues(
                              alpha: 0.05,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        "Snooze",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 13,
                          color: customColors().textPrimary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: accentColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "Dismiss Alarm",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 13,
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
