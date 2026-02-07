import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:locami/bindings/main_bindings.dart';
import 'package:locami/navigation/main_nav.dart';
import 'package:locami/theme/app_theme.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ThemeProvider.instance.setMatchWithSystem(true);

  runApp(
    ChangeNotifierProvider.value(
      value: ThemeProvider.instance,
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: MainBindings(),
      theme: materialLightTheme,
      darkTheme: materialDarkTheme,

      themeMode:
          themeProvider.isMatchWithSystem
              ? ThemeMode.system
              : (themeProvider.theme == AppThemeMode.dark
                  ? ThemeMode.dark
                  : ThemeMode.light),

      home: const MainNav(),
    );
  }
}
