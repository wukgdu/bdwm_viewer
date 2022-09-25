import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../html_parser/top10_parser.dart';
import '../utils.dart';
import '../html_parser/read_thread_parser.dart';
import '../globalvars.dart';
import "./utils.dart";

class BigTenComponent extends StatefulWidget {
  const BigTenComponent({super.key});

  @override
  State<BigTenComponent> createState() => _BigTenComponentState();
}

class _BigTenComponentState extends State<BigTenComponent> {
  late CancelableOperation getDataCancelable;
  static const monthTrans = {
    "01": "Jan", "02": "Feb", "03": "Mar", "04": "Apr", "05": "May", "06": "Jun",
    "07": "Jul", "08": "Aug", "09": "Sep", "10": "Oct", "11": "Nov", "12": "Dec",
  };

  @override
  void initState() {
    getDataCancelable = CancelableOperation.fromFuture(genWidget(), onCancel: () { });
    super.initState();
  }

  Future<Widget> genWidget() async {
    var resp = await bdwmClient.get("$v2Host/mobile/home.php", headers: genHeaders());
    if (resp == null) {
      return const Center(child: Text(networkErrorText),);
    }
    var top10List = parseBigTen(resp.body);
    if (top10List == null) {
      return const Center(child: Text("获取十大失败"),);
    }
    List<String> urls = [];
    for (var tl in top10List) {
      var link = tl.link;
      var bid = getQueryValue(link, "bid");
      var threadid = getQueryValue(link, "threadid");
      if (bid==null || threadid==null) {
        return const Center(child: Text("获取十大失败"),);
      }
      var url = "$v2Host/post-read.php?bid=$bid&threadid=$threadid";
      urls.add(url);
    }
    var respList = await Future.wait(urls.map((e) => bdwmClient.get(e, headers: genHeaders2())));
    if (respList.length != 10) {
      return const Center(child: Text("获取十大失败"),);
    }
    var boardEngName = <String>[];
    var titleName = <String>[];
    var authorName = <String>[];
    var timeStr = <String>[];
    for (var r in respList) {
      if (r==null) {
        return const Center(child: Text("获取十大失败"),);
      }
      var threadInfo = parseThread(r.body, simple: true);
      if (threadInfo.errorMessage != null) {
        return const Center(child: Text("获取十大失败"),);
      }
      var boardName1 = threadInfo.board.text;
      boardName1 = boardName1.split("(").last;
      boardName1 = boardName1.substring(0, boardName1.length-1); // )
      boardName1 = boardName1.padRight(20);
      boardEngName.add(boardName1);
      var authorName1 = threadInfo.posts[0].authorInfo.userName;
      authorName1 = authorName1.padLeft(19);
      authorName.add(authorName1);
      var titleName1 = threadInfo.title;
      var titleLength = termStringLength(titleName1);
      if (titleLength < 62) {
        titleName1 += " "*(62-titleLength);
      }
      titleName.add(titleName1);
      // "2022-09-16 01:41:06" -> "Sep.13 22:59:53"
      var timeStrTmp = threadInfo.posts[0].postTime;
      var timeDate = timeStrTmp.split(" ").first;
      var timeMonth = timeDate.split("-")[1];
      var timeDay = timeDate.split("-")[2];
      var timeStr1 = "${monthTrans[timeMonth] ?? "UKN"}.$timeDay ${timeStrTmp.split(" ").last}";
      timeStr.add(timeStr1);
    }
    return SelectableText('''                [1;34m-----[37m=====[41;37m 本日十大热门话题 [0;1;37m=====[34m-----[0;37m                    [m

[1;30m第 [31m 1[30m 名 信区 : [33m${boardEngName[0]}[0;37m【[1;32m${timeStr[0]}[0;37m】[1;35m${authorName[0]}[m
[1m     标题 : [44;37m${titleName[0]}[m
[1;30m第 [31m 2[30m 名 信区 : [33m${boardEngName[1]}[0;37m【[1;32m${timeStr[1]}[0;37m】[1;35m${authorName[1]}[m
[1m     标题 : [44;37m${titleName[1]}[m
[1;30m第 [31m 3[30m 名 信区 : [33m${boardEngName[2]}[0;37m【[1;32m${timeStr[2]}[0;37m】[1;35m${authorName[2]}[m
[1m     标题 : [44;37m${titleName[2]}[m
[1;30m第 [31m 4[30m 名 信区 : [33m${boardEngName[3]}[0;37m【[1;32m${timeStr[3]}[0;37m】[1;35m${authorName[3]}[m
[1m     标题 : [44;37m${titleName[3]}[m
[1;30m第 [31m 5[30m 名 信区 : [33m${boardEngName[4]}[0;37m【[1;32m${timeStr[4]}[0;37m】[1;35m${authorName[4]}[m
[1m     标题 : [44;37m${titleName[4]}[m
[1;30m第 [31m 6[30m 名 信区 : [33m${boardEngName[5]}[0;37m【[1;32m${timeStr[5]}[0;37m】[1;35m${authorName[5]}[m
[1m     标题 : [44;37m${titleName[5]}[m
[1;30m第 [31m 7[30m 名 信区 : [33m${boardEngName[6]}[0;37m【[1;32m${timeStr[6]}[0;37m】[1;35m${authorName[6]}[m
[1m     标题 : [44;37m${titleName[6]}[m
[1;30m第 [31m 8[30m 名 信区 : [33m${boardEngName[7]}[0;37m【[1;32m${timeStr[7]}[0;37m】[1;35m${authorName[7]}[m
[1m     标题 : [44;37m${titleName[7]}[m
[1;30m第 [31m 9[30m 名 信区 : [33m${boardEngName[8]}[0;37m【[1;32m${timeStr[8]}[0;37m】[1;35m${authorName[8]}[m
[1m     标题 : [44;37m${titleName[8]}[m
[1;30m第 [31m10[30m 名 信区 : [33m${boardEngName[9]}[0;37m【[1;32m${timeStr[9]}[0;37m】[1;35m${authorName[9]}[m
[1m     标题 : [44;37m${titleName[9]}[m
''');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("错误：${snapshot.error}"),);
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("错误：未获取数据"),);
        }
        return snapshot.data as Widget;
      }
    );
  }
}

