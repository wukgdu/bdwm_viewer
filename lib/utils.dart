import 'dart:async';
import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';
import 'package:extended_image/extended_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:characters/characters.dart';

bool isAndroid() {
  return Platform.isAndroid;
}

String? getCollectionPathFromHttp(String httpPath) {
  var path = getQueryValue(httpPath, 'path');
  if (path == null) {
    return null;
  }
  path = path.replaceAll('%2F', '/');
  return path;
}

String genSavePathByTime({required String srcType}) {
  // .png, .jpg
  var curTime = DateTime.now().toIso8601String().replaceAll(":", "_");
  curTime = curTime.split(".").first; // 秒
  var name = "OBViewer-$curTime$srcType";
  return name;
}

class TextAndLink {
  String text = "";
  String? link;

  TextAndLink(this.text, this.link);
  TextAndLink.empty();

  String gist() {
    return "$text[${link??''}]";
  }
}

Future<bool> checkAndRequestStoragePermission() async {
  // https://github.com/Baseflow/flutter-permission-handler/issues/907
  bool couldDoIt = true;
  var p = Permission.storage;
  if (Platform.isWindows) {
    couldDoIt = await checkAndRequestPermission(p);
  } else if (Platform.isAndroid) {
    bool pStorage = true;
    bool pVideos = true;
    bool pPhotos = true;
    bool pAudio = true;

    // Only check for storage < Android 13
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      pVideos = await checkAndRequestPermission(Permission.videos);
      pPhotos = await checkAndRequestPermission(Permission.photos);
      pAudio = await checkAndRequestPermission(Permission.audio);
    } else {
      pStorage = await checkAndRequestPermission(p);
    }
    couldDoIt = pStorage & pVideos & pPhotos & pAudio;
  }
  return couldDoIt;
}

Future<bool> checkAndRequestPermission(Permission p) async {
  // https://developer.android.com/guide/topics/ui/notifiers/notification-permission?hl=zh-cn
  var couldDoIt = true;
  var hasIt = await p.isGranted;
  if (!hasIt) {
    var status = await p.request();
    if (!status.isGranted) {
      couldDoIt = false;
    }
  }
  return couldDoIt;
}

void clearAllExtendedImageCache({bool? really=false}) {
  if (really==false) { return; }
  // print("clear all");
  clearMemoryImageCache();
  // Future.delayed(Duration.zero, () => clearDiskCachedImages());
  scheduleMicrotask(clearDiskCachedImages);
}

void clearOneExtendedImageCache(String src, {bool? memory=true, bool? local=true, bool? really=false}) async {
  if (really==false) { return; }
  if (memory == true) {
    clearMemoryImageCache(src);
  }
  if (local == true) {
    var f = await getCachedImageFile(src);
    if (f!=null && f.existsSync()) {
      var res = await clearDiskCachedImage(src);
      if (res == false) {
      }
    }
  }
}

String? getQueryValue(String link, String name) {
  var p1 = link.indexOf(name);
  if (p1==-1) { return null; }
  var p2 = link.indexOf("&", p1);
  return link.substring(p1+name.length+1, p2==-1?null:p2);
}

var stopPattern = RegExp(r'&|\s|#');

String? getQueryValueImproved(String link, String name) {
  var p1 = link.indexOf(name);
  if (p1==-1) { return null; }
  int p2 = -1;
  for (var i = p1+name.length+1; i<link.length; i+=1) {
    if ((link[i].contains(stopPattern))) {
      p2 = i;
      break;
    }
  }
  return link.substring(p1+name.length+1, p2==-1?null:p2);
}

int termStringLength(String str, {int sp=255}) {
  int length = 0;
  for (var cu in str.runes) {
    length += cu > sp ? 2 : 1;
  }
  return length;
}

String breakLongText(String s) {
  return s.characters.join("\u200B");
}

bool isIP(String str) {
  var values = str.split(".");
  if (values.length == 4) {
    for (int i=0; i<4; i+=1) {
      var d = int.tryParse(values[i]);
      if (d == null) { return false; }
      if (d<0 || d>255) { return false; }
    }
    return true;
  }
  return false;
}

bool isValidUserName(String userName, {bool whenEmpty=false}) {
  if (userName.isEmpty) { return whenEmpty; }
  var matchRes = RegExp(r"[a-zA-Z_]+").stringMatch(userName);
  if (matchRes == null) { return false; }
  return matchRes.length == userName.length;
}
