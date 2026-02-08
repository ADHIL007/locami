import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:locami/app-status/app-status.dart';
import 'package:locami/core/dataset/country_list.dart';
import 'package:locami/theme/app_text_style.dart';
import 'package:locami/theme/them_provider.dart';

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

  Map<String, dynamic> userdata = {
    'name': '',
    'country': '',
    'theme': AppThemeMode.light,
  };

  @override
  void initState() {
    countries =
        CountryData().countryList.map((c) => c['name'] as String).toList();
    super.initState();
  }

  void validateNext() {
    if (index == 0 && nameController.text.trim().isNotEmpty) {
      setState(() {
        index++;
        userdata['name'] = nameController.text.trim();
      });
    } else if (index == 1 && countryController.text.trim().isNotEmpty) {
      setState(() {
        index++;
        userdata['country'] = countryController.text.trim();
      });
    }
  }

  List<Widget> get pages => [
    inputName('Your name please?'),
    inputCountry(),
    inputTheme(),
  ];

  @override
  Widget build(BuildContext context) {
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
                    style: AppTextStyles.body.copyWith(
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
            if (index < 2)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: validateNext,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      customColors().buttonColor,
                    ),
                  ),
                  child: Text(
                    "Next",
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
              return countries
                  .where((c) => c.toLowerCase().contains(pattern.toLowerCase()))
                  .toList();
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
              // Sync internal controller with external state
              typeAheadController.text = countryController.text;
              if (typeAheadController.text != countryController.text) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  typeAheadController.text = countryController.text;
                });
              }

              return TextField(
                controller: typeAheadController,
                focusNode: focusNode,
                textAlign: TextAlign.center,
                style: AppTextStyles.question.copyWith(
                  color: customColors().textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Which country are you in?',
                  hintStyle: AppTextStyles.question.copyWith(
                    color: customColors().textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.public,
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
                  // Update the main controller when user types
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

  Widget inputTheme() {
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
                        ? const BorderSide(color: Colors.lightBlue, width: 2)
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
                        ? const BorderSide(color: Colors.lightBlue, width: 2)
                        : BorderSide.none,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
