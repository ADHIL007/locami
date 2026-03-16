import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:get/get.dart';
import 'package:locami/modules/alarm/controllers/alarm_controller.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:locami/core/widgets/glass_container.dart';

class AlarmView extends GetView<AlarmController> {
  const AlarmView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is available but we might want to put it if not already
    final controller = Get.isRegistered<AlarmController>() 
        ? Get.find<AlarmController>() 
        : Get.put(AlarmController());
        
    final colors = customColors();
    final accentColor = ThemeProvider.instance.accentColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false, // PREVENT BACK BUTTON
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          // Optionally do nothing or show a message
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: Stack(
            children: [
              // Dynamic Background
              AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.5,
                        colors: [
                          accentColor.withValues(alpha: 0.15 + (0.1 * controller.animationController.value)),
                          colors.background,
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Floating Particles/Effects (Optional but adds to the "Separate" feel)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Glow Ring
                      AnimatedBuilder(
                        animation: controller.animationController,
                        builder: (context, child) {
                          return Container(
                            height: 280,
                            width: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.1),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                height: 230 + (20 * controller.animationController.value),
                                width: 230 + (20 * controller.animationController.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(
                                        alpha: 0.4 * controller.animationController.value,
                                      ),
                                      blurRadius: 60 * controller.animationController.value,
                                      spreadRadius: 10 * controller.animationController.value,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    SolarIconsBold.bellBing,
                                    size: 100,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Text info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            Text(
                              'DESTINATION REACHED',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'You have safely arrived at your destination.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 100),
                      
                      // Large, Easy to Click Dismiss Button
                      GestureDetector(
                        onTap: controller.dismissAndGoHome,
                        child: GlassContainer(
                          height: 80,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 60),
                          color: accentColor,
                          opacity: 0.9,
                          blur: 20,
                          borderRadius: 40,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          child: const Center(
                            child: Text(
                              'I AM HERE',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
