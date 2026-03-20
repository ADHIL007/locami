import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:get/get.dart';
import 'package:locami/modules/home/controllers/home_controller.dart';
import 'package:locami/screens/widgets/trip_info_display.dart';
import 'package:locami/screens/widgets/location_search_sheet.dart';
import 'package:locami/screens/widgets/tracking_button.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:locami/screens/widgets/settings_bottom_sheet.dart';

import 'package:locami/core/widgets/glass_container.dart';
import 'dart:ui';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.theme == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: Obx(() {
        final isTracking = controller.isTracking.value;

        final pos = controller.currentPosition.value;
        final isSatellite = controller.useSatelliteMap.value;


        return SizedBox.expand(
          child: Stack(
            children: [
              // ── 1. MAP LAYER ──
              Positioned.fill(
                child: fm.FlutterMap(
                  mapController: controller.mapController,
                  options: fm.MapOptions(
                    initialCenter: LatLng(
                      pos?.latitude ?? 20.5937,
                      pos?.longitude ?? 78.9629,
                    ),
                    initialZoom: pos != null ? 15.0 : 5.0,
                    interactionOptions: const fm.InteractionOptions(
                      flags: fm.InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // Map Tiles
                    Obx(() {
                      final mapDark = controller.isMapDark.value;
                      return fm.TileLayer(
                        urlTemplate: isSatellite
                            ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                            : (mapDark
                                ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png'),
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.example.locami',
                      );
                    }),
                    // Labels Overlay for Satellite
                    if (isSatellite)
                      fm.TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),

                    // Route Polyline
                    if (controller.currentRoute.isNotEmpty)
                      fm.PolylineLayer(
                        polylines: [
                          fm.Polyline(
                            points: controller.currentRoute.toList(),
                            color: accentColor,
                            strokeWidth: 5,
                          ),
                        ],
                      ),

                    // Destination Marker & Circle
                    if (controller.destinationLatitude.value != null) ...[
                      fm.CircleLayer(
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
                      ),
                      fm.MarkerLayer(
                        markers: [
                          fm.Marker(
                            point: LatLng(
                              controller.destinationLatitude.value!,
                              controller.destinationLongitude.value!,
                            ),
                            width: 44,
                            height: 44,
                            child: Icon(
                              SolarIconsBold.mapPoint,
                              color: accentColor,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Current User Location
                    if (pos != null)
                      fm.MarkerLayer(
                        markers: [
                          fm.Marker(
                            point: LatLng(pos.latitude, pos.longitude),
                            width: 32,
                            height: 32,
                            child: _buildUserLocationIndicator(accentColor),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ── 2. MAP SPOTLIGHT & VIGNETTE ──
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

              // ── 3. TOP LOCATION HEADER ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                SolarIconsBold.mapPoint,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  controller.currentLocationName.value
                                      .toLowerCase(),
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 4. BOTTOM PANELS ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: isTracking
                    ? const TripInfoDisplay()
                    : _buildSetupPanelGlass(isDark, accentColor),
              ),

              // ── 5. ALL CTA BUTTONS ──
              if (!(themeProvider.uiMode == 'low' && isTracking))
                Positioned(
                  right: 20,
                  bottom: isTracking ? 500 : 360,
                  child: _buildGhostFABGroup(accentColor),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildUserLocationIndicator(Color accentColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.2),
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
        ),
      ],
    );
  }

  Widget _buildSetupPanelGlass(bool isDark, Color accentColor) {
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
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              GestureDetector(
                onTap: _showLocationSearch,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Icon(SolarIconsBold.mapPoint, color: accentColor, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Obx(() => Text(
                          controller.toAddress.value.isEmpty
                              ? "Where are you going?"
                              : controller.toAddress.value,
                          style: TextStyle(
                            color: controller.toAddress.value.isEmpty
                                ? (isDark ? Colors.white38 : Colors.black38)
                                : (isDark ? Colors.white : Colors.black),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                      ),
                      Icon(
                        SolarIconsOutline.altArrowRight,
                        color: isDark ? Colors.white24 : Colors.black12,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── DISTANCE SELECTION CHIPS ──
              Obx(() => Row(
                children: [500, 1000, 2000].map((dist) {
                  final isSelected = controller.alertDistance.value == dist;
                  final label = dist == 500 ? "500m" : "${dist ~/ 1000}km";
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.setAlertDistance(dist),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                          left: dist == 500 ? 0 : 6,
                          right: dist == 2000 ? 0 : 6,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.15)
                              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.4)
                                : Colors.transparent,
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
              )),
              const SizedBox(height: 20),
              Obx(() => TrackingButton(
                onPressed: controller.toggleTracking,
                isTracking: false,
                isLoading: controller.isTrackingLoading.value,
                canStart: controller.toAddress.value.isNotEmpty,
                accentColor: accentColor,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGhostFABGroup(Color accentColor) {
    return Column(
      children: [
        _buildGhostBtn(
          icon: controller.useSatelliteMap.value ? SolarIconsBold.map : SolarIconsOutline.map,
          onTap: controller.toggleMapStyle,
        ),
        const SizedBox(height: 16),
        _buildGhostBtn(
          icon: controller.isMapDark.value ? SolarIconsBold.moon : SolarIconsOutline.sun,
          onTap: controller.toggleMapTheme,
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
    );
  }

  Widget _buildGhostBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
