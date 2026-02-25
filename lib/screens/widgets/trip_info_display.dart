import 'package:flutter/material.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:locami/screens/widgets/speedometer.dart';
import 'package:locami/theme/them_provider.dart';

class TripInfoDisplay extends StatelessWidget {
  const TripInfoDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TripDetailsModel?>(
      valueListenable: TripDetailsManager.instance.currentTripDetail,
      builder: (context, details, _) {
        if (details == null) {
          return Center(
            child: Text(
              'No active trip',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: customColors().textSecondary,
              ),
            ),
          );
        }

        final speedKmh = (details.speed * 3.6);
        final remainingKm = (details.remainingDistance ?? 0) / 1000;
        final gForce = (details.acceleration ?? 0) / 9.81;
        final activityIcon = _getActivityIcon(gForce, speedKmh);
        final activityLabel = _getActivityLabel(gForce, speedKmh);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: Speedometer(speed: speedKmh, maxSpeed: 140),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bigMetric(
                    label: "Remaining",
                    value: remainingKm.toStringAsFixed(2),
                    unit: "km",
                  ),
                  Column(
                    children: [
                      Icon(
                        activityIcon,
                        size: 50,
                        color: customColors().textPrimary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activityLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: customColors().textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Location",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: customColors().textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _infoLine("Country", details.country ?? "Unknown"),
              _infoLine(
                "Coordinates",
                "${details.latitude.toStringAsFixed(4)}, ${details.longitude.toStringAsFixed(4)}",
              ),
              _infoLine("Street", details.street ?? "Fetching..."),

              const SizedBox(height: 20),

              Divider(color: customColors().borderColor),

              const SizedBox(height: 10),

              _infoLine("Accuracy", "${details.accuracy.toStringAsFixed(1)} m"),
              _infoLine("Altitude", "${details.altitude.toStringAsFixed(1)} m"),
              _infoLine("Heading", "${details.heading.toStringAsFixed(0)}°"),
              _infoLine("G-force", "${gForce.toStringAsFixed(1)} g"),
            ],
          ),
        );
      },
    );
  }

  IconData _getActivityIcon(double gForce, double speedKmh) {
    if (speedKmh < 1 && gForce < 0.03) {
      return Icons.bed;
    }

    if (speedKmh < 1) {
      return Icons.accessibility_new;
    }

    if (speedKmh < 6) {
      return Icons.directions_walk;
    }

    if (speedKmh < 12) {
      return Icons.directions_run;
    }

    if (speedKmh < 25) {
      return Icons.directions_bike;
    }

    if (speedKmh < 35) {
      return Icons.electric_scooter;
    }

    if (speedKmh < 80) {
      return Icons.motorcycle;
    }

    if (speedKmh < 160) {
      return Icons.directions_car;
    }

    if (speedKmh < 250) {
      return Icons.train;
    }

    if (speedKmh >= 250) {
      return Icons.flight;
    }

    return Icons.help_outline;
  }

  String _getActivityLabel(double gForce, double speedKmh) {
    if (gForce > 2.5) return "High Impact";

    if (speedKmh < 1 && gForce < 0.03) return "Idle";
    if (speedKmh < 1) return "Standing";
    if (speedKmh < 6) return "Walking";
    if (speedKmh < 12) return "Running";
    if (speedKmh < 25) return "Cycling";
    if (speedKmh < 35) return "E-Scooter";
    if (speedKmh < 80) return "Motorcycle";
    if (speedKmh < 160) return "Car";
    if (speedKmh < 250) return "Train";
    if (speedKmh >= 250) return "Flight";

    return "Unknown";
  }

  Widget _bigMetric({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: customColors().textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w600,
                color: customColors().textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 16,
                  color: customColors().textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: customColors().textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: customColors().textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