class FunFunFunPage extends StatefulWidget {
  const FunFunFunPage({super.key});

  @override
  State<FunFunFunPage> createState() => _FunFunFunPageState();
}

class _FunFunFunPageState extends State<FunFunFunPage> {
  bool showBigTen = false;
  Widget? bigTenWidget;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: ListTile(
            onTap: () {
              if (showBigTen == true) {
                setState(() {
                  showBigTen = false;
                  bigTenWidget = null;
                });
                return;
              }
              showAlertDialog(context, "十大拍照", const Text("将要读取当前十大每个帖子的首页"),
                actions1: TextButton(
                  onPressed: () { Navigator.of(context).pop(); },
                  child: const Text("不了"),
                ),
                actions2: TextButton(
                  onPressed: () { Navigator.of(context).pop("ok"); },
                  child: const Text("确认"),
                ),
              ).then((value) {
                if (value == null) { return; }
                if (value == "ok") {
                  if (!mounted) { return; }
                  setState(() {
                    showBigTen = true;
                    bigTenWidget = const BigTenComponent();
                  });
                }
              });
            },
            title: const Text("十大拍照（term）"),
            trailing: const Icon(Icons.arrow_drop_down),
          ),
        ),
        if (showBigTen)
          Card(child: bigTenWidget ?? const Center(child: Text("生成十大拍照失败"))),
        Card(
          child: ListTile(
            onTap: () {
              Navigator.of(context).pushNamed('/seeNoThem');
            },
            title: const Text("不看ta"),
            trailing: const Icon(Icons.arrow_right),
          )
        ),
        Card(
          child: ListTile(
            onTap: () {
              Navigator.of(context).pushNamed('/friendsPosts');
            },
            title: const Text("朋友动态"),
            trailing: const Icon(Icons.arrow_right),
          )
        ),
      ],
    );
  }
}