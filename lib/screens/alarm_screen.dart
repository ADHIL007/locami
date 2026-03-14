import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _startAlarm();
  }

  void _startAlarm() {
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

  void _stopAlarm() {
    FlutterRingtonePlayer().stop();
    _audioPlayer.stop();
  }

  @override
  void dispose() {
    _stopAlarm();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = customColors();
    final accentColor = ThemeProvider.instance.accentColor;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(
                              0.5 * _animationController.value),
                          blurRadius: 50 * _animationController.value,
                          spreadRadius: 20 * _animationController.value,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_on,
                      size: 100,
                      color: accentColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              Text(
                'Destination Reached!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You have successfully arrived.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 64),
              GestureDetector(
                onTap: () {
                  _stopAlarm();
                  Get.back();
                },
                child: Container(
                  height: 60,
                  width: 200,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
