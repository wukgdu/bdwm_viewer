import 'package:quick_notify/quick_notify.dart';

class TextAndLink {
  String text = "";
  String? link;

  TextAndLink(this.text, this.link);
  TextAndLink.empty();
}

void quickNotify(String title, String content) async {
  var hasP = await QuickNotify.hasPermission();
  if (!hasP) {
    var getP = await QuickNotify.requestPermission();
    if (!getP) {
      return;
    }
  }
  QuickNotify.notify(
    title: title,
    content: content,
  );
}
