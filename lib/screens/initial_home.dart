import 'package:flutter/material.dart';
import 'package:locami/core/model/user_model.dart';
import 'package:locami/dbManager/app-status_manager.dart';
import 'package:locami/core/dataset/country_list.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/dbManager/userModel_manager.dart';
import 'package:locami/screens/home.dart';
import 'package:locami/theme/app_theme.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';

class InitialHome extends StatefulWidget {
  const InitialHome({Key? key}) : super(key: key);

  @override
  _InitialHomeState createState() => _InitialHomeState();
}

class _InitialHomeState extends State<InitialHome> {
  int index = 0;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController countrySearchController = TextEditingController();
  List<String> countries = [];
  List<String> filteredCountries = [];
  bool isSubmitted = false;

  Map<String, dynamic> userdata = {
    'name': '',
    'country': '',
    'theme': AppThemeMode.dark, // Default to dark as per screenshot preference
  };

  final Map<String, String> flagMapping = {
    'India': '🇮🇳',
    'United States': '🇺🇸',
    'United Kingdom': '🇬🇧',
    'Canada': '🇨🇦',
    'Australia': '🇦🇺',
    'Brazil': '🇧🇷',
    'Japan': '🇯🇵',
    'Germany': '🇩🇪',
    'France': '🇫🇷',
    'China': '🇨🇳',
    'Russia': '🇷🇺',
    'Italy': '🇮🇹',
    'Spain': '🇪🇸',
    'Pakistan': '🇵🇰',
    'Bangladesh': '🇧🇩',
  };

  @override
  void initState() {
    countries =
        CountryData().countryList.map((c) => c['name'] as String).toList();
    filteredCountries = countries;

    // Get current theme from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = context.read<ThemeProvider>();
      setState(() {
        userdata['theme'] = themeProvider.theme;
      });
    });

    super.initState();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCountries = countries;
      } else {
        filteredCountries =
            countries
                .where((c) => c.toLowerCase().contains(query.toLowerCase()))
                .toList();
      }
    });
  }

  void validateNext() async {
    if (index == 0) {
      if (nameController.text.trim().isEmpty) {
        showSnack('Please enter your name');
        return;
      }
      setState(() {
        userdata['name'] = nameController.text.trim();
        index++;
      });
    } else if (index == 1) {
      if (userdata['country'].toString().isEmpty) {
        showSnack('Please select your country');
        return;
      }
      setState(() {
        index++;
      });
    } else if (index == 2) {
      final themeProvider = context.read<ThemeProvider>();

      await AppStatusManager.instance.updateStatus(
        AppStatus(
          theme: userdata['theme'] == AppThemeMode.dark ? 'dark' : 'light',
          accentColor: themeProvider.accentColor.value,
          isFirstTimeUser: false,
          isLoggedIn: true,
        ),
      );

      await UserModelManager.instance.updateUser(
        UserModel(username: userdata['name'], country: userdata['country']),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeProvider>().accentColor;

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
                  SizedBox(width: 8),
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
                child: IndexedStack(
                  index: index,
                  children: [
                    _buildNameStep(accentColor),
                    _buildCountryStep(accentColor),
                    _buildThemeStep(accentColor),
                  ],
                ),
              ),

              // Footer
              Column(
                children: [
                  // Step Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              i == index
                                  ? accentColor
                                  : customColors().textSecondary.withOpacity(
                                    0.3,
                                  ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Step ${index + 1} of 3",
                    style: TextStyle(
                      color: customColors().textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Button
                  GestureDetector(
                    onTap: validateNext,
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
                          Text(
                            index == 0 ? "Continue" : "Next",
                            style: TextStyle(
                              color: customColors().buttonTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
        Container(
          decoration: BoxDecoration(
            color: customColors().borderColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: nameController,
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
            onSubmitted: (_) => validateNext(),
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
        Container(
          decoration: BoxDecoration(
            color: customColors().borderColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: countrySearchController,
            onChanged: _filterCountries,
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
        Expanded(
          child: ListView.separated(
            itemCount: filteredCountries.length,
            separatorBuilder:
                (context, index) =>
                    Divider(color: customColors().borderColor, height: 1),
            itemBuilder: (context, index) {
              final country = filteredCountries[index];
              final isSelected = userdata['country'] == country;
              final flag = flagMapping[country] ?? '🏳️';

              return ListTile(
                onTap: () {
                  setState(() {
                    userdata['country'] = country;
                  });
                },
                contentPadding: EdgeInsets.zero,
                leading: Text(flag, style: const TextStyle(fontSize: 24)),
                title: Text(
                  country,
                  style: TextStyle(
                    color:
                        isSelected
                            ? customColors().textPrimary
                            : customColors().textSecondary,
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing:
                    isSelected ? Icon(Icons.check, color: accentColor) : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemeStep(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader("Choose your theme", "Pick the app theme you prefer."),

        _buildThemeCard(
          "Light",
          Icons.wb_sunny_outlined,
          AppThemeMode.light,
          accentColor,
        ),
        const SizedBox(height: 16),
        _buildThemeCard(
          "Dark",
          Icons.dark_mode_outlined,
          AppThemeMode.dark,
          accentColor,
        ),
      ],
    );
  }

  Widget _buildThemeCard(
    String label,
    IconData icon,
    AppThemeMode mode,
    Color accentColor,
  ) {
    final isSelected = userdata['theme'] == mode;
    final themeProvider = context.read<ThemeProvider>();

    return GestureDetector(
      onTap: () {
        setState(() {
          userdata['theme'] = mode;
        });
        themeProvider.setTheme(mode);
      },
      child: Container(
        height: 80,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color:
              mode == AppThemeMode.light
                  ? lightTheme.background
                  : darkTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : customColors().borderColor,
            width: 2,
          ),
          boxShadow:
              isSelected && mode == AppThemeMode.dark
                  ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  mode == AppThemeMode.light
                      ? lightTheme.textPrimary
                      : darkTheme.textPrimary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color:
                    mode == AppThemeMode.light
                        ? lightTheme.textPrimary
                        : darkTheme.textPrimary,
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
