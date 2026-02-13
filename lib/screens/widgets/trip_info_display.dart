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
        final distanceKm = (details.distanceTraveled ?? 0) / 1000;
        final gForce = (details.acceleration ?? 0) / 9.81;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// --- SPEEDOMETER ---
              SizedBox(
                height: 200,
                width: 200,
                child: Speedometer(
                  speed: speedKmh,
                  maxSpeed: 140, // typical max for car
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bigMetric(
                    label: "Distance",
                    value: distanceKm.toStringAsFixed(2),
                    unit: "km",
                  ),
                  _bigMetric(
                    label: "G-Force",
                    value: gForce.toStringAsFixed(2),
                    unit: "g",
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// --- LOCATION INFO ---
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

              /// --- META DATA ---
              Divider(color: customColors().borderColor),

              const SizedBox(height: 10),

              _infoLine("Accuracy", "${details.accuracy.toStringAsFixed(1)} m"),
              _infoLine("Altitude", "${details.altitude.toStringAsFixed(1)} m"),
              _infoLine("Heading", "${details.heading.toStringAsFixed(0)}°"),
            ],
          ),
        );
      },
    );
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
