import 'package:get/get.dart';

abstract class IMapService extends GetxService {
  String getStaticMapUrl({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    int width,
    int height,
    String mapLayer,
    int pathWidth,
  });
}
