import 'package:flutter/material.dart';

import '../views/read_thread.dart';
import '../html_parser/read_thread_parser.dart';
import '../bdwm/req.dart';
import '../globalvars.dart';

class ThreadApp extends StatefulWidget {
  final String bid;
  final String threadid;
  final String page;
  final String? boardName;
  const ThreadApp({Key? key, required this.bid, required this.threadid, this.boardName, required this.page}) : super(key: key);
  // ThreadApp.empty({Key? key}) : super(key: key);

  @override
  State<ThreadApp> createState() => _ThreadAppState();
}

class _ThreadAppState extends State<ThreadApp> {
  int page = 0;
  // Future<ThreadPageInfo>? _future;
  @override
  void initState() {
    super.initState();
    page = widget.page.isEmpty ? 0 : int.parse(widget.page);
    // _future = getData();
  }

  Future<ThreadPageInfo> getData() async {
    var bid = widget.bid;
    var threadid = widget.threadid;
    var url = "$v2Host/post-read.php?bid=$bid&threadid=$threadid";
    if (! (page == 0 || page == 1)) {
      url += "&page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    return parseThread(resp.body);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // return const CircularProgressIndicator();
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName ?? "看帖"),
            ),
            body: ReadThreadPage(bid: widget.bid, threadid: widget.threadid, page: page.toString(), threadPageInfo: ThreadPageInfo.empty(),),
            bottomNavigationBar: BottomAppBar(
              shape: null,
              // color: Colors.blue,
              child: IconTheme(
                data: IconThemeData(color: Colors.redAccent),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      tooltip: '上一页',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () { },
                    ),
                    TextButton(
                      child: Text("/"),
                      onPressed: () {},
                    ),
                    IconButton(
                      tooltip: '下一页',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () { },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text("错误：${snapshot.error}");
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Text("错误：未获取数据");
        }
        var threadPageInfo = snapshot.data as ThreadPageInfo;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.boardName ?? "看帖"),
          ),
          body: ReadThreadPage(bid: widget.bid, threadid: widget.threadid, page: page.toString(), threadPageInfo: threadPageInfo,),
          bottomNavigationBar: BottomAppBar(
            shape: null,
            // color: Colors.blue,
            child: IconTheme(
              data: IconThemeData(color: Colors.redAccent),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    disabledColor: Colors.grey,
                    tooltip: '上一页',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: page == 1 ? null : () {
                      setState(() {
                        page = page - 1;
                      });
                    },
                  ),
                  TextButton(
                    child: Text("$page/${threadPageInfo.pageNum}"),
                    onPressed: () {},
                  ),
                  IconButton(
                    disabledColor: Colors.grey,
                    tooltip: '下一页',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: page == threadPageInfo.pageNum ? null : () {
                      // if (page == threadPageInfo.pageNum) {
                      //   return;
                      // }
                      setState(() {
                        page = page + 1;
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
  if (arguments != null) {
    var settingsMap = arguments as Map;
    bid = settingsMap['bid'] as String;
    threadid = settingsMap['threadid'] as String;
    boardName = settingsMap['boardName'] as String;
    page = settingsMap['page'] as String;
  } else {
    return null;
  }
  builder = (BuildContext context) => ThreadApp(boardName: boardName, bid: bid, threadid: threadid, page: page,);
  return builder;
}

void naviGotoThread(context, String bid, String threadid, String page, String boardName) {
  Navigator.of(context).pushNamed('/thread', arguments: {
    'bid': bid,
    'threadid': threadid,
    'page': page,
    'boardName': boardName,
  });
}

void naviGotoThreadByLink(context, String link, String boardName) {
  var pb1 = link.indexOf('bid');
  var pb2 = link.indexOf('&', pb1);
  var pt1 = link.indexOf('threadid');
  var pt2 = link.indexOf('&', pt1);
  var bid = link.substring(pb1+4, pb2 == -1 ? null : pb2);
  var threadid = link.substring(pt1+9, pt2 == -1 ? null : pt2);
  var page = "1";
  Navigator.of(context).pushNamed('/thread', arguments: {
    'bid': bid,
    'threadid': threadid,
    'page': page,
    'boardName': boardName,
  });
}