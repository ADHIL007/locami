import 'package:locami/core/services/i_map_service.dart';
import 'package:locami/core/constants/app_constants.dart';

class YandexMapService extends IMapService {
  @override
  String getStaticMapUrl({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    int width = 600,
    int height = 450,
    String mapLayer = 'map',
    int pathWidth = 5,
  }) {
    return "${AppConstants.yandexMapsBaseUrl}"
        "?l=$mapLayer"
        "&lang=${AppConstants.defaultMapLang}"
        "&size=$width,$height"
        "&scale=${AppConstants.defaultMapScale}"
        "&pt=$startLon,$startLat,pm2blm~$endLon,$endLat,pm2rdm"
        "&pl=c:${AppConstants.polylineColor},w:$pathWidth,$startLon,$startLat,$endLon,$endLat";
  }
}
