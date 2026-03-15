import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:locami/core/model/user_model.dart';
import 'package:locami/db_manager/app_status_manager.dart';
import 'package:locami/core/dataset/country_list.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/db_manager/user_model_manager.dart';

import 'package:locami/theme/theme_provider.dart';
import 'package:locami/modules/home/views/home_view.dart';
import 'package:locami/modules/home/bindings/home_binding.dart';

class InitialHomeController extends GetxController {
  final index = 0.obs;
  final nameController = TextEditingController();
  final countrySearchController = TextEditingController();

  final countries = <String>[].obs;
  final filteredCountries = <String>[].obs;
  final userdata = {
    'name': '',
    'country': '',
    'theme': 'system', // Default to system
  }.obs;

  final flagMapping = {
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

  final isLocating = false.obs;

  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    final countryList =
        CountryData().countryList.map((c) => c['name'] as String).toList();
    countries.assignAll(countryList);
    filteredCountries.assignAll(countryList);

    userdata['theme'] = ThemeProvider.instance.isMatchWithSystem ? 'system' : (ThemeProvider.instance.theme == AppThemeMode.dark ? 'dark' : 'light');
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    nameController.dispose();
    countrySearchController.dispose();
    super.onClose();
  }

  void filterCountries(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        filteredCountries.assignAll(countries);
      } else {
        filteredCountries.assignAll(
          countries
              .where((c) => c.toLowerCase().contains(query.toLowerCase()))
              .toList(),
        );
      }
    });
  }

  Future<void> validateNext() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index.value == 0) {
      if (nameController.text.trim().isEmpty) {
        showSnack('Please enter your name');
        return;
      }
      userdata['name'] = nameController.text.trim();
      index.value++;
    } else if (index.value == 1) {
      if (userdata['country'].toString().isEmpty) {
        showSnack('Please select your country');
        return;
      }
      index.value++;
    } else if (index.value == 2) {
      final themeProvider = ThemeProvider.instance;

      await AppStatusManager.instance.updateStatus(
        AppStatus(
          theme: userdata['theme'].toString(),
          accentColor: themeProvider.accentColor.toARGB32(),
          isFirstTimeUser: false,
          isLoggedIn: true,
        ),
      );

      await UserModelManager.instance.updateUser(
        UserModel(
          username: userdata['name'] as String,
          country: userdata['country'] as String,
        ),
      );

      Get.offAll(() => const HomeView(), binding: HomeBinding());
    }
  }

  void selectCountry(String country) {
    userdata['country'] = country;
    userdata.refresh(); // Ensure UI updates
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> autoLocateCountry() async {
    isLocating.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showSnack('Location services are disabled.');
        isLocating.value = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showSnack('Location permissions are denied');
          isLocating.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showSnack('Location permissions are permanently denied');
        isLocating.value = false;
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        String? detectedCountry = placemarks.first.country;
        if (detectedCountry != null) {
          // Try to find the closest match in our list
          String? matchedCountry = countries.firstWhereOrNull(
            (c) => c.toLowerCase() == detectedCountry.toLowerCase(),
          );

          if (matchedCountry != null) {
            // Filter the search bar to show ONLY the detected country so it's clearly visible
            countrySearchController.text = matchedCountry;
            filteredCountries.assignAll([matchedCountry]);

            selectCountry(matchedCountry);
            //  showSnack('Located: $matchedCountry');
          } else {
            showSnack('Country $detectedCountry not found in list');
          }
        }
      }
    } catch (e) {
      showSnack('Error locating country: $e');
    } finally {
      isLocating.value = false;
    }
  }

  void setThemeToSystem() {
    userdata['theme'] = 'system';
    ThemeProvider.instance.setMatchWithSystem(true);
  }

  void setTheme(AppThemeMode mode) {
    userdata['theme'] = mode == AppThemeMode.dark ? 'dark' : 'light';
    ThemeProvider.instance.setTheme(mode);
  }

  void showSnack(String message) {
    Get.snackbar(
      'Notice',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black54,
      colorText: Colors.white,
    );
  }
}
