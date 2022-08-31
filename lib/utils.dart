import 'package:quick_notify/quick_notify.dart';
import 'package:permission_handler/permission_handler.dart';

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
