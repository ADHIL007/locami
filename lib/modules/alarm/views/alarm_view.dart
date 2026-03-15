import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:get/get.dart';
import 'package:locami/modules/alarm/controllers/alarm_controller.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:locami/core/widgets/glass_container.dart';

class AlarmView extends GetView<AlarmController> {
  const AlarmView({super.key});

  @override
  Widget build(BuildContext context) {
    // We can put the controller if it's not already there
    final controller = Get.put(AlarmController());
    final colors = customColors();
    final accentColor = ThemeProvider.instance.accentColor;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5 * controller.animationController.value),
                          blurRadius: 50 * controller.animationController.value,
                          spreadRadius: 20 * controller.animationController.value,
                        ),
                      ],
                    ),
                    child: Icon(
                      SolarIconsBold.mapPoint,
                      size: 100,
                      color: accentColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              Text(
                'Destination Reached!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You have successfully arrived.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 64),
              GestureDetector(
                onTap: controller.dismiss,
                child: GlassContainer(
                  height: 60,
                  width: 200,
                  color: accentColor,
                  opacity: 0.8,
                  blur: 10,
                  borderRadius: 30,
                  border: Border.all(color: Colors.white24),
                  child: const Center(
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
