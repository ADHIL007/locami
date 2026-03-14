import 'package:flutter/material.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:locami/screens/widgets/speedometer.dart';
import 'package:locami/core/utils/trip_simulator.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class TripInfoDisplay extends StatelessWidget {
  static const bool _showSimulation =
      true; //simulation set to false to disable simulation

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

        final rawSpeed = details.speed < 0 ? 0.0 : details.speed;
        final speedKmh = (rawSpeed * 3.6);
        final remainingKm = (details.remainingDistance ?? 0) / 1000;
        final activityLabel = _getActivityLabel(speedKmh);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: Speedometer(speed: speedKmh, maxSpeed: 140),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  remainingKm.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: customColors().textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "km From Destination",
                  style: TextStyle(
                    fontSize: 14,
                    color: customColors().textPrimary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.gps_fixed,
                  size: 12,
                  color: customColors().textPrimary.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  "$activityLabel, GPS Active",
                  style: TextStyle(
                    fontSize: 12,
                    color: customColors().textPrimary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildAlertProgress(details, accentColor),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (kDebugMode && _showSimulation) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () => TripSimulator.simulateMoveTowards(),
                      icon: const Icon(Icons.fast_forward, size: 16),
                      label: const Text("10% Closer"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () => TripSimulator.simulateArrival(),
                      icon: const Icon(Icons.location_on, size: 16),
                      label: const Text("Simulate Arrival"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAlertProgress(TripDetailsModel details, Color accentColor) {
    final alertDistance = TripDetailsManager.instance.alertDistance ?? 500.0;
    final remaining = details.remainingDistance ?? 0.0;
    final total =
        details.totalDistance ?? (details.distanceTraveled ?? 0) + remaining;

    double progress = 0.0;
    if (total > 0) {
      progress = (details.distanceTraveled ?? 0) / total;
    }
    progress = progress.clamp(0.0, 1.0);

    String alertText;
    if (remaining > alertDistance) {
      final toAlert = remaining - alertDistance;
      if (toAlert >= 1000) {
        alertText = "${(toAlert / 1000).toStringAsFixed(1)} km";
      } else {
        alertText = "${toAlert.toStringAsFixed(0)} m";
      }
    } else {
      alertText = "Alert Triggered";
    }

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
                Icons.notifications_active_outlined,
                size: 16,
                color: accentColor,
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
              alertText,
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
            value: progress,
            backgroundColor: customColors().textPrimary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${((details.distanceTraveled ?? 0) / 1000).toStringAsFixed(1)} km traveled",
              style: TextStyle(
                fontSize: 12,
                color: customColors().textPrimary.withOpacity(0.5),
              ),
            ),
            Text(
              "${(progress * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
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
