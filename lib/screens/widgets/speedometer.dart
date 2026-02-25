import 'dart:math';
import 'package:flutter/material.dart';
import 'package:locami/theme/them_provider.dart';

class Speedometer extends StatelessWidget {
  final double speed;
  final double maxSpeed;

  const Speedometer({Key? key, required this.speed, this.maxSpeed = 180})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SpeedometerPainter(
              speed: speed,
              maxSpeed: maxSpeed,
              primaryColor: customColors().textPrimary,
              secondaryColor: customColors().textSecondary.withOpacity(0.2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    speed.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.bold,
                      color: customColors().textPrimary,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: TextStyle(
                      fontSize: size * 0.1,
                      color: customColors().textSecondary,
                    ),
                  ),
                ],
              ),
            ),
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

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.08;

    final startAngle = 135 * pi / 180;
    final sweepAngle = 270 * pi / 180;

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

    final progressPaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final progressRatio = (speed / maxSpeed).clamp(0.0, 1.0);
    final progressSweepAngle = sweepAngle * progressRatio;

    if (progressRatio > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        progressSweepAngle,
        false,
        progressPaint,
      );
    }

    final tickPaint =
        Paint()
          ..color = primaryColor.withOpacity(0.5)
          ..strokeWidth = 2;

    final tickCount = 9;
    final tickRadius = radius - strokeWidth - 10;

    for (int i = 0; i <= tickCount; i++) {
      final tickRatio = i / tickCount;
      final angle = startAngle + (sweepAngle * tickRatio);

      final p1 = Offset(
        center.dx + tickRadius * cos(angle),
        center.dy + tickRadius * sin(angle),
      );
      final p2 = Offset(
        center.dx + (tickRadius - 5) * cos(angle),
        center.dy + (tickRadius - 5) * sin(angle),
      );

      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed ||
        oldDelegate.maxSpeed != maxSpeed ||
        oldDelegate.primaryColor != primaryColor;
  }
}
