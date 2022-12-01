import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../html_parser/board_note_parser.dart';
import '../globalvars.dart';
import '../views/html_widget.dart';

class BoardNoteApp extends StatefulWidget {
  final String bid;
  final String boardName;
  const BoardNoteApp({super.key, required this.bid, required this.boardName});

  @override
  State<BoardNoteApp> createState() => _BoardNoteAppState();
}

class _BoardNoteAppState extends State<BoardNoteApp> {
  late CancelableOperation getDataCancelable;

  @override
  void initState() {
    super.initState();
    // _future = getData();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      debugPrint("cancel it");
    },);
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
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.boardName),
          ),
          body: SingleChildScrollView(
            child: HtmlComponent(boardNoteInfo.note, ts: const TextStyle(fontFamily: "SimSun", fontFamilyFallback: ['NotoSansMonoCJKsc', 'monospace', 'roboto', 'serif'], height: 1.0, fontSize: 14), isBoardNote: true, needSelect: false,),
          ),
        );
      },
    );
  }
}
