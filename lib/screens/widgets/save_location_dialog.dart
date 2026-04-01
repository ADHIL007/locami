import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:locami/core/db_helper/saved_location_db.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:locami/modules/home/controllers/home_controller.dart';

/// Dialog for tagging/labeling a location (Home, Work, Gym, custom name).
class SaveLocationDialog extends StatefulWidget {
  final String displayName;
  final double latitude;
  final double longitude;

  const SaveLocationDialog({
    super.key,
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  /// Show the dialog and return the saved location (or null if cancelled).
  static Future<SavedLocation?> show(
    BuildContext context, {
    required String displayName,
    required double latitude,
    required double longitude,
  }) {
    return showDialog<SavedLocation?>(
      context: context,
      builder: (_) => SaveLocationDialog(
        displayName: displayName,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  @override
  State<SaveLocationDialog> createState() => _SaveLocationDialogState();
}

class _SaveLocationDialogState extends State<SaveLocationDialog> {
  final _labelController = TextEditingController();
  String _selectedIcon = 'place';
  bool _isSaving = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final saved = await Get.find<HomeController>().saveTaggedLocation(
        label: label,
        displayName: widget.displayName,
        latitude: widget.latitude,
        longitude: widget.longitude,
        icon: _selectedIcon,
      );
      if (mounted) Navigator.of(context).pop(saved);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.theme == AppThemeMode.dark;
    final accentColor = themeProvider.accentColor;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black45;

    final icons = SavedLocation.iconOptions();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Save Location',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.displayName,
                style: TextStyle(color: subColor, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // Label input
              TextField(
                controller: _labelController,
                autofocus: true,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Label (e.g. Home, Office)',
                  hintStyle: TextStyle(color: subColor),
                  filled: true,
                  fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Icon picker
              Text(
                'Category',
                style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: icons.entries.map((entry) {
                  final isSelected = _selectedIcon == entry.key;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIcon = entry.key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.15)
                            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? accentColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        entry.value,
                        color: isSelected ? accentColor : subColor,
                        size: 26,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: TextStyle(color: subColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
