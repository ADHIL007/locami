import 'package:flutter/material.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/dbManager/app-status_manager.dart';
import 'package:locami/screens/home.dart';
import 'package:locami/screens/initial_home.dart';

class MainNav extends StatefulWidget {
  const MainNav({Key? key}) : super(key: key);

  @override
  _MainNavState createState() => _MainNavState();
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

    return isFirstTimeUser! ? const InitialHome() : const Home();
  }
}
