import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../html_parser/board_parser.dart';
import '../bdwm/req.dart';
import '../views/board.dart';
import '../globalvars.dart';
import '../views/utils.dart';
import '../views/constants.dart';

class BoardApp extends StatefulWidget {
  final String boardName;
  final String bid;
  const BoardApp({Key? key, required this.boardName, required this.bid}) : super(key: key);

  @override
  State<BoardApp> createState() => _BoardAppState();
}

class _BoardAppState extends State<BoardApp> {
  int page = 1;
  late CancelableOperation getDataCancelable;

  @override
  void initState() {
    super.initState();
    page = 1;
    // _future = getData();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      debugPrint("cancel it");
    },);
  }

  Future<BoardInfo> getData() async {
    var url = "$v2Host/thread.php?bid=${widget.bid}";
    if (! (page == 0 || page == 1)) {
      url += "&page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    return parseBoardInfo(resp.body);
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
          return Text("错误：${snapshot.error}");
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text("错误：未获取数据");
        }
        var boardInfo = snapshot.data as BoardInfo;
        if (boardInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName),
            ),
            body: Center(
              child: Text(boardInfo.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(boardInfo.boardName),
          ),
          // floatingActionButton: IconButton(
          //   icon: const Icon(Icons.add_circle, color: bdwmPrimaryColor, size: 24,),
          //   onPressed: () {
          //   },
          // ),
          // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          body: BoardPage(bid: widget.bid, page: page, boardInfo: boardInfo,),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            // color: Colors.blue,
            child: IconTheme(
              data: const IconThemeData(color: Colors.redAccent),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    disabledColor: Colors.grey,
                    tooltip: '发帖',
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/post', arguments: {
                        'bid': widget.bid,
                        'boardName': boardInfo.boardName,
                      }).then((value) {
                        if (value != null && value == true) {
                          if (!mounted) { return; }
                          setState(() {
                            page = page;
                            getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                              debugPrint("cancel it");
                            },);
                          });
                        }
                      });
                    },
                  ),
                  IconButton(
                    disabledColor: Colors.grey,
                    tooltip: '上一页',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: page == 1 ? null : () {
                      if (!mounted) { return; }
                      setState(() {
                        page = page - 1;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                          debugPrint("cancel it");
                        },);
                      });
                    },
                  ),
                  TextButton(
                    child: Text("$page/${boardInfo.pageNum}"),
                    onPressed: () async {
                      var nPageStr = await showPageDialog(context, page, boardInfo.pageNum);
                      if (nPageStr == null) { return; }
                      if (nPageStr.isEmpty) { return; }
                      var nPage = int.parse(nPageStr);
                      setState(() {
                        page = nPage;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                          debugPrint("cancel it");
                        },);
                      });
                    },
                  ),
                  IconButton(
                    disabledColor: Colors.grey,
                    tooltip: '下一页',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: page == boardInfo.pageNum ? null : () {
                      // if (page == threadPageInfo.pageNum) {
                      //   return;
                      // }
                      if (!mounted) { return; }
                      setState(() {
                        page = page + 1;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                          debugPrint("cancel it");
                        },);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}