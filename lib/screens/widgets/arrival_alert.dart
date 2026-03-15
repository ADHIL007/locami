import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:locami/core/widgets/glass_container.dart';
import 'package:get/get.dart';
import 'package:locami/core/controllers/map_controller.dart';

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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        padding: const EdgeInsets.all(28),
        opacity: 0.8,
        blur: 25,
        borderRadius: 36,
        color: const Color(0xFF1A1A1A),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF66BB6A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x6666BB6A),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                SolarIconsBold.checkCircle,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Reached Text
            Text(
              "$destination Reached!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              "You've arrived at your destination",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Map Clip
            if (trip != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: _buildMapSnippet(trip),
                ),
              ),

            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: onThanks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "THANKS!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFB71C1C,
                        ).withValues(alpha: 0.8),
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
                          fontSize: 16,
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
      return Container(color: Colors.grey.withValues(alpha: 0.2));
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
              Container(color: Colors.grey.withValues(alpha: 0.1)),
      errorWidget:
          (context, url, e) =>
              Container(color: Colors.grey.withValues(alpha: 0.1)),
    );
  }
}
