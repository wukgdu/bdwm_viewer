import 'package:flutter/material.dart';
import 'package:async/async.dart';

import "../views/search.dart" show PostSearchSettings;
import '../html_parser/board_parser.dart';
import '../html_parser/board_single_parser.dart';
import '../views/constants.dart' show bdwmPrimaryColor;
import '../bdwm/req.dart';
import '../views/board.dart';
import '../globalvars.dart';
import '../views/utils.dart';
// import '../views/constants.dart';
import '../router.dart' show nv2Push;

class BoardSearchAlert extends StatefulWidget {
  final String boardEngName;
  const BoardSearchAlert({super.key, required this.boardEngName});

  @override
  State<BoardSearchAlert> createState() => _BoardSearchAlertState();
}

class _BoardSearchAlertState extends State<BoardSearchAlert> {
  TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("版内搜索"),
      content: TextField(
        controller: textController,
        // keyboardType: const TextInputType.numberWithOptions(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () {
            String txt = textController.text.trim();
            if (txt.isEmpty) { return; }
            PostSearchSettings pss = PostSearchSettings.empty();
            pss.days = "24855";
            pss.owner = txt;
            pss.board = widget.boardEngName;
            nv2Push(context, "/complexSearchResult", arguments: {
              "settings": pss,
            });
          },
          child: const Text("搜索用户")
        ),
        TextButton(
          onPressed: () {
            String txt = textController.text.trim();
            if (txt.isEmpty) { return; }
            PostSearchSettings pss = PostSearchSettings.empty();
            pss.days = "24855";
            pss.keyWord = txt;
            pss.board = widget.boardEngName;
            nv2Push(context, "/complexSearchResult", arguments: {
              "settings": pss,
            });
          },
          child: const Text("搜索内容")
        ),
      ],
    );
  }
}

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

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   int pid = getForceID();
  //   debugPrint("*************** change $pid");
  //   forceRefresh(-1);
  //   getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
  //     debugPrint("cancel it");
  //   },);
  // }

  Future<BoardInfo> getData() async {
    var url = "$v2Host/thread.php?bid=${widget.bid}";
    if (! (page == 0 || page == 1)) {
      url += "&page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return BoardInfo.error(errorMessage: networkErrorText);
    }
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
            actions: [
              IconButton(
                onPressed: () {
                  showComplexInformDialog(context, "属性", SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText("在线：${boardInfo.onlineCount}"),
                        SelectableText("今日：${boardInfo.todayCount}"),
                        SelectableText("主题：${boardInfo.topicCount}"),
                        SelectableText("帖数：${boardInfo.postCount}"),
                        if (boardInfo.ycfCount.isNotEmpty) SelectableText("原创分：${boardInfo.ycfCount}"),
                      ],
                    ),
                  ));
                },
                icon: const Icon(Icons.info),
              ),
              IconButton(
                onPressed: () {
                  showAlertDialog2(context, BoardSearchAlert(boardEngName: boardInfo.engName,));
                },
                icon: const Icon(Icons.search),
              ),
            ],
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
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '刷新',
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      if (!mounted) { return; }
                      setState(() {
                        page = page;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                          debugPrint("cancel it");
                        },);
                      });
                    },
                  ),
                  IconButton(
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '发帖',
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      nv2Push(context, '/post', arguments: {
                        'bid': widget.bid,
                        'boardName': boardInfo.boardName,
                      });
                    },
                  ),
                  IconButton(
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '上一页',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: page <= 1 ? null : () {
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
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '下一页',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: page >= boardInfo.pageNum ? null : () {
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

class BoardSingleApp extends StatefulWidget {
  final String boardName;
  final String bid;
  final String? stype;
  final String smode;
  const BoardSingleApp({Key? key, required this.boardName, required this.bid, this.stype, required this.smode}) : super(key: key);

  @override
  State<BoardSingleApp> createState() => _BoardSingleAppState();
}

class _BoardSingleAppState extends State<BoardSingleApp> {
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

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  Future<BoardSingleInfo> getData() async {
    var url = "$v2Host/thread.php?bid=${widget.bid}&mode=single";
    if (widget.stype != null) {
      url += "&type=${widget.stype}";
    }
    if (! (page == 0 || page == 1)) {
      url += "&page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return BoardSingleInfo.error(errorMessage: networkErrorText);
    }
    return parseBoardSingleInfo(resp.body);
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
        var boardInfo = snapshot.data as BoardSingleInfo;
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
            actions: [
              IconButton(
                onPressed: () {
                  showAlertDialog2(context, BoardSearchAlert(boardEngName: boardInfo.engName,));
                },
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          // floatingActionButton: IconButton(
          //   icon: const Icon(Icons.add_circle, color: bdwmPrimaryColor, size: 24,),
          //   onPressed: () {
          //   },
          // ),
          // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          body: BoardSinglePage(bid: widget.bid, page: page, boardInfo: boardInfo, stype: widget.stype, smode: widget.smode),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            // color: Colors.blue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  color: bdwmPrimaryColor,
                  disabledColor: Colors.grey,
                  tooltip: '刷新',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    if (!mounted) { return; }
                    setState(() {
                      page = page;
                      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                        debugPrint("cancel it");
                      },);
                    });
                  },
                ),
                IconButton(
                  color: bdwmPrimaryColor,
                  disabledColor: Colors.grey,
                  tooltip: '发帖',
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    nv2Push(context, '/post', arguments: {
                      'bid': widget.bid,
                      'boardName': boardInfo.boardName,
                    });
                  },
                ),
                IconButton(
                  color: bdwmPrimaryColor,
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
                  color: bdwmPrimaryColor,
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
        );
      },
    );
  }
}
