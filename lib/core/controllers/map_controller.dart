import 'package:get/get.dart';
import 'package:locami/core/services/i_map_service.dart';
import 'package:locami/core/model/trip_details_model.dart';

class MapController extends GetxController {
  // We depend on the interface, not the concrete implementation!
  final IMapService _mapService = Get.find<IMapService>();

  /// Helper to get URL directly from a Trip model, centralizing logic
  String getUrlForTrip(TripDetailsModel trip, {
    int width = 600,
    int height = 450,
    String mapLayer = 'map',
    int pathWidth = 5,
  }) {
    if (trip.destinationLatitude == null || trip.destinationLongitude == null) {
      return "";
    }

    return _mapService.getStaticMapUrl(
      startLat: trip.latitude,
      startLon: trip.longitude,
      endLat: trip.destinationLatitude!,
      endLon: trip.destinationLongitude!,
      width: width,
      height: height,
      mapLayer: mapLayer,
      pathWidth: pathWidth,
    );
  }

  /// General purpose method for custom coordinates
  String getCustomMapUrl({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    int width = 600,
    int height = 450,
    String mapLayer = 'map',
    int pathWidth = 5,
  }) {
    return _mapService.getStaticMapUrl(
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      width: width,
      height: height,
      mapLayer: mapLayer,
      pathWidth: pathWidth,
    );
  }
}
