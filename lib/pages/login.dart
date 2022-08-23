import 'package:flutter/material.dart';

import '../views/login.dart';
import '../views/drawer.dart';

class LoginApp extends StatefulWidget {
  String? boardName;
  LoginApp({Key? key, this.boardName}) : super(key: key);

  @override
  State<LoginApp> createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Text("登录"),
      ),
      body: LoginPage(),
    );
  }
}