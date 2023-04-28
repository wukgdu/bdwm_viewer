import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../html_parser/board_ban_parser.dart';
import '../bdwm/req.dart';
import '../globalvars.dart' show v2Host, networkErrorText, genHeaders2;
import '../views/board_ban.dart' show BoardBanView;
import '../views/utils.dart' show showAlertDialog2;
import '../views/read_thread.dart' show BanUserDialog;

class BoardBanPage extends StatefulWidget {
  final String boardName;
  final String bid;
  const BoardBanPage({super.key, required this.bid, required this.boardName});

  @override
  State<BoardBanPage> createState() => _BoardBanPageState();
}

class _BoardBanPageState extends State<BoardBanPage> {
  late CancelableOperation getDataCancelable;

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData());
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  Future<BoardBanInfo> getData() async {
    var url = "$v2Host/ban.php?bid=${widget.bid}";
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return BoardBanInfo.error(errorMessage: networkErrorText);
    }
    return parseBoardBanInfo(resp.body);
  }

  void refresh() {
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData());
    });
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
        var boardBanInfo = snapshot.data as BoardBanInfo;
        if (boardBanInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName),
            ),
            body: Center(
              child: Text(boardBanInfo.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text("${boardBanInfo.boardName}-禁言"),
            actions: [
              IconButton(
                onPressed: () {
                  showAlertDialog2(context, BanUserDialog(
                    boardName: widget.boardName, bid: widget.bid, userName: "", postid: null, uid: null,
                    showPostid: true,
                  ));
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: BoardBanView(bid: widget.bid, boardBanInfo: boardBanInfo, refresh: () { refresh(); },),
        );
      }
    );
  }
}
