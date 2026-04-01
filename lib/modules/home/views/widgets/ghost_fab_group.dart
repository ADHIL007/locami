import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/modules/home/controllers/home_controller.dart';
import 'package:locami/core/widgets/glass_container.dart';
import 'package:locami/screens/widgets/settings_bottom_sheet.dart';

class GhostFABGroup extends StatelessWidget {
  final Color accentColor;

  const GhostFABGroup({
    super.key,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() => Column(
      children: [
        if (!controller.isTracking.value)
          _buildGhostBtn(
            onTap: () => controller.isPinSelectionMode.toggle(),
            customChild:
                controller.isPinSelectionMode.value
                    ? const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    )
                    : _buildMiniUberPin(),
            borderColor:
                controller.isPinSelectionMode.value
                    ? Colors.redAccent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.5),
          ),
        if (!controller.isTracking.value) const SizedBox(height: 16),
        if (!controller.isPinSelectionMode.value) ...[
          _buildGhostBtn(
            icon:
                controller.useSatelliteMap.value
                    ? SolarIconsBold.map
                    : SolarIconsOutline.map,
            onTap: controller.toggleMapStyle,
            isDisabled: !controller.isOnline.value,
          ),
          const SizedBox(height: 16),
          _buildGhostBtn(
            icon:
                controller.isMapDark.value
                    ? SolarIconsBold.moon
                    : SolarIconsOutline.sun,
            onTap: controller.toggleMapTheme,
            isDisabled: controller.useSatelliteMap.value || !controller.isOnline.value,
          ),
          const SizedBox(height: 16),
          _buildGhostBtn(
            icon: SolarIconsOutline.gps,
            onTap: controller.focusCurrentLocation,
          ),
          const SizedBox(height: 16),
          _buildGhostBtn(
            icon: SolarIconsBold.settings,
            onTap: () {
              Get.bottomSheet(
                const SettingsBottomSheet(),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
          ),
        ],
      ],
    ));
  }

  Widget _buildGhostBtn({
    IconData? icon,
    Widget? customChild,
    required VoidCallback onTap,
    Color? borderColor,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.3 : 1.0,
        child: GlassContainer(
        width: 54,
        height: 54,
        blur: 15,
        opacity: 0.2,
        borderRadius: 27,
        color: Colors.black,
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        padding: EdgeInsets.zero,
        child: Center(
          child:
              customChild ??
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.95),
                size: 26,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
        ),
        ),
      ),
    );
  }

  Widget _buildMiniUberPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.2),
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 2,
          height: 4,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}
