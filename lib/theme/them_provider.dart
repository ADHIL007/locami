import 'package:flutter/material.dart';
import 'package:locami/core/dbHelper/app_status.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/theme/app_theme.dart';

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

  AppThemeMode theme = AppThemeMode.light;
  bool isMatchWithSystem = true;
  Color accentColor = const Color(0xFFE53935);

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
    _themeData = materialLightTheme;
  }

  void _setDark() {
    theme = AppThemeMode.dark;
    currentTheme = darkTheme;
    _themeData = materialDarkTheme;
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
        accentColor: accentColor.value,
      ),
    );
  }

  void applyFromStatus(AppStatus status) {
    if (status.theme == 'system') {
      setMatchWithSystem(true);
    } else {
      setMatchWithSystem(false);
      setTheme(status.theme == 'dark' ? AppThemeMode.dark : AppThemeMode.light);
    }
    accentColor = Color(status.accentColor);
    notifyListeners();
  }
}

ColorTheme customColors() {
  return ThemeProvider.currentTheme;
}
