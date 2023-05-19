import 'package:flutter/material.dart';
import 'package:async/async.dart';

import "../views/search.dart" show PostSearchSettings;
import '../html_parser/board_parser.dart';
import '../html_parser/board_single_parser.dart';
import '../views/constants.dart' show bdwmPrimaryColor;
import '../bdwm/req.dart';
import '../bdwm/search.dart' show bdwmGetPostByNum;
import '../utils.dart' show isValidUserName;
import '../views/board.dart';
import '../globalvars.dart';
import '../views/utils.dart';
// import '../views/constants.dart';
import '../router.dart' show nv2Push, nv2RawPush;

enum BoardSearchType {
  user, str, number,
}

class BoardSearchDialog extends StatefulWidget {
  final String boardEngName;
  final String bid;
  const BoardSearchDialog({super.key, required this.boardEngName, required this.bid});

  @override
  State<BoardSearchDialog> createState() => _BoardSearchDialogState();
}

class _BoardSearchDialogState extends State<BoardSearchDialog> {
  TextEditingController textController = TextEditingController();
  BoardSearchType curType = BoardSearchType.str;

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
        onChanged: (value) {
          String txt = textController.text.trim();
          if (isValidUserName(txt)) {
            setState(() {
              curType = BoardSearchType.user;
            });
          } else if (int.tryParse(txt) != null) {
            setState(() {
              curType = BoardSearchType.number;
            });
          } else {
            setState(() {
              curType = BoardSearchType.str;
            });
          }
        },
        // keyboardType: const TextInputType.numberWithOptions(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("取消"),
        ),
        if (curType == BoardSearchType.number) ...[
          TextButton(
            onPressed: () async {
              String txt = textController.text.trim();
              if (txt.isEmpty) { return; }
              var num = int.tryParse(txt);
              if (num == null) { return; }
              var res = await bdwmGetPostByNum(bid: widget.bid, num: num.toString());
              if (res.success && res.postInfoItem.isNotEmpty) {
                var resPost = res.postInfoItem.first;
                var postid = resPost.postid;
                if (postid == -1) { return; }
                nv2RawPush('/singlePost', arguments: {
                  'bid': widget.bid,
                  'postid': postid.toString(),
                  'boardName': "",
                });
              } else {
                if (!mounted) { return; }
                showInformDialog(context, "跳转失败", res.errorMessage ?? "错误码：${res.error}");
              }
            },
            child: const Text("帖子序号")
          ),
        ] else if (curType == BoardSearchType.user) ...[
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
        ],
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

class BoardPage extends StatefulWidget {
  final String boardName;
  final String bid;
  const BoardPage({Key? key, required this.boardName, required this.bid}) : super(key: key);

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
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

  void refresh() {
    setState(() {
      page = page;
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () { });
    });
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
                  showAlertDialog2(context, BoardSearchDialog(boardEngName: boardInfo.engName, bid: widget.bid,));
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
          body: BoardView(bid: widget.bid, page: page, boardInfo: boardInfo, refresh: () { refresh(); },),
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
                      refresh();
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

class BoardSinglePage extends StatefulWidget {
  final String boardName;
  final String bid;
  final String? stype;
  final String smode;
  const BoardSinglePage({Key? key, required this.boardName, required this.bid, this.stype, required this.smode}) : super(key: key);

  @override
  State<BoardSinglePage> createState() => _BoardSinglePageState();
}

class _BoardSinglePageState extends State<BoardSinglePage> {
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

  void refresh() {
    setState(() {
      page = page;
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
        debugPrint("cancel it");
      },);
    });
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
                  showAlertDialog2(context, BoardSearchDialog(boardEngName: boardInfo.engName, bid: widget.bid,));
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
          body: BoardSingleView(bid: widget.bid, page: page, boardInfo: boardInfo, stype: widget.stype, smode: widget.smode, refresh: () { refresh(); },),
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
                    refresh();
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
