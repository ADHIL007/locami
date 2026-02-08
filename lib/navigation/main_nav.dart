import 'package:flutter/material.dart';
import 'package:locami/core/model/appstatus_model.dart';
import 'package:locami/screens/home.dart';
import 'package:locami/screens/initial_home.dart';

class MainNav extends StatefulWidget {
  const MainNav({Key? key}) : super(key: key);

  @override
  _MainNavState createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  bool isFirstTimeUser = true;
  @override
  void initState() {
    isFirstTimeUser = AppStatus().isFirstTimeUser;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return isFirstTimeUser ? InitialHome() : Home();
  }
}
