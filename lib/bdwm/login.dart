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

Future<bool> bdwmLogin(String username, String password) async {
  var loginUrl = "$v2Host/ajax/login.php";
  var data = genLoginInfo(username, password);
  var resp = await bdwmClient.post(loginUrl, headers: <String, String>{}, data: data);
  var status = json.decode(resp.body);
  if (!status['success']) {
    return false;
  }
  List<String> res = parseCookie(resp.headers['set-cookie'] ?? "");
  if (res.isNotEmpty) {
    globalUInfo.setInfo(res[1], res[0], username);
  }
  return true;
}
