import 'package:flutter/material.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:intl/intl.dart';

class TripHistoryCard extends StatelessWidget {
  final TripDetailsModel trip;

  const TripHistoryCard({Key? key, required this.trip}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(trip.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: customColors().textPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: customColors().textPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.destination ?? "Unknown Destination",
                      style: TextStyle(
                        color: customColors().textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: customColors().textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((trip.distanceTraveled ?? 0) > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat(
                  Icons.map_outlined,
                  "${((trip.distanceTraveled ?? 0) / 1000).toStringAsFixed(1)} km",
                  "Distance",
                ),
                _buildStat(
                  Icons.speed,
                  "${(trip.speed * 3.6).toStringAsFixed(0)} km/h",
                  "Avg Speed",
                ),
                _buildStat(
                  Icons.location_on_outlined,
                  trip.street?.split(',').first ?? "N/A",
                  "Location",
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: customColors().textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: customColors().textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: customColors().textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
