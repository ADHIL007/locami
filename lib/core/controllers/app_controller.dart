import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:locami/modules/alarm/views/alarm_view.dart';

class AppController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _initBackgroundListener();
  }

  void _initBackgroundListener() {
    FlutterBackgroundService().on('locationReached').listen((event) {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        Get.to(() => const AlarmView());
      }
    });
  }
}
