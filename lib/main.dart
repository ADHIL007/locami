import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:locami/db_manager/app_status_manager.dart';
import 'package:locami/bindings/main_bindings.dart';
import 'package:locami/navigation/main_nav.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:locami/core/utils/background_service.dart';

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
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: MainBindings(),
      theme: themeProvider.themeData,
      darkTheme: themeProvider.themeData,
      themeMode: (themeProvider.theme == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light),
      home: Scaffold(
        backgroundColor: customColors().background,
        body: SafeArea(child: Center(child: MainNav())),
      ),
    );
  }
}
