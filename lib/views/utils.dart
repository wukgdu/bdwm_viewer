import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart' show Permission;
// import 'package:fwfh_selectable_text/fwfh_selectable_text.dart';

import '../globalvars.dart' show networkErrorText;
import './constants.dart';
import '../utils.dart' show quickNotify, checkAndRequestPermission;

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

Future<String?> showConfirmDialog(BuildContext context, String title, String content) {
  return showAlertDialog(context, title, SelectableText(content),
    actions1: TextButton(
      onPressed: () {
        Navigator.of(context).pop();
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

Future<String?> showTextDialog(BuildContext context, String title, {bool inputNumber=false}) {
  TextEditingController textValue = TextEditingController();
  Widget content() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: textValue,
            keyboardType: inputNumber == true ? const TextInputType.numberWithOptions() : null,
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

Widget genVipLabel(int vipIdentity) {
  return Container(
    width: 16,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      // border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
      color: getVipColor(vipIdentity),
    ),
    child: const Text("V", style: TextStyle(color: Colors.white, fontSize: 14,),),
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
                var down = downloadPath ?? "";
                if (down.isEmpty) {
                  var fn = filename ?? path.basename(link);
                  var saveRes = await genDownloadPath(name: fn);
                  if (saveRes.success == false) {
                    return;
                  }
                  down = saveRes.reason;
                } else {
                  var couldStore = await checkAndRequestPermission(Permission.storage);
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

class SaveRes {
  bool success = false;
  String reason = "";
  SaveRes(this.success, this.reason);
}

Future<SaveRes> genDownloadPath({String? name}) async {
  var couldStore = await checkAndRequestPermission(Permission.storage);
  if (couldStore == false) {
    return SaveRes(false, "没有保存文件权限");
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
      if (name!=null) {
        name = name.replaceAll(RegExp(r'[<>:\/\\|?*"]'), "_");
      }
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: "选择保存路径",
        fileName: (name == null || name.isEmpty) ? "image.jpg" : name,
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
