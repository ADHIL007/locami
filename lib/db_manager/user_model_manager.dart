import 'package:locami/core/db_helper/user_db.dart';
import 'package:locami/core/model/user_model.dart';

class UserModelManager {
  UserModelManager._internal();
  static final UserModelManager instance = UserModelManager._internal();

  UserModel? _currentUser;

  Future<UserModel> get user async {
    _currentUser = await UserDbHelper.instance.getUser();
    return _currentUser!;
  }

  Future<void> updateUser(UserModel newUser) async {
    await UserDbHelper.instance.saveUser(newUser);
    _currentUser = newUser;
  }

  Future<void> patchUser({
    String? username,
    String? country,
    bool? isTravelStarted,
    bool? isTravelEnded,
    DateTime? startTime,
    DateTime? endTime,
    Duration? totalTravel,
    String? fromStreet,
    String? destinationStreet,
    double? destinationLatitude,
    double? destinationLongitude,
    String? travelMode,
    double? alertDistance,
    String? currentTripId,
    bool? isAlarmActive,
    double? totalTripDistance,
    bool clearDestination = false,
  }) async {
    final current = await user;
    final bool streetChanged = destinationStreet != null && destinationStreet != current.destinationStreet;

    final updated = UserModel(
      username: username ?? current.username,
      country: country ?? current.country,
      isTravelStarted: isTravelStarted ?? current.isTravelStarted,
      isTravelEnded: isTravelEnded ?? current.isTravelEnded,
      startTime: startTime ?? current.startTime,
      endTime: endTime ?? current.endTime,
      totalTravel: totalTravel ?? current.totalTravel,
      fromStreet: fromStreet ?? current.fromStreet,
      destinationStreet: clearDestination ? null : (destinationStreet ?? current.destinationStreet),
      destinationLatitude: clearDestination ? null : (destinationLatitude ?? (streetChanged ? null : current.destinationLatitude)),
      destinationLongitude: clearDestination ? null : (destinationLongitude ?? (streetChanged ? null : current.destinationLongitude)),
      travelMode: travelMode ?? current.travelMode,
      alertDistance: alertDistance ?? current.alertDistance,
      currentTripId: currentTripId ?? current.currentTripId,
      isAlarmActive: isAlarmActive ?? current.isAlarmActive,
      totalTripDistance: clearDestination ? null : (totalTripDistance ?? current.totalTripDistance),
    );

    await updateUser(updated);
  }

  Future<void> clear() async {
    await UserDbHelper.instance.clearUser();
    _currentUser = const UserModel();
  }
}
