import 'package:home_widget/home_widget.dart';

class WidgetHelper {
  static const String androidWidgetName = "LocamiWidget";

  static Future<void> updateWidget({
    required double? remainingDistance,
    required bool isTracking,
    required String currentLoc,
    required String destName,
    required int progress,
    required String statusInfo,
    required String alertDist,
    required int speed,
  }) async {
    final String distanceStr = remainingDistance != null 
        ? "${remainingDistance.toStringAsFixed(1)} km" 
        : "-- km";

    await HomeWidget.saveWidgetData("distance", distanceStr);
    await HomeWidget.saveWidgetData("is_tracking", isTracking);
    await HomeWidget.saveWidgetData("current_loc", currentLoc);
    await HomeWidget.saveWidgetData("dest_name", destName);
    await HomeWidget.saveWidgetData("progress", progress);
    await HomeWidget.saveWidgetData("status_info", statusInfo);
    await HomeWidget.saveWidgetData("alert_dist", alertDist);
    await HomeWidget.saveWidgetData("speed", speed.toString());

    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      qualifiedAndroidName: "com.example.locami.LocamiWidget",
    );
  }
  static Future<void> resetWidget() async {
    await HomeWidget.saveWidgetData("is_tracking", false);
    await HomeWidget.saveWidgetData("distance", "-- km");
    await HomeWidget.saveWidgetData("speed", "0");
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      qualifiedAndroidName: "com.example.locami.LocamiWidget",
    );
  }
}
