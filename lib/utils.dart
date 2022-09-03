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