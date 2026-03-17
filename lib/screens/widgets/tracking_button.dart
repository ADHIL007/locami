import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class TrackingButton extends StatelessWidget {
  final bool isTracking;
  final bool canStart;
  final Color accentColor;
  final VoidCallback onPressed;

  final bool isLoading;
  final String? textOverride;

  const TrackingButton({
    super.key,
    required this.isTracking,
    this.canStart = true,
    this.isLoading = false,
    this.textOverride,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (isTracking || canStart) && !isLoading ? 1 : 0.5,
      child: AbsorbPointer(
        absorbing: (!isTracking && !canStart) || isLoading,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isTracking 
                  ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
                  : [accentColor, accentColor.withValues(alpha: 0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: (isTracking ? Colors.red : accentColor).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child:
                isLoading
                    ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isTracking ? SolarIconsBold.stop : SolarIconsBold.play,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          textOverride ?? (isTracking ? "Stop Tracking" : "Start Tracking"),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
