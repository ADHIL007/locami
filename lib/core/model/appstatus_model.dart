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
  final bool loopAlarm;
  final bool showWaves;
  final bool enableSimulation;
  final bool enableTimerSimulation;
  final String uiMode; // 'low', 'mid', 'high'
  final bool enableVibration;

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
    this.loopAlarm = true,
    this.showWaves = true,
    this.enableSimulation = false,
    this.enableTimerSimulation = false,
    this.uiMode = 'high',
    this.enableVibration = true,
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
    'loopAlarm': loopAlarm,
    'showWaves': showWaves,
    'enableSimulation': enableSimulation,
    'enableTimerSimulation': enableTimerSimulation,
    'uiMode': uiMode,
    'enableVibration': enableVibration,
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
    loopAlarm: json['loopAlarm'] ?? true,
    showWaves: json['showWaves'] ?? true,
    enableSimulation: json['enableSimulation'] ?? false,
    enableTimerSimulation: json['enableTimerSimulation'] ?? false,
    uiMode: json['uiMode'] ?? 'high',
    enableVibration: json['enableVibration'] ?? true,
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
    bool? loopAlarm,
    bool? showWaves,
    bool? enableSimulation,
    bool? enableTimerSimulation,
    String? uiMode,
    bool? enableVibration,
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
    loopAlarm: loopAlarm ?? this.loopAlarm,
    showWaves: showWaves ?? this.showWaves,
    enableSimulation: enableSimulation ?? this.enableSimulation,
    enableTimerSimulation: enableTimerSimulation ?? this.enableTimerSimulation,
    uiMode: uiMode ?? this.uiMode,
    enableVibration: enableVibration ?? this.enableVibration,
  );
}
