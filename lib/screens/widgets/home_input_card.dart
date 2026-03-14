import 'package:flutter/material.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:locami/core/widgets/glass_container.dart';

class HomeInputCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const HomeInputCard({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.iconColor = Colors.grey,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        opacity: 0.1,
        blur: 20,
        borderRadius: 16,
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
              Icons.chevron_right,
              color: customColors().textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
