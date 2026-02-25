import 'package:flutter/material.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:locami/screens/widgets/speedometer.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';

class TripInfoDisplay extends StatelessWidget {
  const TripInfoDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeProvider>().accentColor;
    return ValueListenableBuilder<TripDetailsModel?>(
      valueListenable: TripDetailsManager.instance.currentTripDetail,
      builder: (context, details, _) {
        if (details == null) {
          return const SizedBox.shrink();
        }

        final speedKmh = (details.speed * 3.6);
        final remainingKm = (details.remainingDistance ?? 0) / 1000;
        final activityLabel = _getActivityLabel(speedKmh);

        return Column(
          children: [
            Center(
              child: SizedBox(
                height: 250,
                width: 250,
                child: Speedometer(speed: speedKmh, maxSpeed: 140),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  remainingKm.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: customColors().textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "km From Destination",
                  style: TextStyle(
                    fontSize: 16,
                    color: customColors().textPrimary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.gps_fixed,
                  size: 14,
                  color: customColors().textPrimary.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  "$activityLabel, GPS Active",
                  style: TextStyle(
                    fontSize: 14,
                    color: customColors().textPrimary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
            // const SizedBox(height: 24),
            // _buildSectionHeader("Current Location"),
            // const SizedBox(height: 16),
            // _buildLocationRow(
            //   icon: Icons.location_on_outlined,
            //   label: "Coordinates",
            //   value:
            //       "${details.latitude.toStringAsFixed(4)}, ${details.longitude.toStringAsFixed(4)}",
            //   trailing: "± ${details.accuracy.toStringAsFixed(1)} m",
            // ),
            // const SizedBox(height: 12),
            // _buildLocationRow(
            //   icon: Icons.height,
            //   label: "Altitude",
            //   value: "${details.altitude.toStringAsFixed(0)} m",
            // ),
            // const SizedBox(height: 40),
            _buildAlertProgress(accentColor),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => TripDetailsManager.instance.stopTracking(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: customColors().textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: customColors().textPrimary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.stop, size: 14),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Stop Tracking",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: customColors().textPrimary,
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String value,
    String? trailing,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: customColors().textPrimary.withOpacity(0.5),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: customColors().textPrimary.withOpacity(0.5),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: customColors().textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          Icon(
            Icons.swap_vert,
            size: 14,
            color: customColors().textPrimary.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 13,
              color: customColors().textPrimary.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertProgress(Color accentColor) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: customColors().textPrimary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.download,
                size: 16,
                color: customColors().textPrimary.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Alerting in",
              style: TextStyle(
                fontSize: 18,
                color: customColors().textPrimary.withOpacity(0.7),
              ),
            ),
            const Spacer(),
            Text(
              "500 m",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: customColors().textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.8, // Static for now matching screenshot
            backgroundColor: customColors().textPrimary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _getActivityLabel(double speedKmh) {
    if (speedKmh < 1) return "Idle";
    if (speedKmh < 6) return "Walking";
    if (speedKmh < 12) return "Running";
    if (speedKmh < 35) return "Cycling";
    if (speedKmh < 80) return "Motorcycle";
    return "Car";
  }
}
