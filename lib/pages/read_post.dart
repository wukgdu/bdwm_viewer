import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../html_parser/read_post_parser.dart';
import '../bdwm/req.dart';
import '../globalvars.dart';
import '../views/read_thread.dart' show OnePostComponent;
import './read_thread.dart' show naviGotoThreadByLink;

Future<SinglePostInfo> getSinglePostData(String bid, String postid, {String? type}) async {
  var url = "$v2Host/post-read-single.php?bid=$bid&postid=$postid";
  if (type != null) {
    url += "&type=$type";
  }
  var resp = await bdwmClient.get(url, headers: genHeaders2());
  if (resp == null) {
    return SinglePostInfo.error(errorMessage: networkErrorText);
  }
  return parseSinglePost(resp.body);
}

class SinglePostPage extends StatefulWidget {
  final String bid;
  final String postid;
  final String? boardName;
  final String? type;
  const SinglePostPage({Key? key, required this.bid, this.boardName, required this.postid, this.type}) : super(key: key);
  // ThreadApp.empty({Key? key}) : super(key: key);

  @override
  // State<ThreadApp> createState() => _ThreadAppState();
  State<SinglePostPage> createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  static const _titleFont = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  late CancelableOperation getDataCancelable;

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      debugPrint("cancel it");
    },);
  }

  @override
  void dispose() {
    Future.microtask(() => getDataCancelable.cancel(),);
    super.dispose();
  }

  Future<SinglePostInfo> getData() async {
    return await getSinglePostData(widget.bid, widget.postid, type: widget.type,);
  }

  void refresh() {
    setState(() {
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
        var singlePostInfo = snapshot.data as SinglePostInfo;
        if (singlePostInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName ?? ""),
            ),
            body: Center(
              child: Text(singlePostInfo.errorMessage!),
            ),
          );
        }
        var boardName = singlePostInfo.board.text.split('(').first;
        return Scaffold(
          appBar: AppBar(
            title: Text(boardName),
            actions: [
              IconButton(
                onPressed: () {
                  naviGotoThreadByLink(context, singlePostInfo.threadLink, widget.boardName ?? "", needToBoard: true, replaceIt: false);
                },
                icon: const Icon(Icons.width_full_outlined)
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                alignment: Alignment.centerLeft,
                // height: 20,
                child: Text(
                  singlePostInfo.title,
                  style: _titleFont,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: OnePostComponent(bid: widget.bid, onePostInfo: singlePostInfo.postInfo,
                    threadid: singlePostInfo.threadid, boardName: boardName, title: singlePostInfo.title,
                    refreshCallBack: () {
                      refresh();
                    },
                  ),
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
