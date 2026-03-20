import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/modules/home/controllers/home_controller.dart';
import 'package:locami/core/widgets/glass_container.dart';

class MapCenterConfirmPanel extends StatelessWidget {
  final Color accentColor;
  final bool isDark;

  const MapCenterConfirmPanel({
    super.key,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return GlassContainer(
      customBorderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      opacity: isDark ? 0.25 : 0.65,
      blur: 40,
      color: isDark ? Colors.black : Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Position destination at center pin",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                controller.selectCenterLocation();
                controller.isPinSelectionMode.value = false;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(SolarIconsBold.checkCircle, size: 22),
                  SizedBox(width: 12),
                  Text(
                    "Confirm Location",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
