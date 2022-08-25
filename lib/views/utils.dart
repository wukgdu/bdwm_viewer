import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fwfh_selectable_text/fwfh_selectable_text.dart';

class MyWidgetFactory extends WidgetFactory with SelectableTextFactory {

  @override
  SelectionChangedCallback? get selectableTextOnChanged => (selection, cause) {
    // do something when the selection changes
  };

}

HtmlWidget renderHtml(String htmlStr) {
  return HtmlWidget(
    // htmlStr.replaceAll("<br/>", ""),
    htmlStr,
    factoryBuilder: () => MyWidgetFactory(),
    onErrorBuilder: (context, element, error) => Text('$element error: $error'),
    onTapImage: (p0) { },
    onTapUrl: (p0) { return true; },
    customStylesBuilder: (element) {
      if (element.localName == 'p') {
        return {'margin-top': '0px', 'margin-bottom': '0px'};
      }
      return null;
    },
    customWidgetBuilder: (element) {
      if (element.classes.contains('quotehead') || element.classes.contains('blockquote')) {
        return Row(
          children: [
            const Icon(
              Icons.format_quote,
              size: 14,
              color: Color(0xffA6DDE3),
            ),
            Flexible(
              child: Text(
                element.text,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          ],
        );
      }
      return null;
    },
  );
}

Future<String?> showAlertDialog(BuildContext context, String title, String content, {Widget? actions1, Widget? actions2}) {

  // set up the buttons
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      if (actions1 != null) ...[actions1],
      if (actions2 != null) ...[actions2],
    ],
  );

  // show the dialog
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
