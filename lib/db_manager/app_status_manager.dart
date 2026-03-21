import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:locami/core/db_helper/app_status.dart';
import 'package:locami/core/model/appstatus_model.dart';

class AppStatusManager {
  AppStatusManager._internal() {
    _initConnectivityListener();
  }
  static final AppStatusManager instance = AppStatusManager._internal();

  AppStatus? _currentStatus;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier(true);

  Future<AppStatus> get status async {
    if (_currentStatus != null) return _currentStatus!;
    _currentStatus = await AppStatusDbHelper.instance.getStatus();
    return _currentStatus!;
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final bool hasInternet = results.any((result) => result != ConnectivityResult.none);
      isOnlineNotifier.value = hasInternet;
      patchStatus(isInternetOn: hasInternet);
    });
    
    // Initial check
    _connectivity.checkConnectivity().then((results) {
      final bool hasInternet = results.any((result) => result != ConnectivityResult.none);
      isOnlineNotifier.value = hasInternet;
      patchStatus(isInternetOn: hasInternet);
    });
  }

  Future<void> updateStatus(AppStatus newStatus) async {
    await AppStatusDbHelper.instance.saveStatus(newStatus);
    _currentStatus = newStatus;
  }

  Future<void> patchStatus({
    bool? isFirstTimeUser,
    bool? isTripStarted,
    bool? isInternetOn,
    bool? isGpsOn,
    bool? isTripEnded,
    bool? isLoggedIn,
    String? theme,
    bool? loopAlarm,
    bool? showWaves,
    bool? enableSimulation,
  }) async {
    final current = await status;
    final updated = current.copyWith(
      isFirstTimeUser: isFirstTimeUser,
      isTripStarted: isTripStarted,
      isInternetOn: isInternetOn,
      isGpsOn: isGpsOn,
      isTripEnded: isTripEnded,
      isLoggedIn: isLoggedIn,
      theme: theme,
      loopAlarm: loopAlarm,
      showWaves: showWaves,
      enableSimulation: enableSimulation,
    );
    await updateStatus(updated);
  }

  Future<void> reset() async {
    await updateStatus(
      const AppStatus(
        isFirstTimeUser: true,
        isLoggedIn: false,
        isTripStarted: false,
        isTripEnded: false,
        isInternetOn: false,
        isGpsOn: false,
        theme: 'system',
        accentColor: 4293212469,
        showWaves: true,
      ),
    );
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
