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

Future<bool> isDownloadOK() async {
  var path = (await getApplicationSupportDirectory()).path;
  var file = File('$path/NotoSansMonoCJKsc_regular.ttf');
  return file.existsSync() && file.lengthSync() == 16393784;
}

class BoardNoteApp extends StatefulWidget {
  final String bid;
  final String boardName;
  const BoardNoteApp({super.key, required this.bid, required this.boardName});

  @override
  State<BoardNoteApp> createState() => _BoardNoteAppState();
}

class _BoardNoteAppState extends State<BoardNoteApp> {
  late CancelableOperation getDataCancelable;
  static const ts = TextStyle(fontFamily: "SimSun", fontFamilyFallback: ['NotoSansMonoCJKsc', 'monospace', 'roboto', 'serif']);
  bool useNotoSansMonoCJKsc = false;

  @override
  void initState() {
    super.initState();
    // _future = getData();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      debugPrint("cancel it");
    },);
    Future.microtask(() async {
      if (await isDownloadOK()) {
        useNotoSansMonoCJKsc = true;
      }
    });
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
          isDownloadOK().then((ok) {
            if (!mounted) { return; }
            if (!ok) {
              showInformDialog(context, "下载字体中", "rt");
            }
          });
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.boardName),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    useNotoSansMonoCJKsc = !useNotoSansMonoCJKsc;
                  });
                },
                child: Text("切换字体", style: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white),),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: HtmlComponent(boardNoteInfo.note, ts: useNotoSansMonoCJKsc ? DynamicFonts.getFont("NotoSansMonoCJKsc", textStyle: ts) : ts, isBoardNote: true, needSelect: false,)
          ),
        );
      },
    );
  }
}
