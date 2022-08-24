import 'package:flutter/material.dart';

import '../views/login.dart';
import '../views/drawer.dart';

class LoginApp extends StatefulWidget {
  bool? needBack = false; 
  LoginApp({Key? key, this.needBack}) : super(key: key);

  @override
  State<LoginApp> createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: ((widget.needBack == null) || (widget.needBack == false)) ? MyDrawer() : null,
      appBar: AppBar(
        title: Text("登录"),
      ),
      body: LoginPage(),
    );
  }
}