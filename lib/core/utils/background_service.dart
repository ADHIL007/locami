import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:locami/dbManager/trip_details_manager.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'locami_tracking_channel', // id
    'Locami Tracking Service', // title
    description: 'Ongoing notification for location tracking', // description
    importance: Importance.high, // Use high importance for Android 14
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'locami_tracking_channel',
      initialNotificationTitle: 'Locami Tracking Active',
      initialNotificationContent: 'Monitoring your location...',
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

  if (service is AndroidServiceInstance) {
    // Re-create the notification channel in this isolate.
    // The background service runs in a separate isolate, so the channel
    // created in initializeService() (main isolate) may not be available here.
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'locami_tracking_channel',
      'Locami Tracking Service',
      description: 'Ongoing notification for location tracking',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // CRITICAL FIX for Android 14+:
    // Pre-show the notification with the SAME ID that flutter_background_service
    // uses internally (888) BEFORE calling setAsForegroundService().
    // This ensures the notification already exists when startForeground() is called.
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'locami_tracking_channel', // Must match the channel ID
      'Locami Tracking Service',
      channelDescription: 'Ongoing notification for location tracking',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.service,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // Show notification with ID 888 (the ID used by flutter_background_service)
    await flutterLocalNotificationsPlugin.show(
      888,
      'Locami Tracking Active',
      'Initializing location monitoring...',
      notificationDetails,
    );

    // Now it's safe to set as foreground — notification 888 already exists
    service.setAsForegroundService();

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Basic logic to keep service alive
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Locami Tracking",
          content: "Destination: ${TripDetailsManager.instance.currentTripDetail.value?.destination ?? 'Monitoring...'}",
        );
      }
    }
    
    // The TripDetailsManager logic will still run because the process is kept alive.
    debugPrint('FLUTTER BACKGROUND SERVICE: Heartbeat');
  });
}
