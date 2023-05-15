import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../globalvars.dart';
import '../notification.dart' show sendNotification;

class BdwmClient {
  final http.Client client = http.Client();

  Future<void> checkStatus(String cookie, {required String reqUid, required String userName}) async {
    if (reqUid != guestUitem.uid) {
      // debugPrint(cookie);
      var res = await globalUInfo.checkAndLogout(cookie, reqUid: reqUid);
      if (res == true) {
        sendNotification("OBViewer", "$userName（$reqUid）登录已失效", payload: "/login");
        debugPrint("$userName（$reqUid）登录已失效");
      }
    }
  }

  Future<http.Response?> post(String url, {Map<String, String> headers=const {}, Object data=const <String, String>{}}) async {
    debugPrint("post");
    var reqUid = globalUInfo.uid;
    var userName = globalUInfo.username;
    var timeout = false;
    try {
      var resp = await client.post(Uri.parse(url), body: data, headers: headers)
        .timeout(const Duration(seconds: 10));
      await checkStatus(resp.headers['set-cookie'] ?? "", reqUid: reqUid, userName: userName);
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
    var userName = globalUInfo.username;
    var timeout = false;
    try {
      var resp =  await client.get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 10));
      await checkStatus(resp.headers['set-cookie'] ?? "", reqUid: reqUid, userName: userName);
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
