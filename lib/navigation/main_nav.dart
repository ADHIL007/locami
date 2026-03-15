import 'package:flutter/material.dart';
import 'package:locami/dbManager/app_status_manager.dart';
import 'package:locami/modules/home/bindings/home_binding.dart';
import 'package:locami/modules/home/views/home_view.dart';
import 'package:locami/modules/initial/bindings/initial_home_binding.dart';
import 'package:locami/modules/initial/views/initial_home_view.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  bool? isFirstTimeUser;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await AppStatusManager.instance.status;
    setState(() {
      isFirstTimeUser = status.isFirstTimeUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstTimeUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isFirstTimeUser!) {
      // Use Get.put if we are embedding it in MainNav, or GetView if we navigate
      // Since it's inside Scaffold in main.dart, we can use Get.put manually or use a wrapper
      return const InitialHomeWrapper();
    } else {
      return const HomeWrapper();
    }
  }
}

class InitialHomeWrapper extends StatelessWidget {
  const InitialHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    InitialHomeBinding().dependencies();
    return const InitialHomeView();
  }
}

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    HomeBinding().dependencies();
    return const HomeView();
  }
}
