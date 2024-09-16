import 'dart:io';

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:dynamic_fonts/dynamic_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../bdwm/req.dart';
import '../html_parser/board_note_parser.dart';
import '../globalvars.dart';
import '../views/utils.dart';
import '../views/html_widget.dart';

Future<String?> showFontDialog(BuildContext context, List<String> fonts, {String defaultFont=""}) {
  var dialog = SimpleDialog(
    title: const Text("选择字体"),
    children: fonts.map((c) {
      return SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, c);
        },
        child: Text(c, style: c==defaultFont ? const TextStyle(color: Colors.redAccent) : null),
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

Future<bool> isDownloadNotoSansMonoCJKscOK() async {
  var path = (await getApplicationSupportDirectory()).path;
  var file = File('$path/NotoSansMonoCJKsc_regular.ttf');
  return file.existsSync() && file.lengthSync() == 16393784;
}

class BoardNotePage extends StatefulWidget {
  final String bid;
  final String boardName;
  const BoardNotePage({super.key, required this.bid, required this.boardName});

  @override
  State<BoardNotePage> createState() => _BoardNotePageState();
}

class _BoardNotePageState extends State<BoardNotePage> {
  late CancelableOperation getDataCancelable;
  static const ts = TextStyle(fontFamily: "SimSun", fontFamilyFallback: ['monospace', 'roboto', 'serif'], height: 1.0, fontSize: 14,);
  String curFont = avaiFonts[0];
  static const fonts2Name = <String, String>{
    simFont: "",
    notoSansMonoCJKscFont: "NotoSansMonoCJKsc",
  };

  bool get notUseSimSun => curFont != simFont;
  bool get useNotoSansMonoCJKsc => curFont == notoSansMonoCJKscFont;

  @override
  void initState() {
    super.initState();
    // _future = getData();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      debugPrint("cancel it");
    },);
    curFont = globalImmConfigInfo.getBoardNoteFont();
  }

  @override
  void dispose() {
    Future.microtask(() => getDataCancelable.cancel(),);
    super.dispose();
  }

  Future<BoardNoteInfo> getData() async {
    var url = "$v2Host/note.php?bid=${widget.bid}";
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return BoardNoteInfo.error(errorMessage: networkErrorText);
    }
    return parseBoardNoteInfo(resp.body);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var boardNoteInfo = snapshot.data as BoardNoteInfo;
        if (boardNoteInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName),
            ),
            body: Center(
              child: Text(boardNoteInfo.errorMessage!),
            ),
          );
        }
        if (useNotoSansMonoCJKsc) {
          isDownloadNotoSansMonoCJKscOK().then((ok) {
            if (!context.mounted) { return; }
            if (!ok) {
              showInformDialog(context, "下载字体中", "https://bbs.pku.edu.cn/attach/ec/04/ec04cc376b34887c/NotoSansMonoCJKsc-Regular.otf \n15.6MB");
            }
          });
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(boardNoteInfo.boardName ?? widget.boardName),
            actions: [
              TextButton(
                onPressed: () async {
                  var f = await showFontDialog(context, avaiFonts, defaultFont: curFont);
                  if (f==null) { return; }
                  if (!mounted) { return; }
                  await globalImmConfigInfo.setBoardNoteFont(f);
                  setState(() {
                    curFont = f;
                  });
                },
                child: Text("切换字体", style: TextStyle(color: globalConfigInfo.getUseMD3() ? null : Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white)),
              ),
              IconButton(
                onPressed: () {
                  showInformDialog(context, "关于字体", "应该用 SimSun，但是可能会有版权问题，因此用了 Noto Sans Mono CJK SC，凑合一下。\n点击“切换字体”下载。\n手机可以旋转横屏看。");
                },
                icon: const Icon(Icons.info),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: HtmlComponent(boardNoteInfo.note, ts: notUseSimSun ? DynamicFonts.getFont(fonts2Name[curFont] ?? "NotoSansMonoCJKsc", textStyle: ts) : ts, isBoardNote: true, needSelect: false,)
          ),
        );
      },
    );
  }
}
