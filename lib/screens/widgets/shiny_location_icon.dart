import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ShinyLocationIcon extends StatefulWidget {
  final Color color;

  const ShinyLocationIcon({super.key, required this.color});

  @override
  State<ShinyLocationIcon> createState() => _ShinyLocationIconState();
}

class _ShinyLocationIconState extends State<ShinyLocationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scheduleRandomRotation();
  }

  void _scheduleRandomRotation() {
    int delay = 2000 + _random.nextInt(4000);

    Timer(Duration(milliseconds: delay), () async {
      if (!mounted) return;

      await _controller.forward(from: 0.0);

      _scheduleRandomRotation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(_controller.value * 2 * pi), // 3D Y-axis rotation
          child: Icon(
            SolarIconsBold.mapPoint,
            color: widget.color,
            size: 32,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
