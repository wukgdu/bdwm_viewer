import 'dart:convert';
import 'dart:io';

// import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import './services_instance.dart';

const bbsHost = "https://bbs.pku.edu.cn";
const v2Host = "https://bbs.pku.edu.cn/v2";
// const bbsHost = "";
// const v2Host = "";
const defaultAvator = "/v2/images/user/portrait-neu.png";
const networkErrorText = "网络问题，请稍后重试";

List<String> parseCookie(String cookie) {
  var pattern1 = "skey=";
  var pattern2 = "uid=";
  var pos1 = cookie.lastIndexOf(pattern1);
  if (pos1 == -1) {
    return <String>[];
  }
  var pos2 = cookie.lastIndexOf(pattern2);
  var pos1sc = cookie.indexOf(";", pos1);
  var pos2sc = cookie.indexOf(";", pos2);
  var skey = cookie.substring(pos1+5, pos1sc);
  var uid = cookie.substring(pos2+4, pos2sc);
  return <String>[uid, skey];
}

class Uinfo {
  String skey = "a946e957f047df88";
  String uid = "15265";
  String username = "";
  bool login = false;
  String storage = "bdwmusers.json";

  Uinfo({required this.skey, required this.uid, required this.username});
  Uinfo.empty();
  Uinfo.initFromFile() {
    init();
  }

  String gist() {
    return "$username($uid): $skey ${login == true? 'online' : 'offline'}";
  }

  Future<void> setInfo(String skey, String uid, String username) async {
    this.skey = skey;
    this.uid = uid;
    this.username = username;
    login = true;
    await update();
    await unreadMail.reInitWorker();
    await unreadMessage.reInitWorker();
  }

  Future<bool> init() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$storage";
    // debugPrint(filename);
    void writeInit() {
      var file = File(filename).openWrite();
      Map<String, Object> content = <String, Object>{
        "users": [{
            "name": "guest",
            "skey": "a946e957f047df88",
            "uid": "15265",
            "login": false
        }],
        "primary": 0
      };
      file.write(jsonEncode(content));
      file.close();
    }
    if (File(filename).existsSync()) {
      var content = File(filename).readAsStringSync();
      if (content.isEmpty) {
        writeInit();
      } else {
        var jsonContent = jsonDecode(content);
        uid = jsonContent['users'][0]['uid'];
        skey = jsonContent['users'][0]['skey'];
        username = jsonContent['users'][0]['name'];
        login = jsonContent['users'][0]['login'];
      }
    } else {
      writeInit();
    }
    return true;
  }

  Future<void> update() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$storage";
    var content = File(filename).readAsStringSync();
    var jsonContent = jsonDecode(content);
    jsonContent['users'][0]['uid'] = uid;
    jsonContent['users'][0]['skey'] = skey;
    jsonContent['users'][0]['name'] = username;
    jsonContent['users'][0]['login'] = login;
    var file = File(filename).openWrite();
    file.write(jsonEncode(jsonContent));
    file.close();
  }

  Future<void> checkAndLogout(cookie) async {
    if (login == false) {
      return;
    }
    List<String> res = parseCookie(cookie);
    if (res.isEmpty) {
      return;
    }
    String newUid = res[0];
    String newSkey = res[1];
    if (newUid != uid) {
      uid = newUid;
      skey = newSkey;
      login = false;
      await update();
    } else if (newSkey != skey) {
      uid = newUid;
      skey = newSkey;
      login = true;
      await update();
    }
  }

  Future<void> setLogout() async {
    login = false;
    username = "guest";
    await update();
  }
}

Map<String, String> genHeaders() {
  return <String, String>{
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
    "accept-language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
    "cache-control": "max-age=0",
    "sec-ch-ua": "\"Chromium\";v=\"104\", \" Not A;Brand\";v=\"99\", \"Microsoft Edge\";v=\"104\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "document",
    "sec-fetch-mode": "navigate",
    "sec-fetch-site": "same-origin",
    "sec-fetch-user": "?1",
    "upgrade-insecure-requests": "1",
    "cookie": "mode=topic; mode=topic; favorite_mode=list; favorite_mode=list; skey=${globalUInfo.skey}; uid=${globalUInfo.uid}",
    "Referer": "https://bbs.pku.edu.cn/v2/home.php",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  };
}

