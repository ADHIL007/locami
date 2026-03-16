import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:locami/db_manager/trip_details_manager.dart';

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
  if (service is AndroidServiceInstance) {
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

  service.on('simulate_location').listen((event) {
    if (event != null) {
      TripDetailsManager.instance.handleSimulatedPosition(event);
    }
  });

  service.on('set_simulation_mode').listen((event) {
    if (event != null) {
      final enabled = event['enabled'] == true;
      TripDetailsManager.instance.setSimulationMode(enabled);
    }
  });

  service.on('stop_alarm').listen((event) {
    TripDetailsManager.instance.stopAlertSound();
  });

  service.on('start_tracking').listen((event) {
    _startTracking(service);
  });

  _startTracking(service);
}

void _startTracking(ServiceInstance service) async {
  try {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (!(await service.isForegroundService())) {
          return;
        }
      }
    });

    await TripDetailsManager.instance.startBackgroundTracking(service);
  } catch (e) {
    if (kDebugMode) {
      print("Background tracking error: $e");
    }
  }
}
