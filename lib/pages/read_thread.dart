import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../views/read_thread.dart';
import '../views/utils.dart';
import '../html_parser/read_thread_parser.dart';
import '../bdwm/req.dart';
import '../globalvars.dart';
import '../utils.dart' show clearAllExtendedImageCache;
import '../router.dart' show nv2Push;

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
  bool firstTime = true;
  ValueNotifier<bool> marked = ValueNotifier<bool>(false);
  String threadLink = "";
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
    threadLink = "$v2Host/post-read.php?bid=${widget.bid}&threadid=${widget.threadid}";
    marked.value = globalMarkedThread.contains(threadLink);
    getDataCancelable = CancelableOperation.fromFuture(getData(firstTime: true), onCancel: () {
      debugPrint("cancel it");
    },);
  }

  Future<bool> addMarked({required String link, required String title, required String userName, required String boardName}) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    await globalMarkedThread.addOne(link: link, title: title, userName: userName, boardName: boardName, timestamp: timestamp);
    return true;
  }

  void addHistory({required String link, required String title, required String userName, required String boardName}) {
    if (firstTime == false) { return; }
    firstTime = false;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    globalThreadHistory.addOne(link: link, title: title, userName: userName, boardName: boardName, timestamp: timestamp);
  }

  @override
  void dispose() {
    marked.dispose();
    Future.microtask(() => getDataCancelable.cancel(),);
    clearAllExtendedImageCache(really: globalConfigInfo.getAutoClearImageCache());
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
        String userName = "未知";
        if (threadPageInfo.posts.isNotEmpty) {
          userName = threadPageInfo.posts.first.authorInfo.userName;
        }
        addHistory(link: threadLink, title: threadPageInfo.title, userName: userName, boardName: threadPageInfo.board.text);
        return Scaffold(
          appBar: AppBar(
            title: Text(threadPageInfo.board.text.split('(').first),
            actions: [
              ValueListenableBuilder(
                valueListenable: marked,
                builder: (context, value, child) {
                  bool markedValue = value as bool;
                  return IconButton(
                    onPressed: () async {
                      if (markedValue) {
                        globalMarkedThread.removeOne(threadLink);
                      } else {
                        await addMarked(link: threadLink, title: threadPageInfo.title, userName: userName, boardName: threadPageInfo.board.text);
                      }
                      marked.value = !markedValue;
                    },
                    icon: Icon(markedValue ? Icons.star : Icons.star_outline),
                  );
                },
              ),
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
                        nv2Push(context, '/board', arguments: {
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
  var page = gotoThreadPage(arguments);
  if (page == null) { return null; }
  builder = (BuildContext context) => page;
  return builder;
}

Widget? gotoThreadPage(Object? arguments) {
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
  return ThreadApp(boardName: boardName, bid: bid, threadid: threadid, page: page, needToBoard: needToBoard, postid: postid);
}

void naviGotoThread(context, String bid, String threadid, String page, String boardName, {bool? needToBoard}) {
  nv2Push(context, '/thread', arguments: {
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
  nv2Push(context, '/thread', arguments: {
    'bid': bid,
    'threadid': threadid,
    'page': page,
    'boardName': boardName,
    'needToBoard': needToBoard,
    'postid': postid,
  });
}
