import 'package:flutter/material.dart';
import 'package:locami/core/db_helper/app_status.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/theme/app_theme.dart';
import 'package:locami/core/utils/environment.dart';

enum AppThemeMode { light, dark }

class ThemeProvider extends ChangeNotifier {
  ThemeProvider._internal() {
    _applyTheme();
  }

  static final ThemeProvider instance = ThemeProvider._internal();

  factory ThemeProvider() => instance;

  static ColorTheme currentTheme = lightTheme;

  ThemeData _themeData = materialLightTheme;
  ThemeData get themeData => _themeData;

  bool get isDarkMode => theme == AppThemeMode.dark;

  AppThemeMode theme = AppThemeMode.light;
  bool isMatchWithSystem = true;
  Color accentColor = const Color(0xFFE53935);
  String alertSound = 'alarm';
  String alertSoundName = 'Default Alarm';
  bool isCustomSound = false;
  String? customSoundPath;
  bool loopAlarm = true;
  bool showWaves = true;
  bool enableSimulation = false;
  bool enableTimerSimulation = false;
  String uiMode = 'high'; // 'low', 'mid', 'high'
  bool enableVibration = true;
  bool enableBackgroundMapDownload = true;

  void _applyTheme() {
    if (isMatchWithSystem) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;

      if (brightness == Brightness.dark) {
        _setDark();
      } else {
        _setLight();
      }
    } else {
      if (theme == AppThemeMode.dark) {
        _setDark();
      } else {
        _setLight();
      }
    }
  }

  void _setLight() {
    theme = AppThemeMode.light;
    currentTheme = lightTheme;
    _themeData = ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: accentColor,
      cardColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: accentColor,
        surface: Colors.white,
        onPrimary: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: accentColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  void _setDark() {
    theme = AppThemeMode.dark;
    currentTheme = darkTheme;
    _themeData = ThemeData.dark().copyWith(
      primaryColor: accentColor,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
      ),
    );
  }

  void setMatchWithSystem(bool value) {
    isMatchWithSystem = value;
    _applyTheme();
    notifyListeners();
  }

  void setTheme(AppThemeMode mode) {
    theme = mode;
    isMatchWithSystem = false;
    _applyTheme();
    _saveStatus();
    notifyListeners();
  }

  void setAccentColor(Color color) {
    accentColor = color;
    _applyTheme();
    _saveStatus();
    notifyListeners();
  }

  void setAlertSound(String sound, String name) {
    alertSound = sound;
    alertSoundName = name;
    isCustomSound = false;
    _saveStatus();
    notifyListeners();
  }

  void setCustomSound(String path, String name) {
    customSoundPath = path;
    alertSoundName = name;
    isCustomSound = true;
    _saveStatus();
    notifyListeners();
  }

  void setLoopAlarm(bool value) {
    loopAlarm = value;
    _saveStatus();
    notifyListeners();
  }

  void setShowWaves(bool value) {
    showWaves = value;
    _saveStatus();
    notifyListeners();
  }

  void setEnableSimulation(bool value) {
    if (!EnvironmentConfig.isDevelopment) {
      enableSimulation = false;
    } else {
      enableSimulation = value;
    }
    _saveStatus();
    notifyListeners();
  }

  void setEnableTimerSimulation(bool value) {
    if (!EnvironmentConfig.isDevelopment) {
      enableTimerSimulation = false;
    } else {
      enableTimerSimulation = value;
    }
    _saveStatus();
    notifyListeners();
  }

  void setUiMode(String mode) {
    uiMode = mode;
    _saveStatus();
    notifyListeners();
  }

  void setEnableVibration(bool value) {
    enableVibration = value;
    _saveStatus();
    notifyListeners();
  }

  void setEnableBackgroundMapDownload(bool value) {
    enableBackgroundMapDownload = value;
    _saveStatus();
    notifyListeners();
  }

  Future<void> _saveStatus() async {
    final status = await AppStatusDbHelper.instance.getStatus();
    await AppStatusDbHelper.instance.saveStatus(
      status.copyWith(
        theme:
            isMatchWithSystem
                ? 'system'
                : (theme == AppThemeMode.dark ? 'dark' : 'light'),
        accentColor: accentColor.toARGB32(),
        alertSound: alertSound,
        alertSoundName: alertSoundName,
        isCustomSound: isCustomSound,
        customSoundPath: customSoundPath,
        loopAlarm: loopAlarm,
        showWaves: showWaves,
        enableSimulation: enableSimulation,
        enableTimerSimulation: enableTimerSimulation,
        uiMode: uiMode,
        enableVibration: enableVibration,
        enableBackgroundMapDownload: enableBackgroundMapDownload,
      ),
    );
  }

  void applyFromStatus(AppStatus status) {
    if (status.theme == 'system') {
      isMatchWithSystem = true;
    } else {
      isMatchWithSystem = false;
      theme = status.theme == 'dark' ? AppThemeMode.dark : AppThemeMode.light;
    }
    accentColor = Color(status.accentColor);
    _applyTheme();
    alertSound = status.alertSound;
    alertSoundName = status.alertSoundName;
    isCustomSound = status.isCustomSound;
    customSoundPath = status.customSoundPath;
    loopAlarm = status.loopAlarm;
    showWaves = status.showWaves;
    enableSimulation =
        EnvironmentConfig.isDevelopment && status.enableSimulation;
    enableTimerSimulation =
        EnvironmentConfig.isDevelopment && status.enableTimerSimulation;
    uiMode = status.uiMode;
    enableVibration = status.enableVibration;
    enableBackgroundMapDownload = status.enableBackgroundMapDownload;
    notifyListeners();
  }
}

ColorTheme customColors() {
  return ThemeProvider.currentTheme;
}
