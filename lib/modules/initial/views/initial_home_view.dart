import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:locami/modules/initial/controllers/initial_home_controller.dart';

import 'package:locami/theme/them_provider.dart';
import 'package:locami/core/widgets/glass_container.dart';

class InitialHomeView extends GetView<InitialHomeController> {
  const InitialHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.instance;
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: customColors().background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.location_on, color: accentColor, size: 28),
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
                              : customColors().textSecondary.withOpacity(0.3),
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
                          colors: [accentColor, accentColor.withOpacity(0.8)],
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
                              Icons.chevron_right,
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
                Icons.person,
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

        // Search bar
        GlassContainer(
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
                Icons.search,
                color: customColors().textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
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
              final isSelected = controller.userdata['country'] == country;
              final flag = controller.flagMapping[country] ?? '🏳️';

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
                trailing: isSelected ? Icon(Icons.check, color: accentColor) : null,
              );
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
          "Light",
          Icons.wb_sunny_outlined,
          AppThemeMode.light,
          accentColor,
        )),
        const SizedBox(height: 16),
        Obx(() => _buildThemeCard(
          "Dark",
          Icons.dark_mode_outlined,
          AppThemeMode.dark,
          accentColor,
        )),
      ],
    );
  }

  Widget _buildThemeCard(
    String label,
    IconData icon,
    AppThemeMode mode,
    Color accentColor,
  ) {
    final isSelected = controller.userdata['theme'] == mode;

    return GestureDetector(
      onTap: () => controller.setTheme(mode),
      child: GlassContainer(
        height: 80,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        opacity: isSelected ? 0.2 : 0.05,
        blur: 15,
        borderRadius: 16,
        border: Border.all(
          color: isSelected ? accentColor : customColors().borderColor.withOpacity(0.2),
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
            if (isSelected) Icon(Icons.check, color: accentColor, size: 24),
          ],
        ),
      ),
    );
  }
}
