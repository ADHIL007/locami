import 'package:flutter/material.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:locami/core/utils/map_utils.dart';

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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: customColors().textPrimary.withOpacity(0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF66BB6A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
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
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              "You've arrived at your destination",
              style: TextStyle(
                color: customColors().textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            
            // Map Clip
            if (trip != null) 
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 140,
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
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onThanks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customColors().textPrimary.withOpacity(0.1),
                        foregroundColor: customColors().textPrimary,
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
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935), // Red from image
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
      return Container(color: Colors.grey.withOpacity(0.2));
    }

    final double startLat = trip.latitude;
    final double startLon = trip.longitude;
    final double endLat = trip.destinationLatitude!;
    final double endLon = trip.destinationLongitude!;

    final double centerLat = (startLat + endLat) / 2;
    final double centerLon = (startLon + endLon) / 2;

    final double dist = MapUtils.distanceInKm(startLat, startLon, endLat, endLon);
    final int zoom = MapUtils.calculateZoom(dist);

    final String url =
        "https://static-maps.yandex.ru/1.x/"
        "?l=map"
        "&lang=en_US"
        "&size=450,200"
        "&scale=2"
        "&z=$zoom"
        "&ll=$centerLon,$centerLat"
        "&pt=$startLon,$startLat,pm2blm~$endLon,$endLat,pm2rdm"
        "&pl=c:1A73E8,w:5,$startLon,$startLat,$endLon,$endLat";

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.grey.withOpacity(0.1)),
      errorWidget: (context, url, e) => Container(color: Colors.grey.withOpacity(0.1)),
    );
  }
}
