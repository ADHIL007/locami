import 'package:locami/core/dbHelper/app_status.dart';
import 'package:locami/core/model/appstatus_model.dart';

class AppStatusManager {
  AppStatusManager._internal();
  static final AppStatusManager instance = AppStatusManager._internal();

  AppStatus? _currentStatus;

  Future<AppStatus> get status async {
    if (_currentStatus != null) return _currentStatus!;
    _currentStatus = await AppStatusDbHelper.instance.getStatus();
    return _currentStatus!;
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
    );
    await updateStatus(updated);
  }
}
