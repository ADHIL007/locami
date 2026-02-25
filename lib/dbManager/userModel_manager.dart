import 'package:locami/core/dbHelper/user_db.dart';
import 'package:locami/core/model/user_model.dart';

class UserModelManager {
  UserModelManager._internal();
  static final UserModelManager instance = UserModelManager._internal();

  UserModel? _currentUser;

  Future<UserModel> get user async {
    if (_currentUser != null) return _currentUser!;
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
  }) async {
    final current = await user;
    final updated = current.copyWith(
      username: username,
      country: country,
      isTravelStarted: isTravelStarted,
      isTravelEnded: isTravelEnded,
      startTime: startTime,
      endTime: endTime,
      totalTravel: totalTravel,
      fromStreet: fromStreet,
      destinationStreet: destinationStreet,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
      travelMode: travelMode,
    );

    await updateUser(updated);
  }

  Future<void> clear() async {
    await UserDbHelper.instance.clearUser();
    _currentUser = const UserModel();
  }
}
