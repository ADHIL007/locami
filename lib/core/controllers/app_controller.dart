import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:locami/modules/home/views/home_view.dart';
import 'package:locami/db_manager/trip_details_manager.dart';
import 'package:locami/db_manager/user_model_manager.dart';

class AppController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    TripDetailsManager.instance.init();
    _initBackgroundListener();
    _checkAlarmStatus();
  }

  Future<void> _checkAlarmStatus() async {
    final user = await UserModelManager.instance.user;
    if (user.isAlarmActive) {
      const channel = MethodChannel('com.example.locami/alarm');
      channel.invokeMethod('toggleLockScreenFlags', {'show': true});
      Get.offAll(() => const HomeView());
    }
  }

  void _initBackgroundListener() {
    FlutterBackgroundService().on('on_alert_triggered').listen((event) {
      const channel = MethodChannel('com.example.locami/alarm');
      channel.invokeMethod('toggleLockScreenFlags', {'show': true});
      
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        Get.offAll(() => const HomeView());
      }
    });

    FlutterBackgroundService().on('stop_alarm').listen((event) {
      const channel = MethodChannel('com.example.locami/alarm');
      channel.invokeMethod('toggleLockScreenFlags', {'show': false});
    });
  }
}
