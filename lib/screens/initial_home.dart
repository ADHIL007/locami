import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
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
  final TextEditingController countryController = TextEditingController();
  List<String> countries = [];
  final appStatus = AppStatusManager.instance.status;
  bool isSubmitted = false;
  Map<String, dynamic> userdata = {
    'name': '',
    'country': '',
    'theme': AppThemeMode.light,
  };

  @override
  void initState() {
    countries =
        CountryData().countryList.map((c) => c['name'] as String).toList();

    final themeProvider = ThemeProvider.instance;

    userdata['theme'] = themeProvider.theme;

    super.initState();
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
      if (countryController.text.trim().isEmpty) {
        showSnack('Please select your country');
        return;
      }

      if (!countries.contains(countryController.text.trim())) {
        showSnack('Please choose a valid country from the list');
        return;
      }

      setState(() {
        userdata['country'] = countryController.text.trim();
        index++;
      });
    }
    if (index == 2) {
      await AppStatusManager.instance.updateStatus(
        AppStatus(
          theme: userdata['theme'] == AppThemeMode.dark ? 'dark' : 'light',
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

  List<Widget> get pages => [
    inputName('Your name please?'),
    inputCountry(),
    inputTheme(ThemeProvider.instance.accentColor),
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeProvider>().accentColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (index > 0)
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      index = 0;
                    });
                  },
                  child: Text(
                    'Hi ${nameController.text}!',
                    style: AppTextStyles.headline.copyWith(
                      color: customColors().textPrimary,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: double.infinity,
                minHeight: 100,
              ),
              child: IndexedStack(index: index, children: pages),
            ),
            const Spacer(),
            if (index < 3)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: validateNext,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(accentColor),
                  ),
                  child: Text(
                    index == 2 ? 'Done' : "Next",
                    style: AppTextStyles.buttonText.copyWith(
                      color: customColors().buttonTextColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget inputName(String text) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: customColors().borderColor, width: 1),
            ),
          ),
          child: TextField(
            onSubmitted: (_) => validateNext(),

            cursorColor: customColors().textPrimary,
            autofocus: true,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,

            controller: nameController,
            textAlign: TextAlign.center,
            style: AppTextStyles.question.copyWith(
              color: customColors().textPrimary,
            ),
            decoration: InputDecoration(
              hintText: text,
              hintStyle: AppTextStyles.question.copyWith(
                color: customColors().textSecondary,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget inputCountry() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: customColors().background,
            border: Border(
              bottom: BorderSide(color: customColors().borderColor, width: 1),
            ),
          ),
          child: TypeAheadField<String>(
            suggestionsCallback: (pattern) {
              if (pattern.isEmpty) return [];

              final query = pattern.toLowerCase();

              final startsWith =
                  countries
                      .where((c) => c.toLowerCase().startsWith(query))
                      .toList();

              final contains =
                  countries
                      .where(
                        (c) =>
                            !c.toLowerCase().startsWith(query) &&
                            c.toLowerCase().contains(query),
                      )
                      .toList();

              return [...startsWith, ...contains];
            },

            itemBuilder: (context, suggestion) {
              return Container(
                decoration: BoxDecoration(
                  color: customColors().background,
                  border: Border(
                    bottom: BorderSide(
                      color: customColors().borderColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Text(
                    suggestion,
                    style: AppTextStyles.body.copyWith(
                      color: customColors().textPrimary,
                    ),
                  ),
                ),
              );
            },
            onSelected: (suggestion) {
              setState(() {
                countryController.text = suggestion;
                userdata['country'] = suggestion;
              });
            },
            hideOnEmpty: true,
            builder: (context, typeAheadController, focusNode) {
              typeAheadController.text = countryController.text;
              if (typeAheadController.text != countryController.text) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  typeAheadController.text = countryController.text;
                });
              }

              if (index == 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!focusNode.hasFocus) {
                    focusNode.requestFocus();
                  }
                });
              }

              return TextField(
                autofocus: true,
                cursorColor: customColors().textPrimary,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.done,

                controller: typeAheadController,
                focusNode: focusNode,
                textAlign: TextAlign.center,
                style: AppTextStyles.question.copyWith(
                  color: customColors().textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your country ?',
                  hintStyle: AppTextStyles.question.copyWith(
                    color: customColors().textSecondary,
                  ),

                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (value) {
                  countryController.text = value;
                  userdata['country'] = value;
                },
              );
            },
            decorationBuilder: (context, child) {
              return Material(
                type: MaterialType.card,
                elevation: 4,
                borderRadius: BorderRadius.circular(4),
                color: customColors().background,
                child: child,
              );
            },
            offset: const Offset(0, 12),
            constraints: const BoxConstraints(maxHeight: 300),
          ),
        ),
      ],
    );
  }

  Widget inputTheme(Color accentColor) {
    return Column(
      children: [
        Text(
          'Choose your theme',
          style: AppTextStyles.question.copyWith(
            color: customColors().textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  userdata['theme'] = AppThemeMode.light;
                  ThemeProvider.instance.setTheme(AppThemeMode.light);
                });
              },

              icon: Icon(Icons.wb_sunny, color: Colors.orange[700]),
              label: Text(
                'Light',
                style: AppTextStyles.buttonText.copyWith(
                  color: customColors().buttonTextColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: customColors().buttonColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                side:
                    userdata['theme'] == AppThemeMode.light
                        ? BorderSide(color: accentColor, width: 2)
                        : BorderSide.none,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  userdata['theme'] = AppThemeMode.dark;
                  ThemeProvider.instance.setTheme(AppThemeMode.dark);
                });
              },

              icon: Icon(Icons.nightlight_round, color: Colors.indigo[300]),
              label: Text(
                'Dark',
                style: AppTextStyles.buttonText.copyWith(
                  color: customColors().buttonTextColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: customColors().buttonColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                side:
                    userdata['theme'] == AppThemeMode.dark
                        ? BorderSide(color: accentColor, width: 2)
                        : BorderSide.none,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
