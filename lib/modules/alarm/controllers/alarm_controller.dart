import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:locami/navigation/main_nav.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:locami/db_manager/trip_details_manager.dart';

class AlarmController extends GetxController with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    startAlarm();
  }

  void startAlarm() {
    final themeProvider = ThemeProvider.instance;
    final soundKey = themeProvider.alertSound;
    final isCustom = themeProvider.isCustomSound;
    final customPath = themeProvider.customSoundPath;
    final loop = themeProvider.loopAlarm;

    if (isCustom && customPath != null) {
      _audioPlayer.play(DeviceFileSource(customPath));
      if (loop) _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } else {
      if (soundKey == 'alarm') {
        FlutterRingtonePlayer().playAlarm(looping: loop);
      } else if (soundKey == 'ringtone') {
        FlutterRingtonePlayer().playRingtone(looping: loop);
      } else {
        FlutterRingtonePlayer().playNotification(looping: loop);
      }
    }
  }

  void stopAlarm() {
    FlutterRingtonePlayer().stop();
    _audioPlayer.stop();
    TripDetailsManager.instance.stopAlertSound();
    FlutterBackgroundService().invoke('stop_alarm');
  }

  @override
  void onClose() {
    stopAlarm();
    animationController.dispose();
    _audioPlayer.dispose();
    super.onClose();
  }

  void dismiss() {
    stopAlarm();
    Get.back();
  }

  void dismissAndGoHome() {
    stopAlarm();
    // Navigate back to the main navigation entry point
    Get.offAll(() => const MainNav());
  }
}
