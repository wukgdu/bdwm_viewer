import 'package:flutter/material.dart';

import '../globalvars.dart';
import '../views/user.dart';
import '../views/drawer.dart';

class UserApp extends StatelessWidget {
  final String uid;
  final bool? needBack;
  const UserApp({Key? key, required this.uid, this.needBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var title = "用户";
    if ((globalUInfo.uid == uid) && (globalUInfo.login == true)) {
      title = "我";
    } else if (uid == "22776") {
      title = "大秘宝";
    }
    return Scaffold(
      drawer: ((needBack == null) || (needBack == false)) ? const MyDrawer(selectedIdx: 3,) : null,
      appBar: AppBar(
        title: Text(title),
      ),
      body: UserInfoPage(uid: uid),
    );
  }
}