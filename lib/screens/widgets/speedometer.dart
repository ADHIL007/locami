import 'dart:math';
import 'package:flutter/material.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';

class Speedometer extends StatelessWidget {
  final double speed;
  final double maxSpeed;

  const Speedometer({Key? key, required this.speed, this.maxSpeed = 180})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeProvider>().accentColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _SpeedometerPainter(
                  speed: speed,
                  maxSpeed: maxSpeed,
                  primaryColor: accentColor,
                  secondaryColor: customColors().textPrimary.withOpacity(0.05),
                  tickColor: customColors().textPrimary.withAlpha(50),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      speed.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.bold,
                        color: customColors().textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: size * 0.08,
                        color: customColors().textPrimary.withOpacity(0.5),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      Icons.home,
                      color: accentColor.withOpacity(0.8),
                      size: size * 0.15,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tickColor;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.12;

    final startAngle = 140 * pi / 180;
    final sweepAngle = 260 * pi / 180;

    // Draw background arc
    final backgroundPaint =
        Paint()
          ..color = secondaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Draw progress arc
    final progressRatio = (speed / maxSpeed).clamp(0.01, 1.0);
    final progressSweepAngle = sweepAngle * progressRatio;

    final progressPaint =
        Paint()
          ..color = customColors().textPrimary.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      progressSweepAngle,
      false,
      progressPaint,
    );

    // Draw ticks
    final tickPaint =
        Paint()
          ..color = tickColor
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

    final tickCount = 40;
    final innerRadius = radius - strokeWidth - 5;

    for (int i = 0; i <= tickCount; i++) {
      final tickRatio = i / tickCount;
      final angle = startAngle + (sweepAngle * tickRatio);

      // Vary tick length
      final isMajor = i % 5 == 0;
      final length = isMajor ? 8.0 : 4.0;

      final p1 = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );
      final p2 = Offset(
        center.dx + (innerRadius - length) * cos(angle),
        center.dy + (innerRadius - length) * sin(angle),
      );

      canvas.drawLine(p1, p2, tickPaint);
    }

    // Draw thumb
    final thumbAngle = startAngle + progressSweepAngle;
    final thumbCenter = Offset(
      center.dx + (radius - strokeWidth / 2) * cos(thumbAngle),
      center.dy + (radius - strokeWidth / 2) * sin(thumbAngle),
    );

    final thumbPaint =
        Paint()
          ..color = customColors().textPrimary
          ..style = PaintingStyle.fill;

    // Outer glow for thumb
    final glowPaint =
        Paint()
          ..color = customColors().textPrimary.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(thumbCenter, strokeWidth * 0.45, glowPaint);
    canvas.drawCircle(thumbCenter, strokeWidth * 0.35, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.maxSpeed != maxSpeed;
  }
}
