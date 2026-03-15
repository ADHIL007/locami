import 'package:flutter/material.dart';
import 'dart:math' as math;

class ReflectionBackground extends StatefulWidget {
  final Color accentColor;
  final double speed;
  const ReflectionBackground({
    super.key,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<ReflectionBackground> createState() => _ReflectionBackgroundState();
}

class _ReflectionBackgroundState extends State<ReflectionBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Stopwatch _stopwatch = Stopwatch();
  late List<Circle> _circles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _stopwatch.start();

    _circles = List.generate(8, (index) => Circle.random(index));
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ReflectionPainter(
            time: _stopwatch.elapsedMilliseconds / 1000.0 * widget.speed,
            accentColor: widget.accentColor,
            circles: _circles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Circle {
  final double startX;
  final double startY;
  final double size;
  final double moveSpeedX;
  final double moveSpeedY;
  final double phase;
  final double pulseSpeed;
  final int id;

  Circle.random(this.id)
    : startX = math.Random(id * 10).nextDouble(),
      startY = math.Random(id * 10 + 1).nextDouble(),
      size = math.Random(id * 10 + 2).nextDouble() * 0.3 + 0.2,
      moveSpeedX = math.Random(id * 10 + 3).nextDouble() * 0.15 + 0.05,
      moveSpeedY = math.Random(id * 10 + 4).nextDouble() * 0.15 + 0.05,
      phase = math.Random(id * 10 + 5).nextDouble() * 2 * math.pi,
      pulseSpeed = math.Random(id * 10 + 6).nextDouble() * 0.4 + 0.2;
}

class ReflectionPainter extends CustomPainter {
  final double time;
  final Color accentColor;
  final List<Circle> circles;

  ReflectionPainter({
    required this.time,
    required this.accentColor,
    required this.circles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final sortedCircles = List.from(circles)
      ..sort((a, b) => b.size.compareTo(a.size));

    for (final circle in sortedCircles) {
      _drawSmoothBlob(canvas, size, circle);
    }
  }

  void _drawSmoothBlob(Canvas canvas, Size size, Circle circle) {
    double xOffset = math.sin(time * circle.moveSpeedX + circle.phase) * 0.25;
    double yOffset =
        math.cos(time * circle.moveSpeedY + circle.phase * 1.5) * 0.25;

    xOffset += math.sin(time * 0.3 + circle.id) * 0.1;
    yOffset += math.cos(time * 0.2 + circle.id * 0.5) * 0.1;

    double screenX = (circle.startX + xOffset).clamp(-0.5, 1.5) * size.width;
    double screenY = (circle.startY + yOffset).clamp(-0.5, 1.5) * size.height;

    double baseRadius =
        (size.width > size.height ? size.width : size.height) * circle.size;

    double pulse = math.sin(time * circle.pulseSpeed + circle.id) * 0.1 + 1.0;
    double pulsedRadius = baseRadius * pulse;

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [
        accentColor.withValues(alpha: 0.12),
        accentColor.withValues(alpha: 0.06),
        accentColor.withValues(alpha: 0.02),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.8, 1.0],
    );

    final paint =
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(
              center: Offset(screenX, screenY),
              radius: pulsedRadius,
            ),
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, pulsedRadius * 0.4);

    canvas.drawCircle(Offset(screenX, screenY), pulsedRadius, paint);

    final highlightPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.015)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(
      Offset(screenX - pulsedRadius * 0.2, screenY - pulsedRadius * 0.2),
      pulsedRadius * 0.3,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ReflectionPainter oldDelegate) {
    return true;
  }
}
