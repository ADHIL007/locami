import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:locami/dbManager/app-status_manager.dart';
import 'package:locami/bindings/main_bindings.dart';
import 'package:locami/navigation/main_nav.dart';
import 'package:locami/theme/app_theme.dart';
import 'package:locami/theme/them_provider.dart';
import 'package:provider/provider.dart';
import 'package:locami/core/utils/background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:locami/screens/alarm_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

  final appStatus = await AppStatusManager.instance.status;

  ThemeProvider.instance.applyFromStatus(appStatus);

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
    FlutterBackgroundService().on('locationReached').listen((event) {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        Get.to(() => const AlarmScreen());
      }
    });
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

      home: Scaffold(
        backgroundColor: customColors().background,
        body: SafeArea(child: Center(child: MainNav())),
      ),
    );
  }
}
