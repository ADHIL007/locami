import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/modules/home/controllers/home_controller.dart';
import 'package:locami/core/widgets/glass_container.dart';
import 'package:locami/screens/widgets/tracking_button.dart';
import 'package:locami/screens/widgets/save_location_dialog.dart';

class SetupPanel extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final VoidCallback onSearchTap;

  const SetupPanel({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    
    return GlassContainer(
      customBorderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      opacity: isDark ? 0.25 : 0.65,
      blur: 40,
      color: isDark ? Colors.black : Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.06,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        SolarIconsBold.mapPoint,
                        color: accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Obx(
                          () => Text(
                            controller.toAddress.value.isEmpty
                                ? 'where_are_you_going'.tr
                                : controller.toAddress.value,
                            style: TextStyle(
                              color:
                                  controller.toAddress.value.isEmpty
                                      ? (isDark
                                          ? Colors.white38
                                          : Colors.black38)
                                      : (isDark ? Colors.white : Colors.black),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Obx(() => controller.toAddress.value.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                controller.clearDestination();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                                child: Icon(
                                  SolarIconsBold.closeCircle,
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                                  size: 20,
                                ),
                              ),
                            )
                          : Icon(
                              SolarIconsOutline.altArrowRight,
                              color: isDark ? Colors.white24 : Colors.black12,
                              size: 18,
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.toAddress.value.isEmpty || controller.destinationLatitude.value == null) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () async {
                      final result = await SaveLocationDialog.show(
                        Get.context!,
                        displayName: controller.toAddress.value,
                        latitude: controller.destinationLatitude.value!,
                        longitude: controller.destinationLongitude.value!,
                      );
                      if (result != null) {
                        Get.snackbar(
                          'saved'.tr,
                          'location_saved'.trParams({'label': result.label}),
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          colorText: isDark ? Colors.white : Colors.black87,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(SolarIconsOutline.bookmark, size: 16, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'save_to_favorites'.tr,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Obx(
                () {
                  final options = [if (kDebugMode) 10, 500, 1000, 2000];
                  return Row(
                    children: options.map((dist) {
                      final isSelected = controller.alertDistance.value == dist;
                      String label;
                      if (dist == 10) {
                        label = "10m";
                      } else if (dist < 1000) {
                        label = "${dist}m";
                      } else {
                        label = "${dist ~/ 1000}km";
                      }

                      final isFirst = dist == options.first;
                      final isLast = dist == options.last;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setAlertDistance(dist),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                              left: isFirst ? 0 : 6,
                              right: isLast ? 0 : 6,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? accentColor.withValues(alpha: 0.4) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? accentColor : (isDark ? Colors.white70 : Colors.black54),
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              Obx(
                () => TrackingButton(
                  onPressed: controller.toggleTracking,
                  isTracking: false,
                  isLoading: controller.isTrackingLoading.value,
                  canStart: controller.toAddress.value.isNotEmpty,
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
