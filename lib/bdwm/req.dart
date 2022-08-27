import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../globalvars.dart';
import '../utils.dart';

class BdwmClient {
  final http.Client client = http.Client();

  void checkStatus(String cookie) {
    if (globalUInfo.login) {
      // debugPrint(cookie);
      globalUInfo.checkAndLogout(cookie);
      if (globalUInfo.login == false) {
        quickNotify("OBViewer", "登录已失效");
      }
    }
  }

  Future<http.Response> post(String url, {Map<String, String> headers=const {}, Object data=const <String, String>{}}) async {
    debugPrint("post");
    var resp = await client.post(Uri.parse(url), body: data, headers: headers);
    checkStatus(resp.headers['set-cookie'] ?? "");
    return resp;
  }

  Future<http.Response> get(String url, {Map<String, String> headers=const {}}) async {
    debugPrint("get");
    var resp =  await client.get(Uri.parse(url), headers: headers);
    checkStatus(resp.headers['set-cookie'] ?? "");
    return resp;
  }
}

var bdwmClient = BdwmClient();
