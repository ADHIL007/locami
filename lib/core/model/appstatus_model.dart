class AppStatus {
  final bool isFirstTimeUser;
  final bool isTripStarted;
  final bool isInternetOn;
  final bool isGpsOn;
  final bool isTripEnded;
  final bool isLoggedIn;
  final String theme;

  const AppStatus({
    this.isFirstTimeUser = true,
    this.isTripStarted = false,
    this.isInternetOn = false,
    this.isGpsOn = false,
    this.isTripEnded = false,
    this.isLoggedIn = false,
    this.theme = 'system',
  });

  Map<String, dynamic> toJson() => {
    'isFirstTimeUser': isFirstTimeUser,
    'isTripStarted': isTripStarted,
    'isInternetOn': isInternetOn,
    'isGpsOn': isGpsOn,
    'isTripEnded': isTripEnded,
    'isLoggedIn': isLoggedIn,
    'theme': theme,
  };

  factory AppStatus.fromJson(Map<String, dynamic> json) => AppStatus(
    isFirstTimeUser: json['isFirstTimeUser'] ?? true,
    isTripStarted: json['isTripStarted'] ?? false,
    isInternetOn: json['isInternetOn'] ?? false,
    isGpsOn: json['isGpsOn'] ?? false,
    isTripEnded: json['isTripEnded'] ?? false,
    isLoggedIn: json['isLoggedIn'] ?? false,
    theme: json['theme'] ?? 'system',
  );

  AppStatus copyWith({
    bool? isFirstTimeUser,
    bool? isTripStarted,
    bool? isInternetOn,
    bool? isGpsOn,
    bool? isTripEnded,
    bool? isLoggedIn,
    String? theme,
  }) => AppStatus(
    isFirstTimeUser: isFirstTimeUser ?? this.isFirstTimeUser,
    isTripStarted: isTripStarted ?? this.isTripStarted,
    isInternetOn: isInternetOn ?? this.isInternetOn,
    isGpsOn: isGpsOn ?? this.isGpsOn,
    isTripEnded: isTripEnded ?? this.isTripEnded,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    theme: theme ?? this.theme,
  );
}
