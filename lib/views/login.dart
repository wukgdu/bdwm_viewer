import 'package:flutter/material.dart';

import '../bdwm/login.dart';
import '../globalvars.dart';
import './utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    // if (widget.changeTitle != null) {
    //   widget.changeTitle!("登录");
    // }
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
                icon: Icon(Icons.account_box_rounded),
                hintText: '用户名',
              ),
              controller: usernameValue,
            ),
            TextFormField(
              decoration: const InputDecoration(
                icon: Icon(Icons.password_rounded),
                hintText: '密码',
              ),
              obscureText: true,
              controller: passwordValue,
            ),
            const SizedBox(height: 24,),
            ElevatedButton(
              onPressed: () {
                var username = usernameValue.text.trim();
                var password = passwordValue.text.trim();
                // var res = await bdwmLogin(username, password);
                bdwmLogin(username, password).then((res) {
                  bool success = res.success;
                  String title = "登录遇到问题";
                  String content = "";
                  if (success == false) {
                    switch (res.error) {
                      case 4:
                        content = "您输入的用户名不存在"; break;
                      case 5:
                        content = "您输入的密码有误，请重新输入"; break;
                      default:
                        content = "其他错误发生，错误码 ${res.error}";
                    }
                    showAlertDialog(
                      context, title, Text(content),
                      actions1: TextButton(
                        child: const Text("知道了"),
                        onPressed: () { Navigator.pop(context, 'OK'); },
                      ),
                    );
                  } else {
                    debugPrint(globalUInfo.gist());
                    Navigator.of(context).pushReplacementNamed('/me');
                  }
                });
              },
              child: const Text("登录"),
            ),
          ],
        ),
      ),
    );
  }
}