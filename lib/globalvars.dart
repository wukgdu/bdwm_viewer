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
  String username = "guest";
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
    await unreadMail.reInitWorker();
    await unreadMessage.reInitWorker();
    login = true;
    await update();
  }

  Future<bool> init() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$storage";
    // debugPrint(filename);
    Future<void> writeInit() async {
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
      await file.flush();
      await file.close();
    }
    if (File(filename).existsSync()) {
      var content = File(filename).readAsStringSync();
      if (content.isEmpty) {
        await writeInit();
      } else {
        var jsonContent = jsonDecode(content);
        uid = jsonContent['users'][0]['uid'];
        skey = jsonContent['users'][0]['skey'];
        username = jsonContent['users'][0]['name'];
        login = jsonContent['users'][0]['login'];
      }
    } else {
      await writeInit();
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
    await file.flush();
    await file.close();
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
    Future<void> writeInit() async {
      var file = File(filename).openWrite();
      file.write(jsonEncode([]));
      await file.flush();
      await file.close();
    }
    if (File(filename).existsSync()) {
      var content = File(filename).readAsStringSync();
      if (content.isEmpty) {
        await writeInit();
      } else {
        List jsonContent = jsonDecode(content);
        contact.addAll(jsonContent.map((e) => e as String));
      }
    } else {
      await writeInit();
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
    await file.flush();
    await file.close();
    return true;
  }
}

var globalContactInfo = TmpContactInfo.empty();

class BDWMConfig {
  String lastCheckTime = "";
  String lastLoginTime = "";
  bool showWelcome = true;
  bool useImgInMessage = true;
  bool autoClearImageCache = false;
  bool extraThread = false;
  double contentFontSize = 16.0;
  String maxPageNum = "8";
  bool showBadge = true;
  Set<String> seeNoThem = {};
  String storage = "bdwmconfig.json";

  Lock lock = Lock();

  BDWMConfig.empty();
  BDWMConfig.initFromFile() {
    init();
  }

  Map toJson() {
    return {
      "showWelcome": showWelcome,
      "useImgInMessage": useImgInMessage,
      "lastLoginTime": lastLoginTime,
      "lastCheckTime": lastCheckTime,
      "seeNoThem": seeNoThem.toList(),
      "autoClearImageCache": autoClearImageCache,
      "maxPageNum": maxPageNum,
      "extraThread": extraThread,
      "contentFontSize": contentFontSize,
      "showBadge": showBadge,
    };
  }
  void fromJson(Map<String, dynamic> jsonContent) {
    showWelcome = jsonContent['showWelcome'] ?? true;
    useImgInMessage = jsonContent['useImgInMessage'] ?? true;
    autoClearImageCache = jsonContent['autoClearImageCache'] ?? false;
    extraThread = jsonContent['extraThread'] ?? false;
    showBadge = jsonContent['showBadge'] ?? true;
    lastLoginTime = jsonContent['lastLoginTime'] ?? "";
    lastCheckTime = jsonContent['lastCheckTime'] ?? "";
    maxPageNum = jsonContent['maxPageNum'] ?? "8";
    contentFontSize = jsonContent['contentFontSize'] ?? 16.0;
    List seeNoHimHerList = jsonContent['seeNoThem'] ?? <String>[];
    seeNoThem = Set<String>.from(seeNoHimHerList.map((e) => e as String));
  }
  String gist() {
    return jsonEncode(toJson());
  }

  double getContentFontSize() {
    return contentFontSize;
  }

  Future<bool> setContentFontSize(double newValue) async {
    return await lock.synchronized(() async {
      contentFontSize = newValue;
      return await update();
    });
  }

  bool getShowBadge() {
    return showBadge;
  }

  Future<bool> setShowBadge(bool newValue) async {
    return await lock.synchronized(() async {
      showBadge = newValue;
      return await update();
    });
  }

  bool getExtraThread() {
    return extraThread;
  }

  Future<bool> setExtraThread(bool newValue) async {
    return await lock.synchronized(() async {
      extraThread = newValue;
      return await update();
    });
  }

  bool getAutoClearImageCache() {
    return autoClearImageCache;
  }

  Future<bool> setAutoClearImageCache(bool newValue) async {
    return await lock.synchronized(() async {
      autoClearImageCache = newValue;
      return await update();
    });
  }

  bool getUseImgInMessage() {
    return useImgInMessage;
  }

  Future<bool> setUseImgInMessage(bool newValue) async {
    return await lock.synchronized(() async {
      useImgInMessage = newValue;
      return await update();
    });
  }

  bool getShowWelcome() {
    return showWelcome;
  }

  Future<bool> setShowWelcome(bool newValue) async {
    return await lock.synchronized(() async {
      showWelcome = newValue;
      return await update();
    });
  }

  String getMaxPageNum() {
    return maxPageNum;
  }

  Future<bool> setMaxPageNum(String newTime) async {
    return await lock.synchronized(() async {
      maxPageNum = newTime;
      return await update();
    });
  }

  String getLastCheckTime() {
    return lastCheckTime;
  }

  Future<bool> setLastCheckTime(String newTime) async {
    return await lock.synchronized(() async {
      lastCheckTime = newTime;
      return await update();
    });
  }

  String getLastLoginTime() {
    return lastLoginTime;
  }

  Future<bool> setLastLoginTime(String newTime) async {
    return await lock.synchronized(() async {
      lastLoginTime = newTime;
      return await update();
    });
  }

  Set<String> getSeeNoThem() {
    return seeNoThem;
  }

  Future<bool> addOneSeeNo(String userName) async {
    return await lock.synchronized(() async {
      seeNoThem.add(userName);
      return await update();
    });
  }

  Future<bool> removeOneSeeNo(String userName) async {
    return await lock.synchronized(() async {
      seeNoThem.remove(userName);
      return await update();
    });
  }

  Future<bool> init() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$storage";
    // debugPrint(filename);
    Future<void> writeInit() async {
      var file = File(filename).openWrite();
      file.write(jsonEncode(toJson()));
      await file.flush();
      await file.close();
    }
    if (File(filename).existsSync()) {
      var content = File(filename).readAsStringSync();
      if (content.isEmpty) {
        await writeInit();
      } else {
        Map<String, dynamic> jsonContent = jsonDecode(content);
        fromJson(jsonContent);
      }
    } else {
      await writeInit();
    }
    return true;
  }

  Future<bool> update() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$storage";
    var file = File(filename).openWrite();
    file.write(jsonEncode(toJson()));
    await file.flush();
    await file.close();
    return true;
  }
}

var globalConfigInfo = BDWMConfig.empty();
