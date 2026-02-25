import 'package:flutter/material.dart';
import 'package:locami/theme/them_provider.dart';

class TrackingButton extends StatelessWidget {
  final bool isTracking;
  final bool canStart;
  final Color accentColor;
  final VoidCallback onPressed;

  const TrackingButton({
    Key? key,
    required this.isTracking,
    this.canStart = true,
    required this.accentColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (isTracking || canStart) ? 1 : 0.5,
      child: AbsorbPointer(
        absorbing: !isTracking && !canStart,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isTracking ? Colors.red.withOpacity(0.8) : accentColor,
            foregroundColor: customColors().textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          icon: Icon(isTracking ? Icons.stop : Icons.play_arrow, size: 18),
          label: Text(
            isTracking ? "Stop" : "Start Tracking",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: customColors().textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
