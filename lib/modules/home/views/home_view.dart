import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:locami/modules/home/controllers/home_controller.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:locami/core/db_helper/saved_location_db.dart';
import 'package:locami/screens/widgets/location_search_sheet.dart';
import 'package:locami/screens/widgets/trip_info_display.dart';

import 'package:locami/modules/home/views/widgets/loading_screen.dart';
import 'package:locami/modules/home/views/widgets/setup_panel.dart';
import 'package:locami/modules/home/views/widgets/top_header.dart';
import 'package:locami/modules/home/views/widgets/map_center_confirm_panel.dart';
import 'package:locami/modules/home/views/widgets/ghost_fab_group.dart';
import 'package:locami/modules/home/views/widgets/navigation_arrow_painter.dart';
import 'package:locami/core/constants/api_constants.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  Color _getColorForSeed(String seed) {
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.indigoAccent,
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }

  void _showLocationSearch() {
    Get.bottomSheet(
      LocationSearchSheet(
        isFrom: false,
        initialValue: controller.toController.text,
        userCountry: controller.userCountry.value,
        currentPosition: controller.currentPosition.value,
        onSelected: (address) {
          controller.selectDestination(address);
        },
        onTestNearby: controller.setNearbyTestLocation,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showSavedLocationOptions(SavedLocation loc, bool isDark, Color accentColor) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(loc.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.label,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        loc.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.navigation_rounded, color: accentColor),
              title: const Text('Start Tracking Here'),
              onTap: () {
                Get.back();
                controller.startTrackingToSaved(loc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Location'),
              onTap: () {
                Get.back();
                controller.deleteSavedLocation(loc.id);
                Get.snackbar(
                  'Deleted',
                  '${loc.label} removed from saved locations.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  colorText: isDark ? Colors.white : Colors.black87,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.theme == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return LoadingScreen(isDark: isDark, accentColor: accentColor);
        }

        final isTracking = controller.isTracking.value;

        return SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: fm.FlutterMap(
                  mapController: controller.mapController,
                  options: fm.MapOptions(
                    initialCenter: const LatLng(20.5937, 78.9629),
                    initialZoom: 5.0,
                    interactionOptions: const fm.InteractionOptions(
                      flags: fm.InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    Obx(() {
                      final mapDark = controller.isMapDark.value;
                      final sat = controller.useSatelliteMap.value;
                      return fm.TileLayer(
                        key: ValueKey('tiles_${sat}_$mapDark'),
                        urlTemplate: sat
                            ? ApiConstants.arcGisSatelliteUrl
                            : (mapDark
                                ? ApiConstants.cartoDbDarkUrl
                                : ApiConstants.cartoDbLightUrl),
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.example.locami',
                      );
                    }),
                    Obx(() {
                      if (!controller.useSatelliteMap.value) return const SizedBox.shrink();
                      return fm.TileLayer(
                        urlTemplate: ApiConstants.cartoDbLabelsUrl,
                        subdomains: const ['a', 'b', 'c', 'd'],
                      );
                    }),
                    Obx(() {
                      if (controller.currentRoute.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return fm.PolylineLayer(
                        polylines: [
                          fm.Polyline(
                            points: controller.currentRoute.toList(),
                            color: accentColor,
                            strokeWidth: 5,
                          ),
                        ],
                      );
                    }),
                    Obx(() {
                      if (controller.destinationLatitude.value == null) {
                        return const SizedBox.shrink();
                      }
                      return fm.CircleLayer(
                        circles: [
                          fm.CircleMarker(
                            point: LatLng(
                              controller.destinationLatitude.value!,
                              controller.destinationLongitude.value!,
                            ),
                            color: accentColor.withValues(alpha: 0.12),
                            borderColor: accentColor.withValues(alpha: 0.4),
                            borderStrokeWidth: 2,
                            useRadiusInMeter: true,
                            radius: controller.alertDistance.value.toDouble(),
                          ),
                        ],
                      );
                    }),
                    Obx(() {
                      if (controller.destinationLatitude.value == null) {
                        return const SizedBox.shrink();
                      }
                      return fm.MarkerLayer(
                        markers: [
                          fm.Marker(
                            point: LatLng(
                              controller.destinationLatitude.value!,
                              controller.destinationLongitude.value!,
                            ),
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    Obx(() {
                      final locs = controller.savedLocations;
                      if (locs.isEmpty) return const SizedBox.shrink();
                      return fm.MarkerLayer(
                        markers: locs.map((loc) {
                          final pinColor = _getColorForSeed(loc.label);
                          return fm.Marker(
                            point: LatLng(loc.latitude, loc.longitude),
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () {
                                _showSavedLocationOptions(loc, isDark, accentColor);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: pinColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(loc.emoji, style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                    Obx(() {
                      final pos = controller.currentPosition.value;
                      if (pos == null) return const SizedBox.shrink();
                      return fm.MarkerLayer(
                        markers: [
                          fm.Marker(
                            point: LatLng(pos.latitude, pos.longitude),
                            width: 80,
                            height: 80,
                            child: Obx(() => CustomPaint(
                                  size: const Size(80, 80),
                                  painter: NavigationArrowPainter(heading: controller.currentHeading.value),
                                )),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 400,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black,
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopHeader(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: controller.isPinSelectionMode.value
                    ? MapCenterConfirmPanel(accentColor: accentColor, isDark: isDark)
                    : (isTracking
                        ? const TripInfoDisplay()
                        : SetupPanel(
                            isDark: isDark,
                            accentColor: accentColor,
                            onSearchTap: _showLocationSearch,
                          )),
              ),
              Positioned(
                right: 20,
                bottom: isTracking ? 500 : 360,
                child: GhostFABGroup(accentColor: accentColor),
              ),
              if (!isTracking && controller.isPinSelectionMode.value)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 3,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(2),
                                ),
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.white,
                                    width: 0.5,
                                  ),
                                  right: BorderSide(
                                    color: Colors.white,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
