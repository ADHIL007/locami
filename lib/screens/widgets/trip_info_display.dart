import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:locami/db_manager/user_model_manager.dart';
import 'package:locami/screens/widgets/speedometer.dart';
import 'package:locami/core/utils/trip_simulator.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:locami/core/utils/environment.dart';

class TripInfoDisplay extends StatefulWidget {
  const TripInfoDisplay({super.key});

  @override
  State<TripInfoDisplay> createState() => _TripInfoDisplayState();
}

class _TripInfoDisplayState extends State<TripInfoDisplay> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    return ValueListenableBuilder<TripDetailsModel?>(
      valueListenable: TripDetailsManager.instance.currentTripDetail,
      builder: (context, details, _) {
        if (details == null) {
          return FutureBuilder(
            future: UserModelManager.instance.user,
            builder: (context, snapshot) {
              final destination = snapshot.data?.destinationStreet ?? "Destination";
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: SizedBox(
                      height: 180,
                      width: 180,
                      child: Speedometer(speed: 0, maxSpeed: 140),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Waiting for GPS...",
                    style: TextStyle(
                      fontSize: 18,
                      color: customColors().textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: customColors().textPrimary.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: customColors().textPrimary.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          SolarIconsOutline.mapPoint,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: customColors().textPrimary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }

        final rawSpeed = details.speed < 0 ? 0.0 : details.speed;
        final speedKmh = (rawSpeed * 3.6);
        final remainingKm = (details.remainingDistance ?? 0) / 1000;
        final activityLabel = _getActivityLabel(speedKmh);
        final etaText = _getETADisplay(details.remainingDistance ?? 0, rawSpeed);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Center(
                  child: SizedBox(
                    height: 180,
                    width: 180,
                    child: Speedometer(speed: speedKmh, maxSpeed: 140),
                  ),
                ),
                const SizedBox(height: 12),
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
                      "km to go",
                      style: TextStyle(
                        fontSize: 14,
                        color: customColors().textPrimary.withValues(
                          alpha: 0.7,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      SolarIconsOutline.gps,
                      size: 12,
                      color: customColors().textPrimary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$activityLabel, GPS Active",
                      style: TextStyle(
                        fontSize: 12,
                        color: customColors().textPrimary.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: customColors().textPrimary.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: customColors().textPrimary.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            SolarIconsOutline.mapPoint,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              details.street ?? "Determining location...",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: customColors().textPrimary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            SolarIconsOutline.clockCircle,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Will reach in:",
                            style: TextStyle(
                              fontSize: 13,
                              color: customColors().textPrimary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            etaText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: customColors().textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Column(children: [_buildAlertProgress(details, accentColor)]),
            const SizedBox(height: 24),

            if (EnvironmentConfig.isDevelopment &&
                context.watch<ThemeProvider>().enableSimulation) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => TripSimulator.simulateNearAlert(),
                      icon: const Icon(SolarIconsOutline.bell, size: 16),
                      label: const Text("505m Away"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => TripSimulator.simulateMoveTowards(),
                      icon: const Icon(
                        SolarIconsOutline.playbackSpeed,
                        size: 16,
                      ),
                      label: const Text("10% Closer"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => TripSimulator.simulateArrival(),
                      icon: const Icon(SolarIconsBold.mapPoint, size: 16),
                      label: const Text("Arrive"),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                SolarIconsBold.bellBing,
                size: 20,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Alerting in",
              style: TextStyle(
                fontSize: 18,
                color: customColors().textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const Spacer(),
            Text(
              alertText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: customColors().textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: customColors().textPrimary.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${((details.distanceTraveled ?? 0) / 1000).toStringAsFixed(1)} km traveled",
              style: TextStyle(
                fontSize: 12,
                color: customColors().textPrimary.withValues(alpha: 0.5),
              ),
            ),
            Text(
              "${(progress * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getETADisplay(double remainingMeters, double speedMs) {
    if (speedMs < 0.2) return "--";
    final seconds = remainingMeters / speedMs;
    final duration = Duration(seconds: seconds.toInt());

    if (duration.inHours > 0) {
      return "${duration.inHours} hr ${duration.inMinutes.remainder(60)} min";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes} minute";
    } else if (duration.inSeconds > 10) {
      return "less than 1 min";
    } else {
      return "Arriving now";
    }
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
