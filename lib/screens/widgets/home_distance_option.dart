import 'package:flutter/material.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';

class HomeDistanceOption extends StatelessWidget {
  final String distance;
  final bool isSelected;
  final VoidCallback? onTap;

  const HomeDistanceOption({
    Key? key,
    required this.distance,
    required this.isSelected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accentColor = context.read<ThemeProvider>().accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              distance,
              style: TextStyle(
                color: isSelected ? customColors().textPrimary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
