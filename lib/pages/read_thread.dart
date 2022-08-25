import 'package:flutter/material.dart';

import '../views/read_thread.dart';

class ThreadApp extends StatefulWidget {
  String bid = "";
  String threadid = "";
  String page = "";
  String? boardName;
  ThreadApp({Key? key, required this.bid, required this.threadid, this.boardName, required this.page}) : super(key: key);
  ThreadApp.empty({Key? key}) : super(key: key);

  @override
  State<ThreadApp> createState() => _ThreadAppState();
}

class _ThreadAppState extends State<ThreadApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName ?? "看帖"),
      ),
      body: ReadThreadPage(bid: widget.bid, threadid: widget.threadid, page: widget.page),
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
                icon: const Icon(Icons.arrow_left),
                onPressed: () {
                  int pageInt = int.parse(widget.page);
                  if (pageInt == 1) {
                    return;
                  }
                  var page = (pageInt - 1).toString();
                  Navigator.of(context).pushReplacementNamed('/thread', arguments: {
                    'bid': widget.bid,
                    'threadid': widget.threadid,
                    'page': page,
                    'boardName': widget.boardName,
                  });
                },
              ),
              TextButton(
                child: Text(widget.page),
                onPressed: () {},
              ),
              IconButton(
                tooltip: '下一页',
                icon: const Icon(Icons.arrow_right),
                onPressed: () {
                  int pageInt = int.parse(widget.page);
                  var page = (pageInt + 1).toString();
                  Navigator.of(context).pushReplacementNamed('/thread', arguments: {
                    'bid': widget.bid,
                    'threadid': widget.threadid,
                    'page': page,
                    'boardName': widget.boardName,
                  });
                },
              ),
            ],
          ),
        ),
      ),
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