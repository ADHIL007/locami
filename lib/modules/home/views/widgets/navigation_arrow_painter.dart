import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter that draws a Google Maps-style navigation arrow.
/// The arrow points in the direction of movement (heading in degrees).
class NavigationArrowPainter extends CustomPainter {
  final double heading;

  NavigationArrowPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4285F4).withValues(alpha: 0.18),
          const Color(0xFF4285F4).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(heading * math.pi / 180);

    const double arrowH = 26;
    const double arrowW = 12;
    const double notch = 8;

    final arrowPath = Path()
      ..moveTo(0, -arrowH)
      ..lineTo(arrowW, arrowH - notch)
      ..lineTo(0, arrowH - notch * 2)
      ..lineTo(-arrowW, arrowH - notch)
      ..close();

    canvas.save();
    canvas.translate(0, 2);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(arrowPath, shadowPaint);
    canvas.restore();

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(arrowPath, borderPaint);

    final arrowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5B9EF4),
          Color(0xFF4285F4),
          Color(0xFF3367D6),
        ],
      ).createShader(Rect.fromLTRB(-arrowW, -arrowH, arrowW, arrowH));
    canvas.drawPath(arrowPath, arrowPaint);

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(const Offset(0, 0), 3, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(NavigationArrowPainter oldDelegate) =>
      oldDelegate.heading != heading;
}
