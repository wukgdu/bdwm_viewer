import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
// import 'package:fwfh_selectable_text/fwfh_selectable_text.dart';

import '../pages/detail_image.dart';

// https://github.com/daohoangson/flutter_widget_from_html/tree/master/packages/fwfh_selectable_text
mixin SelectableTextFactory on WidgetFactory {
  /// Controls whether text is rendered with [SelectableText] or [RichText].
  ///
  /// Default: `true`.
  bool get selectableText => true;

  /// The callback when user changes the selection of text.
  ///
  /// See [SelectableText.onSelectionChanged].
  SelectionChangedCallback? get selectableTextOnChanged => null;

  @override
  Widget? buildText(BuildMetadata meta, TextStyleHtml tsh, InlineSpan text) {
    if (selectableText &&
        meta.overflow == TextOverflow.clip &&
        text is TextSpan) {
      return SelectableText.rich(
        text,
        maxLines: meta.maxLines > 0 ? meta.maxLines : null,
        textAlign: tsh.textAlign ?? TextAlign.start,
        textDirection: tsh.textDirection,
        textScaleFactor: 1.0,
        onSelectionChanged: selectableTextOnChanged,
        cursorWidth: 0,
      );
    }

    return super.buildText(meta, tsh, text);
  }
}

class MyWidgetFactory extends WidgetFactory with SelectableTextFactory {

  @override
  SelectionChangedCallback? get selectableTextOnChanged => (selection, cause) {
    // do something when the selection changes
  };

}

HtmlWidget renderHtml(String htmlStr, {bool? needSelect = true, TextStyle? ts, BuildContext? context}) {
  return HtmlWidget(
    // htmlStr.replaceAll("<br/>", ""),
    htmlStr,
    factoryBuilder: (needSelect == null || needSelect == false) ? null :  () => MyWidgetFactory(),
    onErrorBuilder: (context, element, error) => Text('$element error: $error'),
    textStyle: ts,
    onTapImage: (p0) {
      if (context == null) { return; }
      gotoDetailImage(context: context, link: p0.sources.first.url, name: p0.title);
    },
    onTapUrl: (p0) {
      return true;
    },
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
