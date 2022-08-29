import 'package:flutter/material.dart';

import '../views/login.dart';
// import '../views/drawer.dart';

class LoginApp extends StatelessWidget {
  final bool? needBack; 
  const LoginApp({Key? key, this.needBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // drawer: ((needBack == null) || (needBack == false)) ? const MyDrawer(selectedIdx: 1,) : null,
      appBar: AppBar(
        title: const Text("登录"),
      ),
      body: const LoginPage(),
    );
  }
}