class AppStatus {
  final bool isFirstTimeUser;
  final bool isTripStarted;
  final bool isInternetOn;
  final bool isGpsOn;
  final bool isTripEnded;

  AppStatus({
    this.isFirstTimeUser = true,
    this.isTripStarted = false,
    this.isInternetOn = false,
    this.isGpsOn = false,
    this.isTripEnded = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'isFirstTimeUser': isFirstTimeUser,
      'isTripStarted': isTripStarted,
      'isInternetOn': isInternetOn,
      'isGpsOn': isGpsOn,
      'isTripEnded': isTripEnded,
    };
  }

  factory AppStatus.fromJson(Map<String, dynamic> json) {
    return AppStatus(
      isFirstTimeUser: json['isFirstTimeUser'] ?? true,
      isTripStarted: json['isTripStarted'] ?? false,
      isInternetOn: json['isInternetOn'] ?? false,
      isGpsOn: json['isGpsOn'] ?? false,
      isTripEnded: json['isTripEnded'] ?? false,
    );
  }

  static List<AppStatus> fromTable(List<Map<String, dynamic>> table) {
    return table.map((json) => AppStatus.fromJson(json)).toList();
  }

  static List<Map<String, dynamic>> toTable(List<AppStatus> list) {
    return list.map((item) => item.toJson()).toList();
  }

  static List<AppStatus> jsonToTable(List<dynamic> jsonList) {
    return jsonList
        .map((item) => AppStatus.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static List<Map<String, dynamic>> tableToJson(List<AppStatus> table) {
    return table.map((item) => item.toJson()).toList();
  }

  AppStatus copyWith({
    bool? isFirstTimeUser,
    bool? isTripStarted,
    bool? isInternetOn,
    bool? isGpsOn,
    bool? isTripEnded,
  }) {
    return AppStatus(
      isFirstTimeUser: isFirstTimeUser ?? this.isFirstTimeUser,
      isTripStarted: isTripStarted ?? this.isTripStarted,
      isInternetOn: isInternetOn ?? this.isInternetOn,
      isGpsOn: isGpsOn ?? this.isGpsOn,
      isTripEnded: isTripEnded ?? this.isTripEnded,
    );
  }

  @override
  String toString() {
    return 'AppStatus(isFirstTimeUser: $isFirstTimeUser, isTripStarted: $isTripStarted, isInternetOn: $isInternetOn, isGpsOn: $isGpsOn, isTripEnded: $isTripEnded)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppStatus &&
        other.isFirstTimeUser == isFirstTimeUser &&
        other.isTripStarted == isTripStarted &&
        other.isInternetOn == isInternetOn &&
        other.isGpsOn == isGpsOn &&
        other.isTripEnded == isTripEnded;
  }

  @override
  int get hashCode {
    return isFirstTimeUser.hashCode ^
        isTripStarted.hashCode ^
        isInternetOn.hashCode ^
        isGpsOn.hashCode ^
        isTripEnded.hashCode;
  }
}
