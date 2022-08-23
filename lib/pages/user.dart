import 'package:flutter/material.dart';

import '../views/user.dart';
import '../views/drawer.dart';

class UserApp extends StatefulWidget {
  String uid;
  UserApp({Key? key, required this.uid}) : super(key: key);

  @override
  State<UserApp> createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Text("我"),
      ),
      body: UserInfoPage(uid: widget.uid),
    );
  }
}