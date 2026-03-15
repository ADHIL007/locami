import 'package:get/get.dart';
import 'package:locami/core/services/i_map_service.dart';
import 'package:locami/core/services/yandex_map_service.dart';
import 'package:locami/core/controllers/map_controller.dart';
import 'package:locami/core/controllers/app_controller.dart';

class MainBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<IMapService>(YandexMapService(), permanent: true);
    Get.put(MapController(), permanent: true);
    Get.put(AppController(), permanent: true);
  }
}
