import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:get/get.dart';
import 'package:locami/core/widgets/reflector_bg.dart';
import 'package:locami/modules/home/controllers/home_controller.dart';
import 'package:locami/screens/widgets/trip_info_display.dart';
import 'package:locami/screens/widgets/home_header.dart';
import 'package:locami/screens/widgets/home_input_card.dart';
import 'package:locami/screens/widgets/home_distance_option.dart';
import 'package:locami/screens/widgets/tracking_button.dart';
import 'package:locami/screens/widgets/location_search_sheet.dart';
import 'package:locami/screens/widgets/trip_history_card.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:locami/core/widgets/glass_container.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  void _showLocationSearch(bool isFrom) {
    Get.bottomSheet(
      LocationSearchSheet(
        isFrom: isFrom,
        initialValue:
            isFrom
                ? controller.fromController.text
                : controller.toController.text,
        userCountry: controller.userCountry.value,
        currentPosition: controller.currentPosition.value,
        onSelected: (address) {
          if (isFrom) {
            controller.fromController.text = address;
          } else {
            controller.toController.text = address;
          }
          controller.update();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showAllHistory() {
    Get.bottomSheet(
      _HistoryBottomSheet(
        history: controller.tripHistory,
        onClear: () async {
          await TripDetailsManager.instance.clearLogs();
          controller.loadTripHistory();
          Get.back();
        },
        onRestart: (TripDetailsModel trip) {
          controller.fromController.text = trip.street ?? "";
          controller.toController.text = trip.destination ?? "";
          Get.back();
          controller.toggleTracking();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (themeProvider.showWaves)
            ReflectionBackground(accentColor: accentColor, speed: 1.0),

          Positioned.fill(
            child:
                themeProvider.showWaves
                    ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(
                                context,
                              ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                              accentColor.withValues(alpha: 0.04),
                              Theme.of(
                                context,
                              ).scaffoldBackgroundColor.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(
                              context,
                            ).scaffoldBackgroundColor.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => HomeHeader(
                      isTracking: controller.isTracking.value,
                      showLocami: controller.showLocami.value,
                      accentColor: accentColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Obx(
                    () => HomeInputCard(
                      controller: controller.fromController,
                      label: "From",
                      hint: "Select starting point",
                      icon: SolarIconsBold.home,
                      onTap:
                          controller.isTracking.value
                              ? null
                              : () => _showLocationSearch(true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => HomeInputCard(
                      controller: controller.toController,
                      label: "To",
                      hint: "Select destination",
                      icon: SolarIconsBold.flag,
                      iconColor: accentColor,
                      onTap:
                          controller.isTracking.value
                              ? null
                              : () => _showLocationSearch(false),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        "Alert Me",
                        style: TextStyle(
                          color: customColors().textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Obx(
                        () => HomeDistanceOption(
                          distance: "500m",
                          isSelected: controller.alertDistance.value == 500,
                          onTap:
                              controller.isTracking.value
                                  ? null
                                  : () => controller.setAlertDistance(500),
                        ),
                      ),
                      Obx(
                        () => HomeDistanceOption(
                          distance: "1km",
                          isSelected: controller.alertDistance.value == 1000,
                          onTap:
                              controller.isTracking.value
                                  ? null
                                  : () => controller.setAlertDistance(1000),
                        ),
                      ),
                      Obx(
                        () => HomeDistanceOption(
                          distance: "2km",
                          isSelected: controller.alertDistance.value == 2000,
                          onTap:
                              controller.isTracking.value
                                  ? null
                                  : () => controller.setAlertDistance(2000),
                        ),
                      ),
                      const Spacer(),
                      Obx(
                        () => TrackingButton(
                          isTracking: controller.isTracking.value,
                          isLoading: controller.isTrackingLoading.value,
                          canStart: controller.validateIsTracking(),
                          accentColor: accentColor,
                          onPressed: controller.toggleTracking,
                        ),
                      ),
                    ],
                  ),
                  Obx(() {
                    if (controller.isTracking.value ||
                        TripDetailsManager.instance.isTracking) {
                      return Column(
                        children: [
                          const SizedBox(height: 32),
                          const TripInfoDisplay(),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          const SizedBox(height: 32),
                          if (controller.isLoadingHistory.value)
                            const Center(child: CircularProgressIndicator())
                          else if (controller.tripHistory.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Recent Trips",
                                  style: TextStyle(
                                    color: customColors().textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (controller.tripHistory.length > 3)
                                  TextButton(
                                    onPressed: _showAllHistory,
                                    child: const Text("Show More"),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Stack(
                              children: [
                                Column(
                                  children:
                                      controller.tripHistory
                                          .take(3)
                                          .map(
                                            (
                                              TripDetailsModel trip,
                                            ) => TripHistoryCard(
                                              trip: trip,
                                              onRestart: () {
                                                controller.fromController.text =
                                                    trip.street ?? "";
                                                controller.toController.text =
                                                    trip.destination ?? "";
                                                controller.toggleTracking();
                                              },
                                            ),
                                          )
                                          .toList(),
                                ),
                                if (controller.tripHistory.length > 3)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: 60,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            customColors().background
                                                .withValues(alpha: 0),
                                            customColors().background,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 40),
                            Center(
                              child: Column(
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/busTerminal.svg',
                                    height: 240,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    "No track history yet",
                                    style: TextStyle(
                                      color: customColors().textPrimary
                                          .withValues(alpha: 0.5),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBottomSheet extends StatelessWidget {
  final List<TripDetailsModel> history;
  final VoidCallback onClear;
  final Function(TripDetailsModel) onRestart;

  const _HistoryBottomSheet({
    required this.history,
    required this.onClear,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.theme == AppThemeMode.dark;

    return GlassContainer(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      opacity: isDark ? 0.15 : 0.7,
      blur: 25,
      color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.9),
      borderRadius: 24,
      border: Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1) 
            : Colors.white.withValues(alpha: 0.5),
        width: 1.5,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: customColors().textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "All Recent Trips",
                style: TextStyle(
                  color: customColors().textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text(
                  "Clear All",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                return TripHistoryCard(
                  trip: history[index],
                  onRestart: () => onRestart(history[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
