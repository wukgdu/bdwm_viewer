import 'package:bdwm_viewer/globalvars.dart';
import 'package:flutter/material.dart';

import '../bdwm/login.dart';

class LoginPage extends StatefulWidget {
  PageCallBack? pageCallBack;
  NameCallBack? changeTitle;
  LoginPage({Key? key, this.pageCallBack, this.changeTitle}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    if (widget.changeTitle != null) {
      widget.changeTitle!("登录");
    }
  }
  TextEditingController usernameValue = TextEditingController();
  TextEditingController passwordValue = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                hintText: '用户名',
              ),
              controller: usernameValue,
            ),
            TextFormField(
              decoration: const InputDecoration(
                hintText: '密码',
              ),
              obscureText: true,
              controller: passwordValue,
            ),
            const SizedBox(height: 24,),
            ElevatedButton(
              onPressed: () async {
                var username = usernameValue.text.trim();
                var password = passwordValue.text.trim();
                var res = await bdwmLogin(username, password);
                if (res == false) {
                } else {
                  debugPrint(globalUInfo.gist());
                  if (widget.pageCallBack != null) {
                    widget.pageCallBack!();
                  }
                }
              },
              child: const Text("登录"),
            ),
          ],
        ),
      ),
    );
  }
}