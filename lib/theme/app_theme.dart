import 'package:flutter/material.dart';

final ThemeData materialLightTheme = ThemeData.light();
final ThemeData materialDarkTheme = ThemeData.dark();

@immutable
@immutable
class ColorTheme {
  final Color background;
  final Color card;
  final Color cardSecondary;
  final Color modal;

  final Color border;
  final Color divider;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;

  final List<Color> primaryGradient;
  final List<Color> secondaryGradient;

  final Color income;
  final Color expense;
  final Color warning;
  final Color info;

  const ColorTheme({
    required this.background,
    required this.card,
    required this.cardSecondary,
    required this.modal,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.income,
    required this.expense,
    required this.warning,
    required this.info,
  });
}

const ColorTheme lightTheme = ColorTheme(
  background: Color(0xFFF5F7FB),
  card: Color(0xFFFFFFFF),
  cardSecondary: Color(0xFFF0F3F8),
  modal: Color(0xFFFFFFFF),

  border: Color(0xFFE2E8F0),
  divider: Color(0xFFCBD5E1),

  textPrimary: Color(0xFF1E293B),
  textSecondary: Color(0xFF475569),
  textMuted: Color(0xFF94A3B8),
  textInverse: Color(0xFFFFFFFF),

  primaryGradient: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],

  secondaryGradient: [Color(0xFF06B6D4), Color(0xFF22C55E)],

  income: Color(0xFF16A34A),
  expense: Color(0xFFDC2626),
  warning: Color(0xFFF59E0B),
  info: Color(0xFF2563EB),
);
const ColorTheme darkTheme = ColorTheme(
  background: Color(0xFF0B0F1A),
  card: Color(0xFF121829),
  cardSecondary: Color(0xFF0F172A),
  modal: Color(0xFF101626),

  border: Color(0xFF1E293B),
  divider: Color(0xFF1F2937),

  textPrimary: Color(0xFFE5E7EB),
  textSecondary: Color(0xFF9CA3AF),
  textMuted: Color(0xFF6B7280),
  textInverse: Color(0xFF0B0F1A),

  primaryGradient: [Color(0xFF4F46E5), Color(0xFF9333EA)],

  secondaryGradient: [Color(0xFF22D3EE), Color(0xFF22C55E)],

  income: Color(0xFF4ADE80),
  expense: Color(0xFFF87171),
  warning: Color(0xFFFBBF24),
  info: Color(0xFF60A5FA),
);
