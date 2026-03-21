import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:locami/modules/home/controllers/home_controller.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:locami/core/db_helper/saved_location_db.dart';
import 'package:locami/screens/widgets/location_search_sheet.dart';
import 'package:locami/screens/widgets/trip_info_display.dart';
import 'package:locami/core/widgets/glass_container.dart';

import 'package:locami/modules/home/views/widgets/loading_screen.dart';
import 'package:locami/modules/home/views/widgets/setup_panel.dart';
import 'package:locami/modules/home/views/widgets/top_header.dart';
import 'package:locami/modules/home/views/widgets/map_center_confirm_panel.dart';
import 'package:locami/modules/home/views/widgets/ghost_fab_group.dart';
import 'package:locami/modules/home/views/widgets/navigation_arrow_painter.dart';
import 'package:locami/core/constants/api_constants.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:locami/core/utils/map_cache_manager.dart';

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
        onSelected: (address, {lat, lon}) {
          controller.selectDestination(address, lat: lat, lon: lon);
        },
        onTestNearby: controller.setNearbyTestLocation,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showSavedLocationOptions(
    SavedLocation loc,
    bool isDark,
    Color accentColor,
  ) {
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
                Icon(loc.iconData, size: 24, color: accentColor),
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
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.5),
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
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text('Delete Location'),
              onTap: () {
                Get.back();
                controller.deleteSavedLocation(loc.id);
                Get.snackbar(
                  'Deleted',
                  '${loc.label} removed from saved locations.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
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
                    backgroundColor: isDark ? const Color(0xFF1A1B1E) : const Color(0xFFF2EFE9),
                    initialCenter: const LatLng(20.5937, 78.9629),
                    initialZoom: 5.0,
                    interactionOptions: const fm.InteractionOptions(
                      flags: fm.InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // ── BASE PERSISTENT LAYER (Zoom 0-6) ──
                    // Always available in the background to prevent grey holes.
                    // Zoom 0-6 tiles are very few and almost certainly cached.
                    fm.TileLayer(
                      key: const ValueKey('base_overview_layer'),
                      urlTemplate: ApiConstants.cartoDbLightUrl,
                      subdomains: const ['a', 'b', 'c', 'd'],
                      maxNativeZoom: 6, // STRETCHES from zoom 6 even if zoomed in
                      tileProvider: CachedTileProvider(
                        store: MapCacheManager.instance.cacheStore,
                      ),
                    ),
                    Obx(() {
                      final isOnline = controller.isOnline.value;
                      final mapDark = controller.isMapDark.value;
                      final sat = controller.useSatelliteMap.value;
                      final cacheStore = MapCacheManager.instance.cacheStore;

                      if (isOnline) {
                        // ── Online Mode: Show SELECTED style ──
                        return fm.TileLayer(
                          key: ValueKey('online_${sat}_$mapDark'),
                          urlTemplate: sat
                              ? ApiConstants.arcGisSatelliteUrl
                              : (mapDark
                                  ? ApiConstants.cartoDbDarkUrl
                                  : ApiConstants.cartoDbLightUrl),
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.example.locami',
                          tileProvider: CachedTileProvider(store: cacheStore),
                        );
                      } else {
                        // ── Offline Mode: Force Standard Light Map ──
                        // This prevents flickering between different cached styles
                        return fm.TileLayer(
                          key: const ValueKey('offline_standard_light'),
                          urlTemplate: ApiConstants.cartoDbLightUrl,
                          subdomains: const ['a', 'b', 'c', 'd'],
                          tileDisplay: const fm.TileDisplay.fadeIn(),
                          tileProvider: CachedTileProvider(store: cacheStore),
                        );
                      }
                    }),
                    Obx(() {
                      final isOnline = controller.isOnline.value;
                      final sat = controller.useSatelliteMap.value;
                      if (!sat && isOnline) return const SizedBox.shrink();
                      
                      return fm.TileLayer(
                        urlTemplate: ApiConstants.cartoDbLabelsUrl,
                        subdomains: const ['a', 'b', 'c', 'd'],
                        tileDisplay: const fm.TileDisplay.fadeIn(),
                        tileProvider: CachedTileProvider(
                          store: MapCacheManager.instance.cacheStore,
                        ),
                      );
                    }),
                    Obx(() {
                      if (controller.currentRoute.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      final traveledIndex = controller.traveledRouteIndex.value;
                      final route = controller.currentRoute.toList();
                      
                      final safeIndex = (traveledIndex >= 0 && traveledIndex < route.length) 
                          ? traveledIndex 
                          : 0;
                          
                      final traversed = route.sublist(0, safeIndex + 1);
                      final remaining = route.sublist(safeIndex);
                      
                      // Optimized polyline rendering with reduced point count
                      // The route is already simplified by OptimizedRouteRenderer
                      return fm.PolylineLayer(
                        polylines: [
                          if (traversed.length > 1) 
                            fm.Polyline(
                              points: traversed,
                              color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.25),
                              strokeWidth: 5,
                              // Use optimized stroke cap/join for better performance
                              strokeCap: fm.StrokeCap.round,
                              strokeJoin: fm.StrokeJoin.round,
                            ),
                          if (remaining.length > 1)
                            fm.Polyline(
                              points: remaining,
                              color: accentColor,
                              strokeWidth: 5,
                              strokeCap: fm.StrokeCap.round,
                              strokeJoin: fm.StrokeJoin.round,
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
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
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
                        markers:
                            locs.map((loc) {
                              final pinColor = _getColorForSeed(loc.label);
                              return fm.Marker(
                                point: LatLng(loc.latitude, loc.longitude),
                                width: 36,
                                height: 36,
                                child: GestureDetector(
                                  onTap: () {
                                    _showSavedLocationOptions(
                                      loc,
                                      isDark,
                                      accentColor,
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: pinColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        loc.iconData,
                                        size: 18,
                                        color: Colors.white,
                                      ),
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
                            child: Obx(
                              () => CustomPaint(
                                size: const Size(80, 80),
                                painter: NavigationArrowPainter(
                                  heading: controller.currentHeading.value,
                                ),
                              ),
                            ),
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
              const Positioned(top: 0, left: 0, right: 0, child: TopHeader()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child:
                    controller.isPinSelectionMode.value
                        ? MapCenterConfirmPanel(
                          accentColor: accentColor,
                          isDark: isDark,
                        )
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
              Obx(() {
                if (!controller.isTracking.value ||
                    controller.isDestinationInView.value) {
                  return const SizedBox.shrink();
                }
                final isTracking = controller.isTracking.value;
                return Positioned(
                  left: 20,
                  bottom: isTracking ? 500 : 360,
                  child: GestureDetector(
                    onTap: controller.animateToDestination,
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle),
                      child: GlassContainer(
                        width: 56,
                        height: 56,
                        blur: 20,
                        opacity: 0.15,
                        borderRadius: 28,
                        color: Colors.black,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        child: Center(
                          child: Obx(() {
                            // Bearing is geographical, subtract map rotation to get screen-relative angle
                            final rotation = controller.mapRotation.value;
                            final bearing = controller.bearingToDestination.value;
                            final angle = (bearing - rotation) * (math.pi / 180);
                            
                            return Transform.rotate(
                              angle: angle,
                              child: Icon(
                                SolarIconsBold.mapArrowUp,
                                color: accentColor,
                                size: 30,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                );
              }),
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
