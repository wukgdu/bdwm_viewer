import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
// import 'package:fwfh_selectable_text/fwfh_selectable_text.dart';

import '../pages/detail_image.dart';
import '../globalvars.dart' show networkErrorText;
import './constants.dart' show topicsLabelColor, bdwmPrimaryColor;
import '../utils.dart' show quickNotify;

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
    // buildAsync: true,
    textStyle: ts,
    onTapImage: (p0) {
      if (context == null) { return; }
      if (p0.sources.first.url.startsWith("data")) {
        return;
      }
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

Future<String?> showAlertDialog(BuildContext context, String title, Widget content, {Widget? actions1, Widget? actions2, Widget? actions3, List<Widget>? actions, bool? barrierDismissible=true}) {

  // set up the buttons
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: content,
    actions: actions ?? [
      if (actions1 != null) actions1,
      if (actions2 != null) actions2,
      if (actions3 != null) actions3,
    ],
  );

  // show the dialog
  return showDialog<String>(
    context: context,
    barrierDismissible: (barrierDismissible!=null&&barrierDismissible==false)?false:true,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Future<String?> showNetWorkDialog(BuildContext context) {
  return showAlertDialog(context, "网络错误", const Text(networkErrorText),
    actions1: TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text("知道了"),
    )
  );
}

Future<String?> showPageDialog(BuildContext context, int curPage, int maxPage) {
  TextEditingController pageValue = TextEditingController();
  Widget content() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: TextField(
          controller: pageValue,
          // decoration: InputDecoration(
          // ),
          keyboardType: const TextInputType.numberWithOptions(),
        ),
        ),
        const Text("/"),
        Text(maxPage.toString()),
      ],
    );
  }
  return showAlertDialog(
    context, "跳转", content(),
    actions1: TextButton(
      onPressed: () { Navigator.of(context).pop(); },
      child: const Text("取消"),
    ),
    actions2: TextButton(
      onPressed: () {
        if (pageValue.text.isEmpty) { return; }
        var nPage = int.tryParse(pageValue.text);
        if (nPage == null) { return; }
        if ((nPage > 0) && (nPage <= maxPage)) {
          Navigator.of(context).pop(pageValue.text);
        }
      },
      child: const Text("确认"),
    ),
  );
}

Future<String?> showTextDialog(BuildContext context, String title) {
  TextEditingController textValue = TextEditingController();
  Widget content() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: textValue,
            // decoration: InputDecoration(
            // ),
            // keyboardType: const TextInputType.numberWithOptions(),
          ),
        ),
      ],
    );
  }
  return showAlertDialog(
    context, title, content(),
    actions1: TextButton(
      onPressed: () { Navigator.of(context).pop(); },
      child: const Text("取消"),
    ),
    actions2: TextButton(
      onPressed: () {
        if (textValue.text.isEmpty) { return; }
        Navigator.of(context).pop(textValue.text);
      },
      child: const Text("确认"),
    ),
  );
}

Widget genThreadLabel(String label) {
  return Container(
    width: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      // border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
      color: topicsLabelColor[label] ?? bdwmPrimaryColor,
    ),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12,),),
  );
}

Future<bool?> showLinkMenu(BuildContext context, String link, {String? downloadPath, String? filename}) async {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Center(child: SelectableText(link),),
            const Divider(),
            ElevatedButton(
              child: const Text('下载'),
              onPressed: () async {
                Navigator.of(context).pop();
                const seconds = 60;
                var fn = filename ?? path.basename(link);
                var saveRes = await genDownloadPath(name: fn);
                if (saveRes.success == false) {
                  return;
                }
                var down = downloadPath ?? saveRes.reason;
                var timeout = false;
                var resp = await http.get(Uri.parse(link)).timeout(const Duration(seconds: seconds), onTimeout: () {
                  timeout = true;
                  return http.Response("timeout", 502); // not exact statuscode, !=200
                }).onError((error, stackTrace) {
                  return http.Response("error", 502); // not exact statuscode, !=200
                });
                if (resp.statusCode == 200) {
                  File(down).writeAsBytes(resp.bodyBytes).then((value) {
                    if (value.existsSync()) {
                      quickNotify("下载完成", down);
                    } else {
                      quickNotify("写入文件失败", down);
                    }
                  },);
                } else {
                  if (timeout) {
                    quickNotify("下载超时", "超过$seconds秒");
                  } else {
                    quickNotify("下载失败", down);
                  }
                }
              }
            ),
          ],
        ),
      );
    },
  );
}

class SaveRes {
  bool success = false;
  String reason = "";
  SaveRes(this.success, this.reason);
}

Future<SaveRes> genDownloadPath({String? name}) async {
  Directory? downloadDir;
  String? downloadPath;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      downloadDir = Directory('/storage/emulated/0/Download');
      if (!downloadDir.existsSync()) {
        var path = await FilePicker.platform.getDirectoryPath();
        if (path != null) {
          downloadDir = Directory(path);
        }
      }
      break;
    case TargetPlatform.iOS:
      var path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        downloadDir = Directory(path);
      }
      break;
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: "选择保存路径",
        fileName: (name == null || name.isEmpty) ? "image.png" : name,
      );
      if (outputFile == null) {
        return SaveRes(false, "未设置保存路径");
      } else {
        downloadPath = outputFile;
      }
      break;
    case TargetPlatform.fuchsia:
    default:
      downloadDir = null;
  }
  if ((downloadDir == null) && (downloadPath == null)) {
    return SaveRes(false, "未设置保存路径");
  }
  if (downloadDir != null && downloadPath == null) {
    if (!downloadDir.existsSync()) {
      return SaveRes(false, "保存目录不存在");
    }
    var nameHere = name ?? "image.jpg";
    downloadPath ??= path.join(downloadDir.path, nameHere);
    if (File(downloadPath).existsSync()) {
      var num = 0;
      do {
        num += 1;
        var dotIdx = nameHere.lastIndexOf(".");
        downloadPath = path.join(downloadDir.path, "${nameHere.substring(0, dotIdx)}_$num${nameHere.substring(dotIdx)}");
      } while (File(downloadPath).existsSync());
    }
  }
  if (downloadPath == null) {
    return SaveRes(false, "未设置保存路径");
  }
  return SaveRes(true, downloadPath);
}

Future<String?> showColorDialog(BuildContext context, List<String> hexRGBColor) {
  var dialog = SimpleDialog(
    title: const Text("选择颜色"),
    children: hexRGBColor.map((c) {
      return SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, c);
        },
        child: Container(
          color: Color(int.parse("0xff${c.substring(1)}")),
          child: Center(child: Text(c, style: const TextStyle(color: Colors.white))),
        ),
      );
    }).toList(),
  );

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return dialog;
    },
  );
}

typedef FutureOrFunction<T> = Future<T?> Function(String a);

void shareWithResultWrap(BuildContext context, String text, {String? subject}) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null) { return; }
  Share.shareWithResult(
    text,
    subject: subject,
    sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
  ).then((result) {
    var txt = "";
    switch (result.status) {
      case ShareResultStatus.success:
        txt = "分享成功";
        break;
      case ShareResultStatus.dismissed:
        txt = "分享取消";
        break;
      case ShareResultStatus.unavailable:
        txt = "分享不可用";
        break;
      default:
        txt = "分享状态未知";
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(txt),
      duration: const Duration(milliseconds: 600),
    ));
  });
}
