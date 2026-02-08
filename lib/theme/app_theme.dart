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
  background: Color(0xFFF5F7FB),
  textPrimary: Color(0xFF000000),
  textSecondary: Color(0xFF757575),
  buttonColor: Color(0xFF262628),
  borderColor: Color(0xFFB0B0B0),
  buttonTextColor: Color(0xFFFFFFFF),
);
const ColorTheme darkTheme = ColorTheme(
  background: Color(0xFF0B0F1A),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFB0B0B0),
  buttonColor: Color(0xFFF2F2F2),
  borderColor: Color(0xFFB0B0B0),

  buttonTextColor: Color(0xFF000000),
);
