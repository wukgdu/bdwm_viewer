import 'package:flutter/material.dart';

import '../bdwm/login.dart' show bdwmLogin;
import '../router.dart' show nv2PushAndRemoveAll;
import '../globalvars.dart' show globalUInfo;
import '../services_instance.dart';
import './utils.dart' show showInformDialog;
import './multi_users.dart' show SwitchUsersComponent;

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  void initState() {
    super.initState();
    // if (widget.changeTitle != null) {
    //   widget.changeTitle!("登录");
    // }
  }

  @override
  void dispose() {
    usernameValue.dispose();
    passwordValue.dispose();
    super.dispose();
  }

  TextEditingController usernameValue = TextEditingController();
  TextEditingController passwordValue = TextEditingController();
  bool hidePassword = true;

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
              autocorrect: false,
            ),
            TextFormField(
              decoration: InputDecoration(
                icon: const Icon(Icons.password_rounded),
                hintText: '密码',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                  icon: hidePassword
                  ? const Icon(Icons.remove_red_eye_outlined)
                  : const Icon(Icons.lock),
                ),
              ),
              obscureText: hidePassword,
              controller: passwordValue,
              autocorrect: false,
            ),
            const SizedBox(height: 24,),
            ElevatedButton(
              onPressed: () {
                var username = usernameValue.text.trim();
                if (username.isEmpty) {
                  showInformDialog(context, "登录", "用户名不能为空");
                  return;
                }
                var password = passwordValue.text.trim();
                if (password.isEmpty) {
                  showInformDialog(context, "登录", "密码不能为空");
                  return;
                }
                // var res = await bdwmLogin(username, password);
                bdwmLogin(username, password).then((res) {
                  bool success = res.success;
                  String title = "登录遇到问题";
                  String content = "";
                  if (success == false) {
                    switch (res.error) {
                      case -1:
                        content = res.desc!; break;
                      case 4:
                        content = "您输入的用户名不存在"; break;
                      case 5:
                        content = "您输入的密码有误，请重新输入"; break;
                      default:
                        content = res.desc ?? "其他错误发生，错误码 ${res.error}";
                    }
                    showInformDialog(context, title, content);
                  } else {
                    debugPrint(globalUInfo.gist());
                    unreadMail.clearAll();
                    unreadMessage.clearAll();
                    nv2PushAndRemoveAll(context, '/home');
                  }
                });
              },
              child: const Text("登录"),
            ),
            const SizedBox(height: 15,),
            const SwitchUsersComponent(showLogin: false,),
          ],
        ),
      ),
    );
  }
}