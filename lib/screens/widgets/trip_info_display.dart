import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:locami/modules/home/controllers/home_controller.dart';
import 'package:locami/core/utils/environment.dart';
import 'package:locami/core/utils/trip_simulator.dart';
import 'package:locami/core/widgets/glass_container.dart';

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
    final isDark = themeProvider.theme == AppThemeMode.dark;
    final homeController = Get.find<HomeController>();

    // Dynamic colors
    final glassColor = isDark ? Colors.black : Colors.white;
    final glassOpacity = isDark ? 0.3 : 0.7;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.45) : Colors.black54;
    final handleColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1);
    final trackBgColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Obx(() {
      // Touch smoothedSpeed to subscribe to changes
      final _ = homeController.smoothedSpeed.value;
      return ValueListenableBuilder<TripDetailsModel?>(
      valueListenable: TripDetailsManager.instance.currentTripDetail,
      builder: (context, details, __) {
        if (details == null) {
          return GlassContainer(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(32),
            opacity: glassOpacity,
            blur: 30,
            color: glassColor,
            borderRadius: 32,
            child: Center(
              child: CircularProgressIndicator(color: isDark ? Colors.white54 : accentColor),
            ),
          );
        }

        final remainingKm = (details.remainingDistance ?? 0) / 1000;
        final total = details.totalDistance ?? 0.0;
        final remaining = details.remainingDistance ?? 0.0;
        // Use smoothed speed from controller (not raw GPS)
        final rawSpeed = homeController.smoothedSpeed.value;
        final speedKmh = (rawSpeed * 3.6).round();
        final showSimulation =
            EnvironmentConfig.isDevelopment && themeProvider.enableSimulation;

        // ETA Calculation
        String etaText = '--';
        String statusText = 'waiting_for_movement'.tr;
        if (rawSpeed > 0.5 && remaining > 0) {
          final etaSeconds = remaining / rawSpeed;
          if (etaSeconds < 60) {
            etaText = 'less_than_1_min'.tr;
          } else if (etaSeconds < 3600) {
            final mins = (etaSeconds / 60).ceil();
            etaText = 'mins'.trParams({'mins': mins.toString()});
          } else {
            final hours = (etaSeconds / 3600).floor();
            final mins = ((etaSeconds % 3600) / 60).round();
            etaText = 'hours_mins'.trParams({'hours': hours.toString(), 'mins': mins.toString()});
          }
          statusText = 'moving_eta'.trParams({'eta': etaText});
        } else if (rawSpeed > 0.5) {
          statusText = 'moving'.tr;
        }

        double progressFactor = 0.0;
        if (total > 0) {
          progressFactor = ((total - remaining) / total).clamp(0.0, 1.0);
        } else if (remaining == 0) {
          progressFactor = 1.0;
        }

        return GlassContainer(
          color: glassColor,
          opacity: glassOpacity,
          blur: 30,
          customBorderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle bar ──
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Main Row: Info left, Gauge right ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Distance + destination
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    SolarIconsBold.mapPoint,
                                    color: accentColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'km_to_destination'.trParams({
                                      'km': remainingKm.toStringAsFixed(1),
                                      'destination': details.destination ?? 'destination_placeholder'.tr
                                    }),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: rawSpeed > 0.5 ? accentColor.withValues(alpha: 0.8) : subTextColor,
                                  fontSize: 13,
                                  fontWeight: rawSpeed > 0.5 ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Alert within label
                            Text(
                              'alert_when_within'.trParams({'distance': homeController.alertDistance.value.toString()}),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // ── Speed Gauge ──
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: CustomPaint(
                          painter: _GaugePainter(
                            speed: speedKmh,
                            maxSpeed: 120,
                            accentColor: accentColor,
                            isDark: isDark,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$speedKmh',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  'km_h'.tr,
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Icon(
                                  Icons.directions_car_rounded,
                                  color: accentColor,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Progress bar ──
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final thumbPos = (constraints.maxWidth * progressFactor)
                          .clamp(8.0, constraints.maxWidth - 8.0);
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Track background
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: trackBgColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Active track
                          Container(
                            height: 6,
                            width: thumbPos,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Thumb
                          Positioned(
                            left: thumbPos - 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── Remaining + ETA ──
                  Row(
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        color: subTextColor,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'km_remaining'.trParams({'km': remainingKm.toStringAsFixed(1)}),
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (rawSpeed > 0.5) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: subTextColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          SolarIconsOutline.clockCircle,
                          color: subTextColor,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          etaText,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── STOP BUTTON ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          homeController.isTrackingLoading.value
                              ? null
                              : homeController.toggleTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child:
                          homeController.isTrackingLoading.value
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_arrow_rounded, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'stop_alert'.tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Simulation buttons (dev only) ──
                  if (showSimulation) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => TripSimulator.simulateMoveTowards(),
                          child: Text(
                            'Closer',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                        TextButton(
                          onPressed: () => TripSimulator.simulateNearAlert(),
                          child: Text(
                            '505m',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                        TextButton(
                          onPressed: () => TripSimulator.simulateArrival(),
                          child: Text(
                            'Arrive',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
    });
  }
}

class _GaugePainter extends CustomPainter {
  final int speed;
  final int maxSpeed;
  final Color accentColor;
  final bool isDark;

  _GaugePainter({
    required this.speed,
    required this.maxSpeed,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background arc
    final bgPaint =
        Paint()
          ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    const startAngle = 2.3561944; // 135 degrees
    const sweepAngle = 4.712389; // 270 degrees

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active arc
    final activePaint =
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    final activeAngle = sweepAngle * (speed / maxSpeed).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeAngle,
      false,
      activePaint,
    );

    // Tick marks
    final tickPaint =
        Paint()
          ..color = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)
          ..strokeWidth = 1;

    const tickCount = 24;
    for (int i = 0; i <= tickCount; i++) {
      final angle = startAngle + (sweepAngle * i / tickCount);
      final outerPoint = Offset(
        center.dx + (radius + 2) * math.cos(angle),
        center.dy + (radius + 2) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // Small numbers at bottom: 0 and maxSpeed
    final subTxtColor = isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3);
    
    final textPainter0 = TextPainter(
      text: TextSpan(
        text: '0',
        style: TextStyle(
          color: subTxtColor,
          fontSize: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter0.layout();
    textPainter0.paint(
      canvas,
      Offset(center.dx - radius + 2, center.dy + radius - 14),
    );

    final textPainterMax = TextPainter(
      text: TextSpan(
        text: '$maxSpeed',
        style: TextStyle(
          color: subTxtColor,
          fontSize: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterMax.layout();
    textPainterMax.paint(
      canvas,
      Offset(center.dx + radius - 18, center.dy + radius - 14),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.speed != speed || oldDelegate.accentColor != accentColor || oldDelegate.isDark != isDark;
}
