import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../globalvars.dart';
import '../notification.dart' show sendNotification;

class BdwmClient {
  final http.Client client = http.Client();

  Future<void> checkStatus(String cookie, {required String reqUid}) async {
    if (globalUInfo.login) {
      // debugPrint(cookie);
      await globalUInfo.checkAndLogout(cookie, reqUid: reqUid);
      if (globalUInfo.login == false) {
        sendNotification("OBViewer", "该$accountChinese登录已失效", payload: "/login");
        debugPrint("该$accountChinese登录已失效");
      }
    }
  }

  Future<http.Response?> post(String url, {Map<String, String> headers=const {}, Object data=const <String, String>{}}) async {
    debugPrint("post");
    var reqUid = globalUInfo.uid;
    var timeout = false;
    try {
      var resp = await client.post(Uri.parse(url), body: data, headers: headers)
        .timeout(const Duration(seconds: 10));
      await checkStatus(resp.headers['set-cookie'] ?? "", reqUid: reqUid);
      return resp;
    } on TimeoutException catch (_) {
      timeout = true;
    } on SocketException catch (_) {
      timeout = true;
    } on HttpException catch (_) {
      timeout = true;
    } on Exception catch (_) {
      timeout = true;
    } catch (e) {
      timeout = true;
    }
    if (timeout) {
      return null;
    }
    return null;
  }

  Future<http.Response?> get(String url, {Map<String, String> headers=const {}}) async {
    debugPrint("get");
    var reqUid = globalUInfo.uid;
    var timeout = false;
    try {
      var resp =  await client.get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 10));
      await checkStatus(resp.headers['set-cookie'] ?? "", reqUid: reqUid);
      return resp;
    } on TimeoutException catch (_) {
      timeout = true;
    } on SocketException catch (_) {
      timeout = true;
    } on HttpException catch (_) {
      timeout = true;
    } on Exception catch (_) {
      timeout = true;
    } catch (e) {
      timeout = true;
    }
    if (timeout) {
      return null;
    }
    return null;
  }
}

var bdwmClient = BdwmClient();
