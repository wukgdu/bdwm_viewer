import 'dart:io' show Directory, File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:media_scanner/media_scanner.dart';
// import 'package:fwfh_selectable_text/fwfh_selectable_text.dart';

import '../globalvars.dart' show networkErrorText;
import './constants.dart';
import '../utils.dart' show checkAndRequestStoragePermission, genSavePathByTime;
import '../notification.dart' show sendNotification;

class SimpleTuple2 {
  String name;
  String action;
  SimpleTuple2({
    required this.name,
    required this.action,
  });
}

Future<String?> getOptOptions(BuildContext context, List<SimpleTuple2> data, {bool isScrollControlled=true, Widget? desc}) async {
  var opt = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (BuildContext context1) {
      return Container(
        margin: const EdgeInsets.all(10.0),
        child: Wrap(
          children: [
            if (desc != null) ...[
              desc,
              const Divider(),
            ],
            for (var datum in data) ...[
              ListTile(
                // dense: true,
                onTap: () { Navigator.of(context).pop(datum.action); },
                title: Center(child: Text(datum.name, style: TextStyle(color: bdwmPrimaryColor),)),
              ),
            ],
            // ListTile(
            //   onTap: () { Navigator.of(context).pop(); },
            //   title: Center(child: Text("取消", style: TextStyle(color: bdwmPrimaryColor),)),
            // ),
          ],
        ),
      );
    }
  );
  return opt;
}

Future<String?> showAlertDialog(BuildContext context, String title, Widget content, {Widget? actions1, Widget? actions2, Widget? actions3, List<Widget>? actions, bool? barrierDismissible=true}) {
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

Future<String?> showAlertDialog2(BuildContext context, Widget alert, {bool? barrierDismissible=true}) {
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

Future<String?> showInformDialog(BuildContext context, String title, String content) {
  return showAlertDialog(context, title, SelectableText(content),
    actions1: TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text("知道了"),
    ),
  );
}

Future<String?> showComplexInformDialog(BuildContext context, String title, Widget content) {
  return showAlertDialog(context, title, content,
    actions1: TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text("知道了"),
    ),
  );
}

Future<String?> showConfirmDialog(BuildContext context, String title, String content) {
  return showAlertDialog(context, title, SelectableText(content),
    actions1: TextButton(
      onPressed: () {
        Navigator.of(context).pop("no");
      },
      child: const Text("不了"),
    ),
    actions2: TextButton(
      onPressed: () {
        Navigator.of(context).pop("yes");
      },
      child: const Text("对的"),
    ),
  );
}

Future<String?> showComplexConfirmDialog(BuildContext context, String title, Widget content) {
  return showAlertDialog(context, title, content,
    actions1: TextButton(
      onPressed: () {
        Navigator.of(context).pop("no");
      },
      child: const Text("不了"),
    ),
    actions2: TextButton(
      onPressed: () {
        Navigator.of(context).pop("yes");
      },
      child: const Text("对的"),
    ),
  );
}

class PageDialog extends StatefulWidget {
  final int maxPage;
  const PageDialog({super.key, required this.maxPage});

  @override
  State<PageDialog> createState() => _PageDialogState();
}

class _PageDialogState extends State<PageDialog> {
  TextEditingController pageValue = TextEditingController();

  @override
  void dispose() {
    pageValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("跳转"),
      content: Row(
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
          Text(widget.maxPage.toString()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () { Navigator.of(context).pop(); },
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () {
            if (pageValue.text.isEmpty) { return; }
            var nPage = int.tryParse(pageValue.text);
            if (nPage == null) { return; }
            if ((nPage > 0) && (nPage <= widget.maxPage)) {
              Navigator.of(context).pop(pageValue.text);
            }
          },
          child: const Text("确认"),
        ),
      ],
    );
  }
}

Future<String?> showPageDialog(BuildContext context, int curPage, int maxPage) {
  return showAlertDialog2(
    context,
    PageDialog(maxPage: maxPage)
  );
}

class TextDialog extends StatefulWidget {
  final String title;
  final bool inputNumber;
  final String? defaultText;
  const TextDialog({super.key, required this.title, this.inputNumber=false, this.defaultText});

  @override
  State<TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<TextDialog> {
  TextEditingController textValue = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.defaultText!=null) {
      textValue.value = TextEditingValue(text: widget.defaultText!);
    }
  }

  @override
  void dispose() {
    textValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: textValue,
              autocorrect: false,
              keyboardType: widget.inputNumber == true ? const TextInputType.numberWithOptions() : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () { Navigator.of(context).pop(); },
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () {
            if (textValue.text.isEmpty) { return; }
            Navigator.of(context).pop(textValue.text);
          },
          child: const Text("确认"),
        ),
      ],
    );
  }
}

