import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:locami/core/model/user_model.dart';
import 'package:locami/dbManager/app-status_manager.dart';
import 'package:locami/core/dataset/country_list.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/dbManager/userModel_manager.dart';

import 'package:locami/theme/them_provider.dart';
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
    'theme': AppThemeMode.dark,
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

  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    final countryList = CountryData().countryList.map((c) => c['name'] as String).toList();
    countries.assignAll(countryList);
    filteredCountries.assignAll(countryList);

    userdata['theme'] = ThemeProvider.instance.theme;
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
          countries.where((c) => c.toLowerCase().contains(query.toLowerCase())).toList(),
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
          theme: userdata['theme'] == AppThemeMode.dark ? 'dark' : 'light',
          accentColor: themeProvider.accentColor.value,
          isFirstTimeUser: false,
          isLoggedIn: true,
        ),
      );

      await UserModelManager.instance.updateUser(
        UserModel(username: userdata['name'] as String, country: userdata['country'] as String),
      );

      Get.offAll(() => const HomeView(), binding: HomeBinding());
    }
  }

  void selectCountry(String country) {
    userdata['country'] = country;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void setTheme(AppThemeMode mode) {
    userdata['theme'] = mode;
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
