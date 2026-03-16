import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:locami/core/widgets/glass_container.dart';

class HomeInputCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const HomeInputCard({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.iconColor = Colors.grey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.instance;
    final isDark = themeProvider.theme == AppThemeMode.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: themeProvider.accentColor.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          opacity: isDark ? 0.1 : 0.6,
          blur: 20,
          borderRadius: 16,
          color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.9),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
            width: 1.5,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: customColors().textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        return Text(
                          value.text.isEmpty ? hint : value.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: customColors().textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Icon(
                SolarIconsOutline.altArrowRight,
                color: customColors().textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