Future<String?> showTextDialog(BuildContext context, String title, {bool inputNumber=false, String? defaultText}) {
  return showAlertDialog2(
    context,
    TextDialog(title: title, inputNumber: inputNumber, defaultText: defaultText,),
  );
}

Widget genVipLabel(int vipIdentity) {
  return Container(
    width: 16,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      // border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
      color: getVipColor(vipIdentity),
    ),
    child: const Text("V", style: TextStyle(color: Colors.white, fontSize: 12, height: 1.0),),
  );
}

Widget genThreadLabel(String label) {
  return Container(
    width: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      // border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
      color: topicsLabelColor[label] ?? bdwmPrimaryColor,
    ),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, height: null),),
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
                var down = downloadPath ?? "";
                if (down.isEmpty) {
                  var fn = filename ?? path.basename(Uri.decodeFull(link));
                  var saveRes = await genDownloadPath(name: fn);
                  if (saveRes.success == false) {
                    return;
                  }
                  down = saveRes.reason;
                } else {
                  var couldStore = await checkAndRequestStoragePermission();
                  if (couldStore == false) {
                    return;
                  }
                }
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
                      if  (defaultTargetPlatform == TargetPlatform.android) {
                        MediaScanner.loadMedia(path: down);
                      }
                      sendNotification("下载完成", down);
                    } else {
                      sendNotification("写入文件失败", down);
                    }
                  },);
                } else {
                  if (timeout) {
                    sendNotification("下载超时", "超过$seconds秒");
                  } else {
                    sendNotification("下载失败", down);
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

Future<String?> showDownloadMenu(BuildContext context, String link) async {
  return showModalBottomSheet<String>(
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
                Navigator.of(context).pop("yes");
              }
            ),
          ],
        ),
      );
    },
  );
}

class LongPressIconButton extends StatelessWidget {
  final bool enabled;
  final Color primaryColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? iconSize;
  final IconData iconData;
  final Color? disabledColor;

  const LongPressIconButton({
    super.key,
    required this.primaryColor,
    required this.iconData,
    required this.enabled,
    this.iconSize,
    this.onTap,
    this.onLongPress,
    this.disabledColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      borderRadius: BorderRadius.circular((iconSize ?? 24.0) / 2.0 + 8.0),
      hoverColor: primaryColor.withAlpha(20),
      focusColor: primaryColor.withAlpha(20),
      highlightColor: primaryColor.withAlpha(30),
      splashColor: primaryColor.withAlpha(30),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Icon(iconData, color: enabled ? primaryColor : disabledColor, size: iconSize,),
      ),
    );
  }
}

class SizedTextButton extends StatelessWidget {
  final Widget child;
  final Function()? onPressed;
  final ButtonStyle? style;
  final double height;
  static final textButtonStyle = TextButton.styleFrom(
    minimumSize: const Size(40, 20),
    padding: const EdgeInsets.all(0.0),
    // textStyle: MaterialStatePropertyAll(TextStyle(fontSize: 12)),
  );
  const SizedTextButton({super.key, required this.child, this.onPressed, this.style, this.height=30});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextButton(
        style: style ?? textButtonStyle,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

class SizedIconButton extends StatelessWidget {
  final Widget icon;
  final Function()? onPressed;
  final ButtonStyle? style;
  final double size;
  const SizedIconButton({super.key, required this.icon, this.onPressed, this.style, this.size=30});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: size/2,
        style: style,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}

LayoutBuilder genScrollableWidgetForPullRefresh(Widget child)  {
  return LayoutBuilder(builder: (context, constraints) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: child,
      ),
    );
  },);
}

class SaveRes {
  bool success = false;
  String reason = "";
  SaveRes(this.success, this.reason);
}

Future<SaveRes> genDownloadPath({String? name}) async {
  var couldStore = await checkAndRequestStoragePermission();
  if (couldStore == false) {
    return SaveRes(false, "没有保存文件权限");
  }
  if (name!=null) {
    name = name.replaceAll(RegExp(r'[<>:\/\\|?*"]'), "_");
  }
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
        fileName: (name == null || name.isEmpty) ? genSavePathByTime(srcType: ".png") : name,
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
    var nameHere = name ?? genSavePathByTime(srcType: ".png");
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
  var newText = text;
  var newSubject = subject;
  if (Platform.isWindows) {
    if (subject == null || subject.isEmpty) { return; }
    // newText = subject;
    // newSubject = text;
  }
  SharePlus.instance.share(
    ShareParams(
      text: newText,
      subject: newSubject,
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    )
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(txt),
        duration: const Duration(milliseconds: 600),
      ));
    }
  });
}
