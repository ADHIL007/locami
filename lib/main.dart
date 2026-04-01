import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:locami/core/utils/performance_service.dart';
import 'package:locami/db_manager/app_status_manager.dart';
import 'package:locami/bindings/main_bindings.dart';
import 'package:locami/modules/home/views/home_view.dart';
import 'package:locami/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:locami/core/localization/app_translations.dart';
import 'package:locami/core/utils/map_cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar / navigation bar globally
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // MapCacheManager must init before runApp since map renders immediately
  await MapCacheManager.instance.init();

  // Only load lightweight settings before runApp — defer heavy I/O
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
    // Start monitoring performance to auto-adjust GPU load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceService.instance.startMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[MAIN] MainApp.build called');
    // Re-apply on every rebuild to ensure it stays dark
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    final themeProvider = context.watch<ThemeProvider>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: MainBindings(),
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      theme: themeProvider.themeData,
      darkTheme: themeProvider.themeData,
      themeMode:
          (themeProvider.theme == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light),
      home: const HomeView(),
    );
  }
}
