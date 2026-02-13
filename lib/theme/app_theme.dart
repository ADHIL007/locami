import 'package:flutter/material.dart';

final ThemeData materialLightTheme = ThemeData.light();
final ThemeData materialDarkTheme = ThemeData.dark();

@immutable
@immutable
class ColorTheme {
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color buttonColor;
  final Color buttonTextColor;
  const ColorTheme({
    required this.textSecondary,
    required this.buttonColor,
    required this.background,
    required this.textPrimary,
    required this.borderColor,
    required this.buttonTextColor,
  });
}

const ColorTheme lightTheme = ColorTheme(
  background: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF111111),
  textSecondary: Color(0xFF6B6B6B),
  borderColor: Color(0xFFE0E0E0),
  buttonColor: Color(0xFF111111),
  buttonTextColor: Color(0xFFFFFFFF),
);

const ColorTheme darkTheme = ColorTheme(
  background: Color(0xFF0E0E0E),
  textPrimary: Color(0xFFF5F5F5),
  textSecondary: Color(0xFF9A9A9A),
  borderColor: Color(0xFF2A2A2A),
  buttonColor: Color(0xFFF5F5F5),
  buttonTextColor: Color(0xFF0E0E0E),
);
