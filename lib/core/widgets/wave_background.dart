import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveBackground extends StatefulWidget {
  final Color accentColor;
  const WaveBackground({Key? key, required this.accentColor}) : super(key: key);

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
          painter: WavePainter(
            animationValue: _controller.value,
            color: widget.accentColor.withOpacity(0.2),
          ),
          child: Container(),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  WavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Bottom Wave (Deep)
    path.moveTo(0, size.height * 0.7);
    for (double i = 0; i <= size.width; i++) {
        double dx = (i / size.width * 2 * math.pi);
        double dy = math.sin(dx + (animationValue * 2 * math.pi)) * 40;
        path.lineTo(i, size.height * 0.8 + dy);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Top Wave (Deeper)
    final path2 = Path();
    paint.color = color.withOpacity(0.08);
    path2.moveTo(0, size.height * 0.3);
    for (double i = 0; i <= size.width; i++) {
        double dx = (i / size.width * 2 * math.pi);
        double dy = math.cos(dx + (animationValue * 2 * math.pi)) * 50;
        path2.lineTo(i, size.height * 0.2 + dy);
    }
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();
    canvas.drawPath(path2, paint);

    // Middle Floating Wave
    final path3 = Path();
    paint.color = color.withOpacity(0.04);
    path3.moveTo(0, size.height * 0.5);
    for (double i = 0; i <= size.width; i++) {
        double dx = (i / size.width * 1.5 * math.pi);
        double dy = math.sin(dx - (animationValue * 2 * math.pi)) * 60;
        path3.lineTo(i, size.height * 0.5 + dy);
    }
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
