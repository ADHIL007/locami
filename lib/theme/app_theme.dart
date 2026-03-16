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
  background: Color(0xFFF8FAFC), // Slate 50
  textPrimary: Color(0xFF0F172A), // Slate 900
  textSecondary: Color(0xFF64748B), // Slate 500
  borderColor: Color(0xFFE2E8F0), // Slate 200
  buttonColor: Color(0xFF0F172A),
  buttonTextColor: Color(0xFFFFFFFF),
);

const ColorTheme darkTheme = ColorTheme(
  background: Color(0xFF0E0E0E),
  textPrimary: Color(0xFFF5F5F5),
  textSecondary: Color(0xFFB0B0B0),
  borderColor: Color(0xFF2A2A2A),
  buttonColor: Color(0xFFF5F5F5),
  buttonTextColor: Color(0xFF0E0E0E),
);
