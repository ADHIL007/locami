import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveBackground extends StatefulWidget {
  final Color accentColor;
  final double speed;
  const WaveBackground({Key? key, required this.accentColor, this.speed = 1.0})
    : super(key: key);

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: EnhancedWavePainter(
            animationValue: _controller.value * widget.speed,
            color: widget.accentColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class EnhancedWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  EnhancedWavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.2),
        color.withOpacity(0.05),
      ],
    );

    _drawWave(
      canvas: canvas,
      size: size,
      amplitude: size.height * 0.04,
      frequency: 1.8,
      phase: animationValue * 2 * math.pi,
      verticalOffset: size.height * 0.85,
      color: color.withOpacity(0.15),
      gradient: gradient,
      isInverted: false,
    );

    _drawWave(
      canvas: canvas,
      size: size,
      amplitude: size.height * 0.03,
      frequency: 2.2,
      phase: -animationValue * 2.2 * math.pi,
      verticalOffset: size.height * 0.7,
      color: color.withOpacity(0.12),
      gradient: gradient,
      isInverted: false,
    );

    _drawWave(
      canvas: canvas,
      size: size,
      amplitude: size.height * 0.02,
      frequency: 3.0,
      phase: animationValue * 3 * math.pi,
      verticalOffset: size.height * 0.5,
      color: color.withOpacity(0.1),
      gradient: gradient,
      isInverted: false,
    );

    _drawWave(
      canvas: canvas,
      size: size,
      amplitude: size.height * 0.015,
      frequency: 2.5,
      phase: animationValue * 2.5 * math.pi + 1.5,
      verticalOffset: size.height * 0.3,
      color: color.withOpacity(0.08),
      gradient: gradient,
      isInverted: true,
    );

    _drawParticles(canvas, size);
  }

  void _drawWave({
    required Canvas canvas,
    required Size size,
    required double amplitude,
    required double frequency,
    required double phase,
    required double verticalOffset,
    required Color color,
    required Gradient gradient,
    bool isInverted = false,
  }) {
    final paint =
        Paint()
          ..shader = gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height),
          )
          ..style = PaintingStyle.fill;

    final path = Path();
    final double startY = verticalOffset;

    path.moveTo(0, startY);

    for (double x = 0; x <= size.width; x += 1.0) {
      double t = x / size.width;

      double y1 = math.sin(t * 2 * math.pi * frequency + phase) * amplitude;
      double y2 =
          math.sin(t * 4 * math.pi * frequency + phase * 1.5) *
          (amplitude * 0.3);
      double y3 =
          math.cos(t * 3 * math.pi * frequency + phase * 0.7) *
          (amplitude * 0.2);

      double y = startY + y1 + y2 + y3;

      if (isInverted) {
        y = startY - (y1 + y2 + y3);
      }

      path.lineTo(x, y);
    }

    if (isInverted) {
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawParticles(Canvas canvas, Size size) {
    final particlePaint =
        Paint()
          ..color = color.withOpacity(0.02)
          ..style = PaintingStyle.fill;

    final random = math.Random(42);

    for (int i = 0; i < 20; i++) {
      double x =
          (random.nextDouble() * size.width +
              animationValue * size.width * 0.1) %
          size.width;
      double y = random.nextDouble() * size.height;
      double radius = random.nextDouble() * 2 + 0.5;

      double moveX = math.sin(animationValue * 2 * math.pi + i) * 3;
      double moveY = math.cos(animationValue * 2 * math.pi + i) * 3;

      canvas.drawCircle(
        Offset((x + moveX) % size.width, (y + moveY) % size.height),
        radius,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
