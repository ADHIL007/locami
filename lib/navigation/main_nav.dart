import 'package:flutter/material.dart';
import 'package:locami/db_manager/app_status_manager.dart';
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
    if (status.isFirstTimeUser) {
      InitialHomeBinding().dependencies();
    } else {
      HomeBinding().dependencies();
    }
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
      return const InitialHomeView();
    } else {
      return const HomeView();
    }
  }
}
