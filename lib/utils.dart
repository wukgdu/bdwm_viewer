import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:quick_notify/quick_notify.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:extended_image/extended_image.dart';

class TextAndLink {
  String text = "";
  String? link;

  TextAndLink(this.text, this.link);
  TextAndLink.empty();

  String gist() {
    return "$text[${link??''}]";
  }
}

Future<bool> checkAndRequestPermission(Permission p) async {
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

void updateOBViewerBadgeCount(int count) async {
  // if (Platform.isAndroid || Platform.isMacOS || Platform.isIOS) {
  if (Platform.isAndroid) {
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      FlutterAppBadger.updateBadgeCount(count);
    }
  }
}

void removeOBViewerBadge() async {
  if (Platform.isAndroid) {
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      FlutterAppBadger.removeBadge();
    }
  }
}

void quickNotify(String title, String content) async {
  var couldNotify = await checkAndRequestPermission(Permission.notification);
  if (couldNotify == false) {
    return;
  }
  QuickNotify.notify(
    title: title,
    content: content,
  );
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

int termStringLength(String str) {
  int length = 0;
  for (var cu in str.codeUnits) {
    length += cu > 255 ? 2 : 1;
  }
  return length;
}
