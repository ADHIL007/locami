import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:locami/dbManager/app_status_manager.dart';
import 'package:locami/dbManager/trip_details_manager.dart';
import 'package:locami/dbManager/user_model_manager.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:locami/core/widgets/glass_container.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:locami/navigation/main_nav.dart';
import 'package:locami/core/utils/environment.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      opacity: themeProvider.theme == AppThemeMode.dark ? 0.15 : 0.7,
      blur: 25,
      color: themeProvider.theme == AppThemeMode.dark ? Colors.white : Colors.white.withValues(alpha: 0.9),
      borderRadius: 24,
      border: Border.all(
        color: themeProvider.theme == AppThemeMode.dark 
            ? Colors.white.withValues(alpha: 0.1) 
            : Colors.white.withValues(alpha: 0.5),
        width: 1.5,
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
                icon: Icon(SolarIconsOutline.closeCircle, color: customColors().textSecondary),
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
                SolarIconsOutline.sun,
                AppThemeMode.light,
                !themeProvider.isMatchWithSystem &&
                    themeProvider.theme == AppThemeMode.light,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context,
                "Dark",
                SolarIconsOutline.moon,
                AppThemeMode.dark,
                !themeProvider.isMatchWithSystem &&
                    themeProvider.theme == AppThemeMode.dark,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context,
                "System",
                SolarIconsOutline.sun2,
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
                  final isSelected = accentColor.toARGB32() == color.toARGB32();
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
               SolarIconsOutline.bell,
               color: accentColor,
            ),
            title: Text(
              "Alert Sound",
              style: TextStyle(color: customColors().textPrimary),
            ),
            subtitle: Text(
              themeProvider.alertSoundName,
              style: TextStyle(
                color: customColors().textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: Icon(
               SolarIconsOutline.altArrowRight,
               color: customColors().textSecondary,
            ),
            onTap: () => _showSoundPicker(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(SolarIconsOutline.repeat, color: accentColor),
            title: Text(
              "Loop Alarm",
              style: TextStyle(color: customColors().textPrimary),
            ),
            trailing: Switch(
              value: themeProvider.loopAlarm,
              activeColor: accentColor,
              onChanged: (val) => themeProvider.setLoopAlarm(val),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(SolarIconsOutline.soundwave, color: accentColor),
            title: Text(
              "Background Waves",
              style: TextStyle(color: customColors().textPrimary),
            ),
            trailing: Switch(
              value: themeProvider.showWaves,
              activeColor: accentColor,
              onChanged: (val) => themeProvider.setShowWaves(val),
            ),
          ),
          if (EnvironmentConfig.isDevelopment) ...[
            const SizedBox(height: 24),
            _buildSectionTitle("Developer Debug"),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(SolarIconsOutline.mapPoint, color: accentColor),
              title: Text(
                "Enable Location Simulation",
                style: TextStyle(color: customColors().textPrimary),
              ),
              trailing: Switch(
                value: themeProvider.enableSimulation,
                activeColor: accentColor,
                onChanged: (val) => themeProvider.setEnableSimulation(val),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(SolarIconsOutline.stopwatch, color: accentColor),
              title: Text(
                "Enable Timer Simulation",
                style: TextStyle(color: customColors().textPrimary),
              ),
              trailing: Switch(
                value: themeProvider.enableTimerSimulation,
                activeColor: accentColor,
                onChanged: (val) => themeProvider.setEnableTimerSimulation(val),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
               SolarIconsOutline.trashBinTrash,
              color: Colors.red,
            ),
            title: const Text(
              "Delete All Data",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: () => _showDeleteConfirmation(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static final AudioPlayer _audioPlayer = AudioPlayer();

  void _showSoundPicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => GlassContainer(
            padding: const EdgeInsets.all(24),
            opacity: themeProvider.theme == AppThemeMode.dark ? 0.15 : 0.7,
            blur: 25,
            color: themeProvider.theme == AppThemeMode.dark ? Colors.white : Colors.white.withValues(alpha: 0.9),
            borderRadius: 24,
            border: Border.all(
              color: themeProvider.theme == AppThemeMode.dark 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Alert Sound",
                  style: TextStyle(
                    color: customColors().textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSoundOption(
                  context,
                  "Default Alarm",
                  "alarm",
                  themeProvider,
                ),
                _buildSoundOption(
                  context,
                  "Default Ringtone",
                  "ringtone",
                  themeProvider,
                ),
                _buildSoundOption(
                  context,
                  "Default Notification",
                  "notification",
                  themeProvider,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                     SolarIconsOutline.musicLibrary,
                    color: accentColor,
                  ),
                  title: Text(
                    "Pick from Device",
                    style: TextStyle(color: customColors().textPrimary),
                  ),
                  subtitle: Text(
                    themeProvider.isCustomSound
                        ? themeProvider.alertSoundName
                        : "Select local audio file",
                    style: TextStyle(
                      color: customColors().textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(SolarIconsOutline.addCircle, size: 20),
                  onTap: () => _pickCustomFile(context),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      FlutterRingtonePlayer().stop();
                      _audioPlayer.stop();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Done"),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSoundOption(
    BuildContext context,
    String name,
    String key,
    ThemeProvider provider,
  ) {
    final isSelected = provider.alertSound == key;
    final accentColor = provider.accentColor;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        name,
        style: TextStyle(
          color: isSelected ? accentColor : customColors().textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected
              ? Icon(SolarIconsBold.checkCircle, color: accentColor)
              : Icon(
                 SolarIconsOutline.closeCircle,
                 color: customColors().textSecondary,
              ),
      onTap: () {
        provider.setAlertSound(key, name);
        // Play sample
        _audioPlayer.stop();
        FlutterRingtonePlayer().stop();
        if (key == 'alarm') {
          FlutterRingtonePlayer().playAlarm();
        } else if (key == 'ringtone') {
          FlutterRingtonePlayer().playRingtone();
        } else {
          FlutterRingtonePlayer().playNotification();
        }
      },
    );
  }

  Future<void> _pickCustomFile(BuildContext context) async {
    final themeProvider = context.read<ThemeProvider>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;

      themeProvider.setCustomSound(path, name);

      // Play sample
      FlutterRingtonePlayer().stop();
      _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              "Delete All Data?",
              style: TextStyle(color: customColors().textPrimary),
            ),
            content: Text(
              "This will permanently delete all your trip history and profile data. This action cannot be undone.",
              style: TextStyle(color: customColors().textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: customColors().textSecondary),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // Clear data
                  await TripDetailsManager.instance.clearLogs();
                  await UserModelManager.instance.clear();
                  await AppStatusManager.instance.reset();

                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNav()),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: customColors().textSecondary, fontSize: 14),
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
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 12),
          opacity: isSelected ? 0.2 : 0.05,
          blur: 10,
          borderRadius: 12,
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? accentColor : customColors().textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? customColors().textPrimary
                          : customColors().textSecondary,
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
