import 'dart:async';

import 'package:quick_notify/quick_notify.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:extended_image/extended_image.dart';

class TextAndLink {
  String text = "";
  String? link;

  TextAndLink(this.text, this.link);
  TextAndLink.empty();
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

void quickNotify(String title, String content) async {
  var couldNotify = true;
  var hasP = await Permission.notification.isGranted;
  if (!hasP) {
    var status = await Permission.notification.request();
    if (!status.isGranted) {
      couldNotify = false;
    }
  }
  if (couldNotify == false) {
    return;
  }
  QuickNotify.notify(
    title: title,
    content: content,
  );
}

void clearAllExtendedImageCache() {
  // print("clear all");
  clearMemoryImageCache();
  // Future.delayed(Duration.zero, () => clearDiskCachedImages());
  scheduleMicrotask(clearDiskCachedImages);
}

void clearOneExtendedImageCache(String src, {bool? memory=true, bool? local=true}) async {
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
