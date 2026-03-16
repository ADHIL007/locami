import 'package:get/get.dart';
import 'package:locami/modules/initial/controllers/initial_home_controller.dart';

class InitialHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InitialHomeController>(() => InitialHomeController());
  }
}
