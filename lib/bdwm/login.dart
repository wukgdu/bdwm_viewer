import 'dart:convert';

import 'package:crypto/crypto.dart';

import './req.dart';
import '../globalvars.dart';

String genMD5(String s) {
  var content = const Utf8Encoder().convert(s);
  return md5.convert(content).toString();
}

Map<String, String> genLoginInfo(String username, String password) {
  var now = DateTime.now();
  var timestamp = now.millisecondsSinceEpoch ~/ 1000;
  var s = genMD5("$password$username$timestamp$password");
  var data = {
    "username": username,
    "password": password,
    'keepalive': '1',
    'time': timestamp.toString(),
    't': s,
  };
  return data;
}

class LoginRes {
  bool success = false;
  int error = 0;
  String? desc;

  LoginRes(this.success, this.error);
  LoginRes.error({
    required this.success,
    required this.error,
    required this.desc,
  });
}

Future<LoginRes> bdwmLogin(String username, String password) async {
  var loginUrl = "$v2Host/ajax/login.php";
  var data = genLoginInfo(username, password);
  var resp = await bdwmClient.post(loginUrl, headers: <String, String>{}, data: data);
  if (resp == null) {
    return LoginRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var status = json.decode(resp.body);
  if (!status['success']) {
    return LoginRes(false, status['error']);
  }
  List<String> res = parseCookie(resp.headers['set-cookie'] ?? "");
  if (res.isNotEmpty) {
    globalUInfo.setInfo(res[1], res[0], username);
  }
  return LoginRes(true, 0);
}
