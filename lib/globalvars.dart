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

const simFont = "SimSun, monospace, roboto, serif";
const notoSansMonoCJKscFont= "Noto Sans Mono CJK SC";
const avaiFonts = [simFont, notoSansMonoCJKscFont];

const accountChinese = "账号";

Future<String> genAppFilename(String name) async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = "$dir/$name";
    return filename;
}

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

class Uitem {
  String skey;
  String uid;
  String username;
  bool login;
  Uitem({
    required this.skey,
    required this.uid,
    required this.username,
    required this.login,
  });
  Map<String, Object> toMap() {
    return {
      "name": username,
      "skey": skey,
      "uid": uid,
      "login": login,
    };
  }
  String briefInfo() {
    return "$username ($uid)";
  }
  String info() {
    return "$username ($uid): $skey $login";
  }
}

enum CheckUserStat {
  ok, full, exist, logout,
}

final guestUitem = Uitem(
  skey: "43ba4d206559d3a9",
  uid: "15265",
  username: "guest",
  login: false,
);

class Uinfo {
  String storage = "bdwmusers.json";
  int primary = -1;
  List<Uitem> users = [];

  String get username {
    if (primary == -1) { return guestUitem.username; }
    return users[primary].username;
  }
  String get skey {
    if (primary == -1) { return guestUitem.skey; }
    return users[primary].skey;
  }
  String get uid {
    if (primary == -1) { return guestUitem.uid; }
    return users[primary].uid;
  }
  bool get login {
    if (primary == -1) { return guestUitem.login; }
    return users[primary].login;
  }

  Future<void> doAfterChangeUser() async {
    unreadMail.clearAll();
    unreadMessage.clearAll();
    await unreadMail.reInitWorker();
    await unreadMessage.reInitWorker();
    await update();
  }

  Future<bool> switchByUsername(String username) async {
    for (var i=0; i<users.length; i+=1) {
      if (users[i].username == username) {
        primary = i;
        await doAfterChangeUser();
        return true;
      }
    }
    if (username == guestUitem.username) {
      primary = -1;
      await doAfterChangeUser();
      return true;
    }
    return false;
  }

  Future<bool> switchByUid(String uid) async {
    for (var i=0; i<users.length; i+=1) {
      if (users[i].uid == uid) {
        primary = i;
        await doAfterChangeUser();
        return true;
      }
    }
    if (uid == guestUitem.uid) {
      primary = -1;
      await doAfterChangeUser();
      return true;
    }
    return false;
  }

  bool containsGuest() {
    for (var i=0; i<users.length; i+=1) {
      if (users[i].username == guestUitem.username) {
        return true;
      }
    }
    return false;
  }

  bool isFull() {
    return users.length >= 3;
  }

  Uinfo({required String skey, required String uid, required String username});
  Uinfo.empty();
  // Uinfo.initFromFile() {
  //   init();
  // }

  String gist() {
    return "$username($uid): $skey ${login == true? 'online' : 'offline'}";
  }

  CheckUserStat checkUserCanLogin(String username) {
    if (isFull()) { return CheckUserStat.full; }
    for (var i=0; i<users.length; i+=1) {
      if (users[i].username == username) {
        if (users[i].login) {
          return CheckUserStat.exist;
        }
        return CheckUserStat.logout;
      }
    }
    return CheckUserStat.ok;
  }

  Future<void> addUser(String skey, String uid, String username) async {
    users.removeWhere((element) => element.uid == guestUitem.uid);
    var curUser = Uitem(skey: skey, uid: uid, username: username, login: true);
    users.add(curUser);
    primary = users.length - 1;
    await doAfterChangeUser();
  }

  void updatePrimary(String curUid, String curSkey) {
    primary = -1;
    for (var i=0; i<users.length; i+=1) {
      if ((users[i].uid == curUid) && ((users[i].skey == curSkey) || (users[i].uid == guestUitem.uid))) {
        primary = i;
        break;
      }
    }
  }

