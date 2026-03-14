import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const int notificationId = 888;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'locami_tracking_channel',
    'Locami Tracking',
    description: 'Navigation tracking notification',
    importance: Importance.low,
  );

  const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
    'locami_alarm_channel_v2',
    'Locami Alarm',
    description: 'Alarm notification when destination is reached',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(alarmChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'locami_tracking_channel',
      initialNotificationTitle: 'Locami',
      initialNotificationContent: 'Preparing tracking...',
      foregroundServiceNotificationId: notificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  double totalDistance = 150.0;
  double remainingDistance = 150.0;
  int elapsedMinutes = 0;

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    remainingDistance -= 150;
    elapsedMinutes += 1;

    if (remainingDistance < 0) remainingDistance = 0;

    int progress =
        (((totalDistance - remainingDistance) / totalDistance) * 100).toInt();

    final androidDetails = AndroidNotificationDetails(
      'locami_tracking_channel',
      'Locami Tracking',
      channelDescription: 'Navigation tracking notification',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      silent: true,
      icon: '@mipmap/ic_launcher',
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      category: AndroidNotificationCategory.navigation,
      actions: [const AndroidNotificationAction('view_trip', 'View Trip')],
    );

    await notifications.show(
      notificationId,
      'Chembumukku → Kozhikode',
      '${remainingDistance.toStringAsFixed(1)} km remaining • ${elapsedMinutes} min elapsed',
      NotificationDetails(android: androidDetails),
    );

    if (remainingDistance == 0) {
      service.invoke('locationReached');

      final alarmAndroidDetails = AndroidNotificationDetails(
        'locami_alarm_channel_v2',
        'Locami Alarm',
        channelDescription: 'Alarm notification when destination is reached',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );

      await notifications.show(
        notificationId + 1,
        'Destination Reached!',
        'You have arrived at your destination.',
        NotificationDetails(android: alarmAndroidDetails),
      );

      timer.cancel();
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}
