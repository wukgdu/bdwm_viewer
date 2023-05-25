import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../globalvars.dart';
import '../notification.dart' show sendNotification;

class BdwmClient {
  final http.Client client = http.Client();

  Future<void> checkStatus(String cookie, {required String reqUid, required String reqSkey, required String userName}) async {
    if (reqUid != guestUitem.uid) {
      // debugPrint(cookie);
      var res = await globalUInfo.checkAndLogout(cookie, reqUid: reqUid, reqSkey: reqSkey);
      if (res == true) {
        sendNotification("OBViewer", "$userName（$reqUid）登录已失效", payload: "/login");
        debugPrint("$userName（$reqUid）登录已失效");
      }
    }
  }

  Future<http.Response?> post(String url, {Map<String, String> headers=const {}, Object data=const <String, String>{}, Duration timeout=const Duration(seconds: 15)}) async {
    debugPrint("post");
    var reqUid = globalUInfo.uid;
    var reqSkey = globalUInfo.skey;
    var userName = globalUInfo.username;
    var isTimeout = false;
    try {
      var resp = await client.post(Uri.parse(url), body: data, headers: headers)
        .timeout(timeout);
      await checkStatus(resp.headers['set-cookie'] ?? "", reqUid: reqUid, userName: userName, reqSkey: reqSkey);
      return resp;
    } on TimeoutException catch (_) {
      isTimeout = true;
    } on SocketException catch (_) {
      isTimeout = true;
    } on HttpException catch (_) {
      isTimeout = true;
    } on Exception catch (_) {
      isTimeout = true;
    } catch (e) {
      isTimeout = true;
    }
    if (isTimeout) {
      return null;
    }
    return null;
  }

  Future<http.Response?> get(String url, {Map<String, String> headers=const {}, Duration timeout=const Duration(seconds: 15)}) async {
    debugPrint("get");
    var reqUid = globalUInfo.uid;
    var reqSkey = globalUInfo.skey;
    var userName = globalUInfo.username;
    var isTimeout = false;
    try {
      var resp =  await client.get(Uri.parse(url), headers: headers)
        .timeout(timeout);
      await checkStatus(resp.headers['set-cookie'] ?? "", reqUid: reqUid, userName: userName, reqSkey: reqSkey);
      return resp;
    } on TimeoutException catch (_) {
      isTimeout = true;
    } on SocketException catch (_) {
      isTimeout = true;
    } on HttpException catch (_) {
      isTimeout = true;
    } on Exception catch (_) {
      isTimeout = true;
    } catch (e) {
      isTimeout = true;
    }
    if (isTimeout) {
      return null;
    }
    return null;
  }
}

var bdwmClient = BdwmClient();
