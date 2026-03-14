import 'package:get/get.dart';
import 'package:flutter/material.dart';

class TripDetailsController extends GetxController {
  final isStarting = false.obs;

  Future<void> startTripAgain(VoidCallback onStartAgain) async {
    isStarting.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    Get.back();
    onStartAgain();
  }
}
