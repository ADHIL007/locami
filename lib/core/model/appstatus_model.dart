class AppStatus {
  final bool isFirstTimeUser;
  final bool isTripStarted;
  final bool isInternetOn;
  final bool isGpsOn;
  final bool isTripEnded;
  final bool isLoggedIn;
  final String theme;
  final int accentColor;
  final String alertSound;
  final String alertSoundName;
  final bool isCustomSound;
  final String? customSoundPath;

  const AppStatus({
    this.isFirstTimeUser = true,
    this.isTripStarted = false,
    this.isInternetOn = false,
    this.isGpsOn = false,
    this.isTripEnded = false,
    this.isLoggedIn = false,
    this.theme = 'system',
    this.accentColor = 0xFFE53935,
    this.alertSound = 'alarm',
    this.alertSoundName = 'Default Alarm',
    this.isCustomSound = false,
    this.customSoundPath,
  });

  Map<String, dynamic> toJson() => {
    'isFirstTimeUser': isFirstTimeUser,
    'isTripStarted': isTripStarted,
    'isInternetOn': isInternetOn,
    'isGpsOn': isGpsOn,
    'isTripEnded': isTripEnded,
    'isLoggedIn': isLoggedIn,
    'theme': theme,
    'accentColor': accentColor,
    'alertSound': alertSound,
    'alertSoundName': alertSoundName,
    'isCustomSound': isCustomSound,
    'customSoundPath': customSoundPath,
  };

  factory AppStatus.fromJson(Map<String, dynamic> json) => AppStatus(
    isFirstTimeUser: json['isFirstTimeUser'] ?? true,
    isTripStarted: json['isTripStarted'] ?? false,
    isInternetOn: json['isInternetOn'] ?? false,
    isGpsOn: json['isGpsOn'] ?? false,
    isTripEnded: json['isTripEnded'] ?? false,
    isLoggedIn: json['isLoggedIn'] ?? false,
    theme: json['theme'] ?? 'system',
    accentColor: json['accentColor'] ?? 0xFFE53935,
    alertSound: json['alertSound'] ?? 'alarm',
    alertSoundName: json['alertSoundName'] ?? 'Default Alarm',
    isCustomSound: json['isCustomSound'] ?? false,
    customSoundPath: json['customSoundPath'],
  );

  AppStatus copyWith({
    bool? isFirstTimeUser,
    bool? isTripStarted,
    bool? isInternetOn,
    bool? isGpsOn,
    bool? isTripEnded,
    bool? isLoggedIn,
    String? theme,
    int? accentColor,
    String? alertSound,
    String? alertSoundName,
    bool? isCustomSound,
    String? customSoundPath,
  }) => AppStatus(
    isFirstTimeUser: isFirstTimeUser ?? this.isFirstTimeUser,
    isTripStarted: isTripStarted ?? this.isTripStarted,
    isInternetOn: isInternetOn ?? this.isInternetOn,
    isGpsOn: isGpsOn ?? this.isGpsOn,
    isTripEnded: isTripEnded ?? this.isTripEnded,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    theme: theme ?? this.theme,
    accentColor: accentColor ?? this.accentColor,
    alertSound: alertSound ?? this.alertSound,
    alertSoundName: alertSoundName ?? this.alertSoundName,
    isCustomSound: isCustomSound ?? this.isCustomSound,
    customSoundPath: customSoundPath ?? this.customSoundPath,
  );
}
