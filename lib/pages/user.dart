import 'package:flutter/material.dart';

import '../globalvars.dart';
import '../views/user.dart';
import '../views/drawer.dart';

class UserApp extends StatefulWidget {
  String uid;
  bool? needBack;
  UserApp({Key? key, required this.uid, this.needBack}) : super(key: key);

  @override
  State<UserApp> createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  @override
  Widget build(BuildContext context) {
    var title = "用户";
    if ((globalUInfo.uid == widget.uid) && (globalUInfo.login == true)) {
      title = "我";
    } else if (widget.uid == "22776") {
      title = "大秘宝";
    }
    return Scaffold(
      drawer: ((widget.needBack == null) || (widget.needBack == false)) ? MyDrawer() : null,
      appBar: AppBar(
        title: Text(title),
      ),
      body: UserInfoPage(uid: widget.uid),
    );
  }
}