  Future<void> removeUser(String uid, String skey, {bool save=false, bool force=false, bool updateP=false}) async {
    if ((force==false) && (uid == this.uid)) { return; }
    var curUid = this.uid;
    var curSkey = this.skey;
    users.removeWhere((element) => (element.uid == uid) && ((uid==guestUitem.uid) || (element.skey == skey)));
    if (updateP) { updatePrimary(curUid, curSkey); }
    if (save) {
      if ((uid == curUid) && (skey == curSkey)) {
        await doAfterChangeUser();
      } else {
        await update();
      }
    }
  }

  Future<void> writeInit(String filename) async {
    var file = File(filename).openWrite();
    Map<String, Object> content = <String, Object>{
      "users": [],
      "primary": -1
    };
    file.write(jsonEncode(content));
    await file.flush();
    await file.close();
  }

  Future<bool> init({bool useGuest=false}) async {
    String filename = await genAppFilename(storage);
    // debugPrint(filename);
    if (File(filename).existsSync()) {
      var content = File(filename).readAsStringSync();
      if (content.isEmpty) {
        await writeInit(filename);
      } else {
        var jsonContent = jsonDecode(content);
        for (var u in jsonContent['users']) {
          var uid0 = u['uid'] as String;
          var skey0 = u['skey'] as String;
          var username0 = u['name'] as String;
          var login0 = u['login'] as bool;
          users.add(Uitem(skey: skey0, uid: uid0, username: username0, login: login0));
        }
        if (useGuest) {
          primary = -1;
        } else {
          primary = jsonContent['primary'] as int;
        }
      }
    } else {
      await writeInit(filename);
    }
    return true;
  }

  Future<void> update() async {
    String filename = await genAppFilename(storage);
    var file = File(filename).openWrite();
    Map<String, Object> content = <String, Object>{
      "users": users.map((e) => e.toMap()).toList(),
      "primary": primary,
    };
    file.write(jsonEncode(content));
    await file.flush();
    await file.close();
  }

  Future<bool> checkAndLogout(cookie, {required String reqUid, required String reqSkey}) async {
    if (reqUid == guestUitem.uid) {
      return false;
    }
    List<String> res = parseCookie(cookie);
    if (res.isEmpty) {
      return false;
    }
    String newUid = res[0];
    String newSkey = res[1];
    if (newUid != reqUid) {
      if (newUid == guestUitem.uid) {
        await setLogout(uid: reqUid, skey: reqSkey);
        return true;
      }
    } else if (newSkey != reqSkey) {
      for (var i=0; i<users.length; i+=1) {
        if ((users[i].uid == reqUid) && (users[i].skey == reqSkey)) {
          users[i].skey = newSkey;
          users[i].login = true;
          await doAfterChangeUser();
          break;
        }
      }
    }
    return false;
  }

