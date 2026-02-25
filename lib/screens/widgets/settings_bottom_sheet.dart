import 'package:flutter/material.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Settings",
                style: TextStyle(
                  color: customColors().textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionTitle("Theme"),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildThemeOption(
                context,
                "Light",
                Icons.light_mode_outlined,
                AppThemeMode.light,
                !themeProvider.isMatchWithSystem &&
                    themeProvider.theme == AppThemeMode.light,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context,
                "Dark",
                Icons.dark_mode_outlined,
                AppThemeMode.dark,
                !themeProvider.isMatchWithSystem &&
                    themeProvider.theme == AppThemeMode.dark,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context,
                "System",
                Icons.settings_brightness_outlined,
                null,
                themeProvider.isMatchWithSystem,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle("Accent Style"),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                [
                  const Color(0xFFE53935),
                  const Color(0xFFD81B60),
                  const Color(0xFF8E24AA),
                  const Color(0xFF1E88E5),
                  const Color(0xFF00897B),
                  const Color(0xFFFFB300),
                ].map((color) {
                  final isSelected = accentColor.value == color.value;
                  return GestureDetector(
                    onTap: () => themeProvider.setAccentColor(color),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(backgroundColor: color, radius: 16),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications_none_outlined,
              color: accentColor,
            ),
            title: Text(
              "Alert Sound",
              style: TextStyle(color: customColors().textPrimary),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.grey, fontSize: 14),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    IconData icon,
    AppThemeMode? mode,
    bool isSelected,
  ) {
    final themeProvider = context.read<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (mode == null) {
            themeProvider.setMatchWithSystem(true);
          } else {
            themeProvider.setTheme(mode);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? accentColor.withOpacity(0.1)
                    : customColors().textPrimary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? accentColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? customColors().textPrimary : Colors.grey,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
