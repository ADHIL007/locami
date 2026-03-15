import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'package:locami/modules/initial/controllers/initial_home_controller.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:locami/core/widgets/glass_container.dart';
import 'package:locami/core/widgets/reflector_bg.dart';
import 'dart:ui';

class InitialHomeView extends GetView<InitialHomeController> {
  const InitialHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Dynamic Background
          ReflectionBackground(accentColor: accentColor, speed: 0.8),
          
          // Blur Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.themeData.scaffoldBackgroundColor.withValues(alpha: 0.4),
                      accentColor.withValues(alpha: 0.04),
                      themeProvider.themeData.scaffoldBackgroundColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(SolarIconsBold.mapPoint, color: accentColor, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          "Locami",
                          style: TextStyle(
                            color: customColors().textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Progress and Page Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Obx(() => IndexedStack(
                          index: controller.index.value,
                          children: [
                            _buildNameStep(accentColor),
                            _buildCountryStep(accentColor),
                            _buildThemeStep(accentColor),
                          ],
                        )),
                      ),
                    ),

                    // Footer
                    Column(
                      children: [
                        // Step Indicator Dots
                        Obx(() => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == controller.index.value
                                    ? accentColor
                                    : customColors().textSecondary.withValues(alpha: 0.3),
                              ),
                            );
                          }),
                        )),
                        const SizedBox(height: 12),
                        Obx(() => Text(
                          "Step ${controller.index.value + 1} of 3",
                          style: TextStyle(
                            color: customColors().textSecondary,
                            fontSize: 12,
                          ),
                        )),
                        const SizedBox(height: 24),

                        // Main Button
                        GestureDetector(
                          onTap: controller.validateNext,
                          child: Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Obx(() => Text(
                                  controller.index.value == 0 ? "Continue" : "Next",
                                  style: TextStyle(
                                    color: customColors().buttonTextColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                                Positioned(
                                  right: 20,
                                  child: Icon(
                                    SolarIconsOutline.altArrowRight,
                                    color: customColors().buttonTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: customColors().textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: customColors().textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNameStep(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader("What's your name?", "Enter your name to continue."),
        GlassContainer(
          opacity: 0.1,
          blur: 10,
          borderRadius: 12,
          child: TextField(
            controller: controller.nameController,
            style: TextStyle(color: customColors().textPrimary),
            decoration: InputDecoration(
              hintText: "Name",
              hintStyle: TextStyle(color: customColors().textSecondary),
              prefixIcon: Icon(
                SolarIconsOutline.user,
                color: customColors().textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onSubmitted: (_) => controller.validateNext(),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryStep(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          "Select your country",
          "This helps display details accurately.",
        ),

        Row(
          children: [
            Expanded(
              child: GlassContainer(
                opacity: 0.1,
                blur: 10,
                borderRadius: 12,
                child: TextField(
                  controller: controller.countrySearchController,
                  onChanged: controller.filterCountries,
                  style: TextStyle(color: customColors().textPrimary),
                  decoration: InputDecoration(
                    hintText: "Search country",
                    hintStyle: TextStyle(color: customColors().textSecondary),
                    prefixIcon: Icon(
                      SolarIconsOutline.mapPointSearch,
                      color: customColors().textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => GestureDetector(
              onTap: controller.isLocating.value ? null : controller.autoLocateCountry,
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: controller.isLocating.value
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(SolarIconsOutline.gps, color: accentColor),
              ),
            )),
          ],
        ),
        const SizedBox(height: 20),

        // List of countries
        SizedBox(
          height: 300,
          child: Obx(() => ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: controller.filteredCountries.length,
            separatorBuilder: (context, index) => Divider(color: customColors().borderColor, height: 1),
            itemBuilder: (context, index) {
              final country = controller.filteredCountries[index];
              final flag = controller.flagMapping[country] ?? '🏳️';
              return Obx(() {
                final isSelected = controller.userdata['country'] == country;
                return ListTile(
                  onTap: () => controller.selectCountry(country),
                  contentPadding: EdgeInsets.zero,
                  leading: Text(flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    country,
                    style: TextStyle(
                      color: isSelected ? customColors().textPrimary : customColors().textSecondary,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? Icon(SolarIconsBold.checkCircle, color: accentColor) : null,
                );
              });
            },
          )),
        ),
      ],
    );
  }

  Widget _buildThemeStep(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader("Choose your theme", "Pick the app theme you prefer."),

        Obx(() => _buildThemeCard(
          "System Default",
          SolarIconsOutline.sun2,
          'system',
          accentColor,
        )),
        const SizedBox(height: 16),
        Obx(() => _buildThemeCard(
          "Light",
          SolarIconsOutline.sun,
          'light',
          accentColor,
        )),
        const SizedBox(height: 16),
        Obx(() => _buildThemeCard(
          "Dark",
          SolarIconsOutline.moon,
          'dark',
          accentColor,
        )),
      ],
    );
  }

  Widget _buildThemeCard(
    String label,
    IconData icon,
    String mode, // 'light', 'dark', or 'system'
    Color accentColor,
  ) {
    final isSelected = controller.userdata['theme'] == mode;

    return GestureDetector(
      onTap: () {
        if (mode == 'system') {
          controller.setThemeToSystem();
        } else if (mode == 'light') {
          controller.setTheme(AppThemeMode.light);
        } else {
          controller.setTheme(AppThemeMode.dark);
        }
      },
      child: GlassContainer(
        height: 80,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        opacity: isSelected ? 0.2 : 0.05,
        blur: 15,
        borderRadius: 16,
        border: Border.all(
          color: isSelected ? accentColor : customColors().borderColor.withValues(alpha: 0.2),
          width: 2,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: customColors().textPrimary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(label,
              style: TextStyle(
                color: customColors().textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(SolarIconsBold.checkCircle, color: accentColor, size: 24),
          ],
        ),
      ),
    );
  }
}
