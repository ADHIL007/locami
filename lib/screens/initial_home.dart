import 'package:flutter/material.dart';
import 'package:locami/core/model/user_model.dart';
import 'package:locami/dbManager/app-status_manager.dart';
import 'package:locami/core/dataset/country_list.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/dbManager/userModel_manager.dart';
import 'package:locami/screens/home.dart';
import 'package:locami/theme/app_text_style.dart';
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
      backgroundColor: const Color(
        0xFF0E0E0E,
      ), // Always dark for onboarding as per screenshot
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
                  const Text(
                    "Locami",
                    style: TextStyle(
                      color: Colors.white,
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
                                  : Colors.grey.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Step ${index + 1} of 3",
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.6),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Positioned(
                            right: 20,
                            child: Icon(
                              Icons.chevron_right,
                              color: Colors.white,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Name",
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.person, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: countrySearchController,
            onChanged: _filterCountries,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Search country",
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
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
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
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
                    color: isSelected ? Colors.white : Colors.grey,
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
          color: mode == AppThemeMode.light ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withOpacity(0.05),
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
                      ? Colors.grey[800]
                      : Colors.grey[400],
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: mode == AppThemeMode.light ? Colors.black : Colors.white,
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
