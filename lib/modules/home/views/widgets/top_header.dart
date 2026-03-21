import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/modules/home/controllers/home_controller.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (controller.isOnline.value) ...[
                    Icon(
                      SolarIconsBold.mapPoint,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isOnline.value
                            ? controller.currentLocationName.value.toLowerCase()
                            : (controller.currentLocationName.value ==
                                    "Locating..."
                                ? ""
                                : controller.currentLocationName.value
                                    .toLowerCase()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      Text(
                        controller.isOnline.value
                            ? "Current location"
                            : (controller.currentLocationName.value ==
                                    "Locating..."
                                ? ""
                                : "Last updated location"),
                        style: const TextStyle(
                          color: Color(0xFF90A4AE), // secondary color
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  if (!controller.isOnline.value) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            color: Colors.red.withValues(alpha: 0.8),
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "OFFLINE",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