Map<String, String> genHeaders2() {
  return <String, String>{
    "accept": "*/*",
    "accept-language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
    "sec-ch-ua": "\"Chromium\";v=\"104\", \" Not A;Brand\";v=\"99\", \"Microsoft Edge\";v=\"104\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest",
    "cookie": "mode=topic; mode=topic; ; favorite_mode=list; favorite_mode=list; skey=${globalUInfo.skey}; uid=${globalUInfo.uid}",
    "Referer": "https://bbs.pku.edu.cn/",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  };
}

Map<String, String> genHeadersForUpload() {
  return <String, String>{
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
    "accept-language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
    "cache-control": "max-age=0",
    "content-type": "multipart/form-data",
    "sec-ch-ua": "\"Microsoft Edge\";v=\"105\", \" Not;A Brand\";v=\"99\", \"Chromium\";v=\"105\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "iframe",
    "sec-fetch-mode": "navigate",
    "sec-fetch-site": "same-origin",
    "sec-fetch-user": "?1",
    "upgrade-insecure-requests": "1",
    "cookie": "mode=topic; mode=topic; ; favorite_mode=list; favorite_mode=list; skey=${globalUInfo.skey}; uid=${globalUInfo.uid}",
  };
}

var globalUInfo = Uinfo.empty();

class TmpContactInfo {
  Set<String> contact = {};
  String storage = "bdwmcontact.json";
  Lock lock = Lock();

  TmpContactInfo.empty();
  TmpContactInfo.initFromFile() {
    init();
  }

  String gist() {
    return contact.join(",");
  }

  Future<Set<String>> getData() async {
    return await lock.synchronized(() async {
      return contact;
    });
  }

  Future<bool> addOne(String userName) async {
    return await lock.synchronized(() async {
      contact.add(userName);
      return await update();
    });
  }

  Future<bool> addAll(Iterable<String> users) async {
    return await lock.synchronized(() async {
      contact.addAll(users);
      return await update();
    });
  }

  Future<bool> removeOne(String userName) async {
    return await lock.synchronized(() async {
      contact.remove(userName);
      return await update();
    });
  }

  Future<bool> removeAll() async {
    return await lock.synchronized(() async {
      contact.clear();
      return await update();
    });
  }

  Future<bool> init() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$storage";
    // debugPrint(filename);
    void writeInit() {
      var file = File(filename).openWrite();
      file.write(jsonEncode([]));
      file.close();
    }
    if (File(filename).existsSync()) {
      var content = File(filename).readAsStringSync();
      if (content.isEmpty) {
        writeInit();
      } else {
        List jsonContent = jsonDecode(content);
        contact.addAll(jsonContent.map((e) => e as String));
      }
    } else {
      writeInit();
    }
    return true;
  }

  Future<bool> update() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$storage";
    var file = File(filename).openWrite();
    var contactList = contact.toList();
    contactList.sort();
    file.write(jsonEncode(contactList));
    file.close();
    return true;
  }
}

var globalContactInfo = TmpContactInfo.empty();

class BDWMConfig {
  Map<String, dynamic> config = {};
  String storage = "bdwmconfig.json";
  Lock lock = Lock();

  BDWMConfig.empty();
  BDWMConfig.initFromFile() {
    init();
  }

  String gist() {
    return jsonEncode(config);
  }

  Future<Map<String, dynamic>> getData() async {
    return await lock.synchronized(() async {
      return config;
    });
  }

  Future<bool> addOne(String key, dynamic value) async {
    return await lock.synchronized(() async {
      config[key] = value;
      return await update();
    });
  }

  Future<bool> addAll(Map<String, dynamic> pairs) async {
    return await lock.synchronized(() async {
      config.addAll(pairs);
      return await update();
    });
  }

  Future<bool> init() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$storage";
    // debugPrint(filename);
    void writeInit() {
      var file = File(filename).openWrite();
      file.write(jsonEncode({}));
      file.close();
    }
    if (File(filename).existsSync()) {
      var content = File(filename).readAsStringSync();
      if (content.isEmpty) {
        writeInit();
      } else {
        Map<String, dynamic> jsonContent = jsonDecode(content);
        config.addAll(jsonContent);
      }
    } else {
      writeInit();
    }
    return true;
  }

  Future<bool> update() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$storage";
    var file = File(filename).openWrite();
    file.write(jsonEncode(config));
    file.close();
    return true;
  }
}

var globalConfigInfo = BDWMConfig.empty();
