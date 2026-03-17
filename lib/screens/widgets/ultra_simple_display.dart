import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:locami/screens/widgets/tracking_button.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:locami/modules/home/controllers/home_controller.dart';

class UltraSimpleDisplay extends StatelessWidget {
  const UltraSimpleDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.theme == AppThemeMode.dark;
    final controller = Get.find<HomeController>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? const Color(0xFF020817) : Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated Glowing Bell
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOutSine,
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2 * value),
                          blurRadius: 40 * value,
                          spreadRadius: 10 * value,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    SolarIconsBold.bell,
                    size: 80,
                    color: accentColor,
                  ),
                ),
                onEnd: () {}, // No need for onEnd as we can use replay in future if needed
              ),
              
              const SizedBox(height: 48),
              
              const Text(
                "ALERT SET!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Obx(() => Text(
                "You'll be alerted when near ${controller.toAddress.value}\n(${controller.alertDistance.value}m away)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              )),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: TrackingButton(
                  isTracking: true,
                  isLoading: controller.isTrackingLoading.value,
                  accentColor: Colors.redAccent,
                  onPressed: controller.toggleTracking,
                  textOverride: "Stop Alert",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
