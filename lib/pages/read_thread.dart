import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../views/read_thread.dart';
import '../views/utils.dart';
import '../html_parser/read_thread_parser.dart';
import '../bdwm/req.dart';
import '../globalvars.dart';

class ThreadApp extends StatefulWidget {
  final String bid;
  final String threadid;
  final String page;
  final String? boardName;
  final bool? needToBoard;
  final String? postid;
  const ThreadApp({Key? key, required this.bid, required this.threadid, this.boardName, required this.page, this.needToBoard, this.postid}) : super(key: key);
  // ThreadApp.empty({Key? key}) : super(key: key);

  @override
  // State<ThreadApp> createState() => _ThreadAppState();
  State<ThreadApp> createState() => _ThreadAppState();
}

class _ThreadAppState extends State<ThreadApp> {
  int page = 1;
  late CancelableOperation getDataCancelable;
  String? postid;
  bool tiebaForm = false;
  // Future<ThreadPageInfo>? _future;
  @override
  void initState() {
    super.initState();
    page = widget.page.isEmpty
      ? 1
      : widget.page == "a"
        ? 1
        : int.parse(widget.page);
    // _future = getData();
    postid = widget.postid;
    getDataCancelable = CancelableOperation.fromFuture(getData(firstTime: true), onCancel: () {
      debugPrint("cancel it");
    },);
  }

  @override
  void dispose() {
    Future.microtask(() => getDataCancelable.cancel(),);
    super.dispose();
  }

  Future<ThreadPageInfo> getData({bool firstTime=false}) async {
    var bid = widget.bid;
    var threadid = widget.threadid;
    var url = "$v2Host/post-read.php?bid=$bid&threadid=$threadid";
    if (firstTime && widget.page == "a") {
      url += "&page=a";
      if (widget.postid != null) {
        url += "&postid=${widget.postid}";
      }
    } else if (! (page == 0 || page == 1)) {
      url += "&page=$page";
    }
    if (!firstTime) {
      postid = null;
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return ThreadPageInfo.error(errorMessage: networkErrorText);
    }
    return parseThread(resp.body);
  }

  void refresh() {
    setState(() {
      page = page;
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
        debugPrint("cancel it");
      },);
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
              title: Text(widget.boardName ?? "看帖"),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName ?? "看帖"),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName ?? "看帖"),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var threadPageInfo = snapshot.data as ThreadPageInfo;
        if (threadPageInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName ?? ""),
            ),
            body: Center(
              child: Text(threadPageInfo.errorMessage!),
            ),
          );
        }
        if (threadPageInfo.page != page) {
          page = threadPageInfo.page;
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(threadPageInfo.board.text.split('(').first),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    tiebaForm = !tiebaForm;
                  });
                },
                icon: Icon(tiebaForm ? Icons.change_circle : Icons.account_tree),
              ),
              IconButton(
                onPressed: () {
                  if (!mounted) { return; }
                  shareWithResultWrap(context, "$v2Host/post-read.php?bid=${threadPageInfo.boardid}&threadid=${threadPageInfo.threadid}", subject: "分享帖子");
                },
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          body: ReadThreadPage(bid: widget.bid, threadid: widget.threadid, page: page.toString(), threadPageInfo: threadPageInfo, postid: postid,
            tiebaForm: tiebaForm,
            refreshCallBack: () {
              refresh();
            },
          ),
          bottomNavigationBar: BottomAppBar(
            shape: null,
            // color: Colors.blue,
            child: IconTheme(
              data: const IconThemeData(color: Colors.redAccent),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    disabledColor: Colors.grey,
                    tooltip: '刷新',
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      refresh();
                    },
                  ),
                  if (widget.needToBoard != null && widget.needToBoard == true)
                    IconButton(
                      disabledColor: Colors.grey,
                      tooltip: '返回本版',
                      icon: const Icon(Icons.list),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/board', arguments: {
                          'boardName': threadPageInfo.board.text.split('(').first,
                          'bid': threadPageInfo.boardid,
                        },);
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
                    child: Text("$page/${threadPageInfo.pageNum}"),
                    onPressed: () async {
                      var nPageStr = await showPageDialog(context, page, threadPageInfo.pageNum);
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
                    onPressed: page == threadPageInfo.pageNum ? null : () {
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

// WidgetBuilder? gotoThread(RouteSettings settings) {
WidgetBuilder? gotoThread(Object? arguments) {
  WidgetBuilder builder;
  String bid = "";
  String threadid = "";
  String boardName = "";
  String page = "";
  String? postid;
  bool? needToBoard;
  if (arguments != null) {
    var settingsMap = arguments as Map;
    bid = settingsMap['bid'] as String;
    threadid = settingsMap['threadid'] as String;
    boardName = settingsMap['boardName'] as String;
    page = settingsMap['page'] as String;
    postid = settingsMap['postid'] as String?;
    needToBoard = settingsMap['needToBoard'] as bool?;
  } else {
    return null;
  }
  builder = (BuildContext context) => ThreadApp(boardName: boardName, bid: bid, threadid: threadid, page: page, needToBoard: needToBoard, postid: postid);
  return builder;
}

void naviGotoThread(context, String bid, String threadid, String page, String boardName, {bool? needToBoard}) {
  Navigator.of(context).pushNamed('/thread', arguments: {
    'bid': bid,
    'threadid': threadid,
    'page': page,
    'boardName': boardName,
    'needToBoard': needToBoard,
  });
}

void naviGotoThreadByLink(context, String link, String boardName, {bool? needToBoard, String? pageDefault}) {
  var pb1 = link.indexOf('bid');
  if (pb1 == -1) {
    return;
  }
  var pb2 = link.indexOf('&', pb1);
  var bid = link.substring(pb1+4, pb2 == -1 ? null : pb2);
  var page = pageDefault ?? "1";
  String? postid;
  if (pageDefault != null) {
    var pp1 = link.indexOf('postid');
    if (pp1 != -1) {
      var pp2 = link.indexOf('&', pp1);
      postid = link.substring(pp1+7, pp2 == -1 ? null : pp2);
      postid = postid.split("#").first;
    }
  } else {
    var pp1 = link.indexOf('postid');
    if (pp1 != -1) {
      var pp2 = link.indexOf('&', pp1);
      postid = link.substring(pp1+7, pp2 == -1 ? null : pp2);
      postid = postid.split("#").first;
    }
    var pg1 = link.indexOf("page");
    if (pg1 != -1) {
      var pg2 = link.indexOf('&', pg1);
      page = link.substring(pg1+5, pg2 == -1 ? null : pg2);
    }
  }
  var pt1 = link.indexOf('threadid');
  if (pt1 == -1) {
    return;
  }
  var pt2 = link.indexOf('&', pt1);
  var threadid = link.substring(pt1+9, pt2 == -1 ? null : pt2);
  Navigator.of(context).pushNamed('/thread', arguments: {
    'bid': bid,
    'threadid': threadid,
    'page': page,
    'boardName': boardName,
    'needToBoard': needToBoard,
    'postid': postid,
  });
}
