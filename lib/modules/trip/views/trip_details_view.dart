import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:get/get.dart';
import 'package:locami/core/model/trip_details_model.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:locami/core/widgets/glass_container.dart';
import 'package:locami/modules/trip/controllers/trip_details_controller.dart';
import 'package:locami/core/controllers/map_controller.dart';

class TripDetailsView extends GetView<TripDetailsController> {
  final TripDetailsModel trip;
  final VoidCallback onStartAgain;

  const TripDetailsView({
    super.key,
    required this.trip,
    required this.onStartAgain,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TripDetailsController());
    final themeProvider = ThemeProvider.instance;
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(trip.timestamp);
    final distance = (((trip.totalDistance ?? trip.distanceTraveled) ?? 0) /
            1000)
        .toStringAsFixed(1);
    final speed = ((trip.speed < 0 ? 0.0 : trip.speed) * 3.6).toStringAsFixed(
      0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Map
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: _buildMapBanner(trip),
          ),
          // Gradient Overlay to blend map into background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                    Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.1),
                    Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.3, 0.8, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: customColors().background.withValues(
                              alpha: 0.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            SolarIconsOutline.altArrowLeft,
                            color: customColors().textPrimary,
                            size: 20,
                          ),
                        ),
                        onPressed: () => Get.back(),
                      ),
                      Expanded(
                        child: Text(
                          'Trip Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: customColors().textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.12,
                      bottom: 40,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          GlassContainer(
                            padding: const EdgeInsets.all(28),
                            borderRadius: 36,
                            opacity: 0.08,
                            blur: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: themeProvider.accentColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        SolarIconsOutline.calendar,
                                        color: themeProvider.accentColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        color: customColors().textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 36),
                                _buildLocationTimeline(),
                                const SizedBox(height: 36),
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        customColors().textPrimary.withValues(
                                          alpha: 0.1,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatBox(
                                      SolarIconsOutline.routing3,
                                      "Distance",
                                      "$distance km",
                                    ),
                                    Container(
                                      width: 1,
                                      height: 60,
                                      color: customColors().textPrimary
                                          .withValues(alpha: 0.1),
                                    ),
                                    _buildStatBox(
                                      SolarIconsOutline.speedometerMiddle,
                                      "Avg Speed",
                                      "$speed km/h",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          _buildStartButton(controller, themeProvider),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTimeline() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                SolarIconsBold.mapPoint,
                color: Colors.green,
                size: 20,
              ),
            ),
            Container(
              width: 3,
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green.withValues(alpha: 0.5),
                    Colors.red.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                SolarIconsBold.mapPoint,
                color: Colors.red,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "STARTING POINT",
                    style: TextStyle(
                      color: customColors().textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.street ?? "Unknown Location",
                    style: TextStyle(
                      color: customColors().textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 46),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DESTINATION",
                    style: TextStyle(
                      color: customColors().textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.destination ?? "Unknown Destination",
                    style: TextStyle(
                      color: customColors().textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(IconData icon, String title, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeProvider.instance.accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: ThemeProvider.instance.accentColor,
            size: 26,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: TextStyle(
            color: customColors().textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: customColors().textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(
    TripDetailsController controller,
    ThemeProvider themeProvider,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: Obx(
        () => ElevatedButton(
          onPressed:
              controller.isStarting.value
                  ? null
                  : () => controller.startTripAgain(onStartAgain),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: themeProvider.accentColor.withValues(alpha: 0.6),
          ),
          child:
              controller.isStarting.value
                  ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(SolarIconsBold.play, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "Start Trip Again",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildMapBanner(TripDetailsModel trip) {
    if (trip.destinationLatitude == null || trip.destinationLongitude == null) {
      return Container(
        color: customColors().background.withValues(alpha: 0.3),
        child: Center(
          child: Icon(
            SolarIconsOutline.map,
            color: customColors().textSecondary.withValues(alpha: 0.5),
            size: 48,
          ),
        ),
      );
    }

    final mapController = Get.find<MapController>();
    final String url = mapController.getUrlForTrip(
      trip,
      width: 600,
      height: 450,
    );

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => Container(
            color: customColors().background.withValues(alpha: 0.1),
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: customColors().background.withValues(alpha: 0.3),
            child: Center(
              child: Icon(
                SolarIconsOutline.map,
                color: customColors().textSecondary.withValues(alpha: 0.5),
                size: 48,
              ),
            ),
          ),
    );
  }
}
