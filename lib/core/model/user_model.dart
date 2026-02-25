class UserModel {
  final String username;
  final String country;
  final bool isTravelStarted;
  final bool isTravelEnded;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? totalTravel;
  final String? fromStreet;
  final String? destinationStreet;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? travelMode;

  const UserModel({
    this.username = '',
    this.country = '',
    this.isTravelStarted = false,
    this.isTravelEnded = false,
    this.startTime,
    this.endTime,
    this.totalTravel,
    this.fromStreet,
    this.destinationStreet,
    this.destinationLatitude,
    this.destinationLongitude,
    this.travelMode,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'country': country,
    'isTravelStarted': isTravelStarted,
    'isTravelEnded': isTravelEnded,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'totalTravel': totalTravel?.inSeconds,
    'fromStreet': fromStreet,
    'destinationStreet': destinationStreet,
    'destination_latitude': destinationLatitude,
    'destination_longitude': destinationLongitude,
    'travelMode': travelMode,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    username: json['username'] ?? '',
    country: json['country'] ?? '',
    isTravelStarted: json['isTravelStarted'] ?? false,
    isTravelEnded: json['isTravelEnded'] ?? false,
    startTime:
        json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    totalTravel:
        json['totalTravel'] != null
            ? Duration(seconds: json['totalTravel'])
            : null,
    fromStreet: json['fromStreet'],
    destinationStreet: json['destinationStreet'],
    destinationLatitude: json['destination_latitude'],
    destinationLongitude: json['destination_longitude'],
    travelMode: json['travelMode'],
  );

  UserModel copyWith({
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
  }) => UserModel(
    username: username ?? this.username,
    country: country ?? this.country,
    isTravelStarted: isTravelStarted ?? this.isTravelStarted,
    isTravelEnded: isTravelEnded ?? this.isTravelEnded,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    totalTravel: totalTravel ?? this.totalTravel,
    fromStreet: fromStreet ?? this.fromStreet,
    destinationStreet: destinationStreet ?? this.destinationStreet,
    destinationLatitude: destinationLatitude ?? this.destinationLatitude,
    destinationLongitude: destinationLongitude ?? this.destinationLongitude,
    travelMode: travelMode ?? this.travelMode,
  );
}