  Future<void> setLogout({String? uid, String? skey}) async {
    var curUid = this.uid;
    var curSkey = this.skey;
    var rUid = uid ?? curUid, rSkey = skey ?? curSkey;
    await removeUser(rUid, rSkey, save: true, force: true, updateP: true);
    // await removeUser(rUid, rSkey, save: false, force: true, updateP: false);
    // updatePrimary(curUid, curSkey);
    // if ((rUid == curUid) && (rSkey == curSkey)) {
    //   await doAfterChangeUser();
    // } else {
    //   await update();
    // }
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

Map<String, String> genHeaders2({String? skey, String? uid}) {
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
    "cookie": "mode=topic; mode=topic; ; favorite_mode=list; favorite_mode=list; skey=${skey ?? globalUInfo.skey}; uid=${uid ?? globalUInfo.uid}",
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

  void memInsertOne(String userName) {
    var clist = globalContactInfo.contact.toList();
    clist.insert(0, userName);
    globalContactInfo.contact = clist.toSet();
  }

  void memInsertMany(List<String> userNames) {
    var clist = globalContactInfo.contact.toList();
    globalContactInfo.contact = (userNames + clist).toSet();
  }

  Future<Set<String>> getData() async {
    return await lock.synchronized(() async {
      return contact;
    });
  }

  Future<bool> addOne(String userName) async {
    return await lock.synchronized(() async {
      memInsertOne(userName);
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
    String filename = await genAppFilename(storage);
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

  Future<bool> update({bool order=true}) async {
    String filename = await genAppFilename(storage);
    var file = File(filename).openWrite();
    var contactList = contact.toList();
    if (order) {
      contactList.sort();
    }
    file.write(jsonEncode(contactList));
    await file.flush();
    await file.close();
    return true;
  }
}

var globalContactInfo = TmpContactInfo.empty();

class BDWMNotConfig {
  // 程序自动修改的设置
  String lastCheckTime = "";
  String lastLoginTime = "";

  Lock lock = Lock();
  String storage = "bdwmnotconfig.json";

  BDWMNotConfig.empty();
  BDWMNotConfig.initFromFile() {
    init();
  }

  Map toJson() {
    return {
      "lastLoginTime": lastLoginTime,
      "lastCheckTime": lastCheckTime,
    };
  }
  void fromJson(Map<String, dynamic> jsonContent) {
    lastLoginTime = jsonContent['lastLoginTime'] ?? "";
    lastCheckTime = jsonContent['lastCheckTime'] ?? "";
  }
  String gist() {
    return jsonEncode(toJson());
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

  Future<bool> init() async {
    String filename = await genAppFilename(storage);
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
    String filename = await genAppFilename(storage);
    var file = File(filename).openWrite();
    file.write(jsonEncode(toJson()));
    await file.flush();
    await file.close();
    return true;
  }
}

var globalNotConfigInfo = BDWMNotConfig.empty();

class BDWMImmConfig {
  // 修改后自动保存的设置
  String _boardNoteFont = simFont;
  bool _showAttachLink = true;
  Set<String> _seeNoThem = {};
  Map<String, String> _qmd = {};

  Lock lock = Lock();
  String storage = "bdwmimmconfig.json";

  BDWMImmConfig.empty();
  BDWMImmConfig.initFromFile() {
    init();
  }

  Map toJson() {
    return {
      "boardNoteFont": _boardNoteFont,
      "seeNoThem": _seeNoThem.toList(),
      "qmd": _qmd,
      "showAttachLink": _showAttachLink,
    };
  }
  void fromJson(Map<String, dynamic> jsonContent) {
    _boardNoteFont = jsonContent['boardNoteFont'] ?? _boardNoteFont;
    _showAttachLink = jsonContent['showAttachLink'] ?? _showAttachLink;
    List seeNoHimHerList = jsonContent['seeNoThem'] ?? _seeNoThem.toList();
    _seeNoThem = Set<String>.from(seeNoHimHerList.map((e) => e as String));
    var savedQmd = jsonContent['qmd'] ?? _qmd;
    _qmd = (savedQmd as Map<String, dynamic>).cast<String, String>();
  }
  String gist() {
    return jsonEncode(toJson());
  }

  bool getShowAttachLink() {
    return _showAttachLink;
  }

  Future<bool> setShowAttachLink(bool newValue) async {
    return await lock.synchronized(() async {
      _showAttachLink = newValue;
      return await update();
    });
  }

  String getQmd() {
    return _qmd[globalUInfo.uid] ?? "";
  }

  Future<bool> setQmd(String newValue) async {
    return await lock.synchronized(() async {
      var curUid = globalUInfo.uid;
      _qmd[curUid] = newValue;
      return await update();
    });
  }

  String getBoardNoteFont() {
    return _boardNoteFont;
  }

  Future<bool> setBoardNoteFont(String newValue) async {
    return await lock.synchronized(() async {
      _boardNoteFont = newValue;
      return await update();
    });
  }

  Set<String> getSeeNoThem() {
    return _seeNoThem;
  }

  Future<bool> addOneSeeNo(String userName) async {
    return await lock.synchronized(() async {
      _seeNoThem.add(userName);
      return await update();
    });
  }

  Future<bool> removeOneSeeNo(String userName) async {
    return await lock.synchronized(() async {
      _seeNoThem.remove(userName);
      return await update();
    });
  }

  Future<bool> init() async {
    String filename = await genAppFilename(storage);
    // debugPrint(filename);
    Future<void> writeInit() async {
      // 1.9.2 修改了设置文件，读取之前的设置
      _seeNoThem.addAll(globalConfigInfo.seeNoThem);
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
    String filename = await genAppFilename(storage);
    var file = File(filename).openWrite();
    file.write(jsonEncode(toJson()));
    await file.flush();
    await file.close();
    return true;
  }
}

var globalImmConfigInfo = BDWMImmConfig.empty();

class BDWMConfig {
  // 可以临时修改的设置，需要手动保存
  bool showWelcome = true;
  bool useImgInMessage = true;
  bool autoClearImageCache = false;
  bool extraThread = false;
  bool highQualityPreview = true;
  bool suggestUser = true;
  bool showFAB = true;
  bool useMD3 = true;
  bool useDynamicColor = false;
  String refreshRate = "high";
  bool autoHideBottomBar = true;
  bool guestFirst = false;
  String primaryColorString = "";
  double contentFontSize = 16.0;
  String maxPageNum = "8";
  bool autoSaveConfig = false;
  bool showDetailInCard = false;
  bool savePostHistory = true;
  Set<String> seeNoThem = {};

  Lock lock = Lock();
  String storage = "bdwmconfig.json";

  BDWMConfig.empty();
  BDWMConfig.initFromFile() {
    init();
  }

  Map toJson() {
    return {
      "showWelcome": showWelcome,
      "useImgInMessage": useImgInMessage,
      // "seeNoThem": seeNoThem.toList(),
      "autoClearImageCache_1": autoClearImageCache,
      "maxPageNum": maxPageNum,
      "extraThread": extraThread,
      "contentFontSize": contentFontSize,
      "highQualityPreview_1": highQualityPreview,
      "primaryColorString": primaryColorString,
      "suggestUser": suggestUser,
      "showFAB": showFAB,
      "useMD3_1": useMD3,
      "useDynamicColor": useDynamicColor,
      "autoHideBottomBar": autoHideBottomBar,
      "refreshRate": refreshRate,
      "guestFirst": guestFirst,
      "autoSaveConfig": autoSaveConfig,
      "showDetailInCard": showDetailInCard,
      "savePostHistory": savePostHistory,
    };
  }
  void fromJson(Map<String, dynamic> jsonContent) {
    showWelcome = jsonContent['showWelcome'] ?? showWelcome;
    useImgInMessage = jsonContent['useImgInMessage'] ?? useImgInMessage;
    autoClearImageCache = jsonContent['autoClearImageCache_1'] ?? autoClearImageCache;
    extraThread = jsonContent['extraThread'] ?? extraThread;
    highQualityPreview = jsonContent['highQualityPreview_1'] ?? highQualityPreview;
    suggestUser = jsonContent['suggestUser'] ?? suggestUser;
    showFAB = jsonContent['showFAB'] ?? showFAB;
    maxPageNum = jsonContent['maxPageNum'] ?? maxPageNum;
    contentFontSize = jsonContent['contentFontSize'] ?? contentFontSize;
    primaryColorString = jsonContent['primaryColorString'] ?? primaryColorString;
    refreshRate = jsonContent['refreshRate'] ?? refreshRate;
    useMD3 = jsonContent['useMD3_1'] ?? useMD3;
    autoSaveConfig = jsonContent['autoSaveConfig'] ?? autoSaveConfig;
    guestFirst = jsonContent['guestFirst'] ?? guestFirst;
    useDynamicColor = jsonContent['useDynamicColor'] ?? useDynamicColor;
    autoHideBottomBar = jsonContent['autoHideBottomBar'] ?? autoHideBottomBar;
    showDetailInCard = jsonContent['showDetailInCard'] ?? showDetailInCard;
    savePostHistory = jsonContent['savePostHistory'] ?? savePostHistory;
    List seeNoHimHerList = jsonContent['seeNoThem'] ?? seeNoThem.toList();
    seeNoThem = Set<String>.from(seeNoHimHerList.map((e) => e as String));
  }
  String gist() {
    return jsonEncode(toJson());
  }

  bool getSavePostHistory() {
    return savePostHistory;
  }

  Future<bool> setSavePostHistory(bool newValue) async {
    return await lock.synchronized(() async {
      savePostHistory = newValue;
      return await update();
    });
  }

  bool getShowDetailInCard() {
    return showDetailInCard;
  }

  Future<bool> setShowDetailInCard(bool newValue) async {
    return await lock.synchronized(() async {
      showDetailInCard = newValue;
      return await update();
    });
  }

  bool getAutoSaveConfig() {
    return autoSaveConfig;
  }

  Future<bool> setAutoSaveConfig(bool newValue) async {
    return await lock.synchronized(() async {
      autoSaveConfig = newValue;
      return await update();
    });
  }

  bool getGuestFirst() {
    return guestFirst;
  }

  Future<bool> setGuestFirst(bool newValue) async {
    return await lock.synchronized(() async {
      guestFirst = newValue;
      return await update();
    });
  }

  String getRefreshRate() {
    return refreshRate;
  }

  Future<bool> setRefreshRate(String newValue) async {
    return await lock.synchronized(() async {
      refreshRate = newValue;
      return await update();
    });
  }

  bool getAutoHideBottomBar() {
    return autoHideBottomBar;
  }

  Future<bool> setAutoHideBottomBar(bool newValue) async {
    return await lock.synchronized(() async {
      autoHideBottomBar = newValue;
      return await update();
    });
  }

  bool getUseDynamicColor() {
    return useDynamicColor;
  }

  Future<bool> setUseDynamicColor(bool newValue) async {
    return await lock.synchronized(() async {
      useDynamicColor = newValue;
      return await update();
    });
  }

  bool getUseMD3() {
    return useMD3;
  }

  Future<bool> setUseMD3(bool newValue) async {
    return await lock.synchronized(() async {
      useMD3 = newValue;
      return await update();
    });
  }

  String getPrimaryColorString() {
    return primaryColorString;
  }

  Future<bool> setPrimaryColorString(String newValue) async {
    return await lock.synchronized(() async {
      primaryColorString = newValue;
      return await update();
    });
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

  bool getShowFAB() {
    return showFAB;
  }

  Future<bool> setShowFAB(bool newValue) async {
    return await lock.synchronized(() async {
      showFAB = newValue;
      return await update();
    });
  }

  bool getSuggestUser() {
    return suggestUser;
  }

  Future<bool> setSuggestUser(bool newValue) async {
    return await lock.synchronized(() async {
      suggestUser = newValue;
      return await update();
    });
  }

  bool getHighQualityPreview() {
    return highQualityPreview;
  }

  Future<bool> setHighQualityPreview(bool newValue) async {
    return await lock.synchronized(() async {
      highQualityPreview = newValue;
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

  Future<bool> init() async {
    String filename = await genAppFilename(storage);
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
    String filename = await genAppFilename(storage);
    var file = File(filename).openWrite();
    file.write(jsonEncode(toJson()));
    await file.flush();
    await file.close();
    return true;
  }
}

var globalConfigInfo = BDWMConfig.empty();

class RecentThreadItemInfo {
  String link = "";
  String title = "";
  String userName = "";
  String boardName = "";
  int timestamp = 0;

  RecentThreadItemInfo({
    required this.link,
    required this.title,
    required this.userName,
    required this.boardName,
    required this.timestamp,
  });
  RecentThreadItemInfo.fromJson(Map jsonObject) {
    fromJson(jsonObject);
  }
  Map toJson() {
    return {
      'link': link,
      'title': title,
      'userName': userName,
      'boardName': boardName,
      'timestamp': timestamp,
    };
  }
  void fromJson(Map jsonObject) {
    link = jsonObject['link'] ?? "";
    title = jsonObject['title'] ?? "";
    userName = jsonObject['userName'] ?? "";
    boardName = jsonObject['boardName'] ?? "";
    timestamp = jsonObject['timestamp'] ?? 0;
  }
}

class RecentThreadInfo {
  int get maxCount => 200;
  List<RecentThreadItemInfo> items = [];
  int get count => items.length;
  String get storage => "bdwmhistory.json";

  RecentThreadInfo({required this.items});
  RecentThreadInfo.empty();
  RecentThreadInfo.initFromFile() {
    init();
  }

  List toJson() {
    return items;
  }

  void fromJson(List jsonList) {
    items.clear();
    for (var jo in jsonList) {
      var jm = jo as Map;
      items.add(RecentThreadItemInfo.fromJson(jm));
    }
  }

  Future<bool> addOne({required String link, required String title, required String userName, required String boardName, required int timestamp}) async {
    items.removeWhere((element) => element.link == link);
    if (count >= maxCount) {
      items.removeAt(0);
    }
    items.add(RecentThreadItemInfo(link: link, title: title, userName: userName, boardName: boardName, timestamp: timestamp));
    await update();
    return true;
  }

  Future<bool> removeOne(String link) async {
    items.removeWhere((element) => element.link == link);
    await update();
    return true;
  }

  Future<bool> removeAll() async {
    items.clear();
    await update();
    return true;
  }

  Future<bool> init() async {
    String filename = await genAppFilename(storage);
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
        List jsonContent = jsonDecode(content);
        fromJson(jsonContent);
      }
    } else {
      await writeInit();
    }
    return true;
  }

  Future<bool> update() async {
    String filename = await genAppFilename(storage);
    var file = File(filename).openWrite();
    file.write(jsonEncode(toJson()));
    await file.flush();
    await file.close();
    return true;
  }
}

var globalThreadHistory = RecentThreadInfo.empty();

class MarkedThreadInfo extends RecentThreadInfo {
  @override
  int get maxCount => 400;
  @override
  String get storage => "bdwmmarked.json";
  MarkedThreadInfo({required super.items});
  MarkedThreadInfo.empty() : super.empty();

  bool contains(String link) {
    for (var i in items) {
      if (i.link == link) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<bool> addOne({required String link, required String title, required String userName, required String boardName, required int timestamp}) async {
    if (count >= maxCount) {
      return false;
    }
    items.add(RecentThreadItemInfo(link: link, title: title, userName: userName, boardName: boardName, timestamp: timestamp));
    await update();
    return true;
  }
}

var globalMarkedThread = MarkedThreadInfo.empty();

class PostHistoryData extends RecentThreadInfo {
  @override
  int get maxCount => 400;
  @override
  String get storage => "bdwmposthistory.json";
  PostHistoryData({required super.items});
  PostHistoryData.empty() : super.empty();

  @override
  Future<bool> addOne({required String link, required String title, required String userName, required String boardName, required int timestamp}) async {
    if (count >= maxCount) {
      // do nothing, save all history
      // return false;
    }
    items.add(RecentThreadItemInfo(link: link, title: title, userName: userName, boardName: boardName, timestamp: timestamp));
    await update();
    return true;
  }
}

var globalPostHistoryData = PostHistoryData.empty();
