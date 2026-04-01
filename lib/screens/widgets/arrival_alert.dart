import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:locami/db_manager/user_model_manager.dart';
import 'package:locami/core/widgets/glass_container.dart';
import 'package:locami/theme/theme_provider.dart';

class ArrivalAlert extends StatefulWidget {
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
  State<ArrivalAlert> createState() => _ArrivalAlertState();
}

class _ArrivalAlertState extends State<ArrivalAlert> {
  String fromLocation = "Unknown Location";
  String timeTaken = "Calculating...";
  String distanceText = "Calculating...";

  @override
  void initState() {
    super.initState();
    // Hide status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadTripData();
  }

  @override
  void dispose() {
    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadTripData() async {
    final trip = TripDetailsManager.instance.currentTripDetail.value;
    final user = await UserModelManager.instance.user;

    setState(() {
      fromLocation = user.fromStreet ?? "Starting Point";
      
      final durationSecs = trip?.totalDuration ?? 
         ((user.startTime != null) ? DateTime.now().difference(user.startTime!).inSeconds.toDouble() : 0.0);
      
      final hours = (durationSecs / 3600).floor();
      final mins = ((durationSecs % 3600) / 60).round();
      timeTaken = hours > 0 ? "$hours hr $mins min" : "$mins min";
      
      final distMeters = trip?.distanceTraveled ?? 0.0;
      if (distMeters < 1000) {
        distanceText = "${distMeters.round()} m";
      } else {
        distanceText = "${(distMeters / 1000).toStringAsFixed(1)} km";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.instance;
    final isDark = themeProvider.theme == AppThemeMode.dark;
    final accentColor = themeProvider.accentColor;
    
    // Animate background gradient based on accent color
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Gradient Ambient Glow
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Success Icon with Glow
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      SolarIconsBold.checkCircle,
                      color: Color(0xFF4CAF50),
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Reached Text
                  Text(
                    "You've Arrived!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: customColors().textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    "Destination successfully reached.",
                    style: TextStyle(
                      color: customColors().textSecondary.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Stats Glass Container
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    opacity: isDark ? 0.2 : 0.7,
                    blur: 30,
                    borderRadius: 24,
                    color: isDark ? Colors.black : Colors.white,
                    border: Border.all(
                      color: customColors().textPrimary.withValues(alpha: 0.05),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(SolarIconsOutline.mapPoint, "From", fromLocation),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, thickness: 1),
                        ),
                        _buildDetailRow(SolarIconsOutline.mapArrowUp, "To", widget.destination),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, thickness: 1),
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildDetailRow(SolarIconsOutline.routing2, "Distance", distanceText)),
                            Container(width: 1, height: 40, color: customColors().textSecondary.withValues(alpha: 0.2)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDetailRow(SolarIconsOutline.stopwatch, "Time", timeTaken)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Premium Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: TextButton(
                            onPressed: widget.onThanks,
                            style: TextButton.styleFrom(
                              backgroundColor: customColors().textPrimary.withValues(alpha: 0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              "Snooze",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: customColors().textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: widget.onDone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 10,
                              shadowColor: accentColor.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              "Dismiss Alarm",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ThemeProvider.instance.accentColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: customColors().textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: customColors().textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
