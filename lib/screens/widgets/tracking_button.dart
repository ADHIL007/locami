import 'package:flutter/material.dart';
import 'package:locami/theme/them_provider.dart';

class TrackingButton extends StatelessWidget {
  final bool isTracking;
  final bool canStart;
  final Color accentColor;
  final VoidCallback onPressed;

  final bool isLoading;

  const TrackingButton({
    Key? key,
    required this.isTracking,
    this.canStart = true,
    this.isLoading = false,
    required this.accentColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (isTracking || canStart) && !isLoading ? 1 : 0.5,
      child: AbsorbPointer(
        absorbing: (!isTracking && !canStart) || isLoading,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: customColors().textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            minimumSize: const Size(120, 40),
          ),
          child:
              isLoading
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        customColors().textPrimary,
                      ),
                    ),
                  )
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTracking ? Icons.stop : Icons.play_arrow,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isTracking ? "Stop" : "Start Tracking",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: customColors().textPrimary,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
