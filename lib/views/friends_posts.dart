import 'package:flutter/material.dart';
// import 'package:async/async.dart';

import './constants.dart';
import '../bdwm/req.dart';
import '../bdwm/search.dart';
import '../pages/read_thread.dart' show naviGotoThreadByLink;
import '../globalvars.dart';
import '../html_parser/search_parser.dart';

class FriendsPostsItem {
  String oriAuthor = "";
  String author = "";
  TextAndLinkAndTime info = TextAndLinkAndTime.empty();
  String formatedTimeString = "";
  String title = "";
  String boardName = "";
  FriendsPostsItem({
    required this.oriAuthor,
    required this.author,
    required this.info,
    required this.title,
    required this.boardName,
  }) {
    var tstr = info.time;
    var recentDay = tstr.split(" ").first.split("-");
    if (recentDay.length == 1) {
      // 昨天 前天 分钟前
      var timeStr =recentDay[0]; 
      if (timeStr == "昨天") {
        var date = DateTime.now().toLocal().subtract(const Duration(days: 1));
        formatedTimeString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${tstr.substring(3)}";
      } else if (timeStr == "前天") {
        var date = DateTime.now().toLocal().subtract(const Duration(days: 2));
        formatedTimeString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${tstr.substring(3)}";
      } else if (timeStr.contains(":")) {
        // 今天
        var date = DateTime.now().toLocal();
        formatedTimeString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $tstr";
      } else {
        int t = 0;
        int idx = 0;
        while (idx < timeStr.length) {
          if (timeStr.codeUnitAt(idx) < 255) {
            t = t * 10 + int.parse(timeStr[idx]);
          } else {
            break;
          }
          idx += 1;
        }
        var date = DateTime.now().toLocal().subtract(Duration(minutes: t));
        formatedTimeString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      }
    } else if (recentDay.length == 2) {
      var date = DateTime.now().toLocal();
      formatedTimeString = "${date.year}-$tstr";
    } else if (recentDay.length == 3) {
      formatedTimeString = tstr;
    } else {
      formatedTimeString = tstr;
    }
  }
}

class FriendsPostsInfo {
  int processedCount = 0;
  String curUserName = "";
  String? errorMessage;
  List<FriendsPostsItem> items = [];

  FriendsPostsInfo.error({this.errorMessage});
  FriendsPostsInfo.empty();
  FriendsPostsInfo({
    required this.processedCount,
    required this.curUserName,
    required this.items,
  });
}

class FriendsPostsPage extends StatefulWidget {
  final UserInfoRes friendsInfo;
  const FriendsPostsPage({super.key, required this.friendsInfo});

  @override
  State<FriendsPostsPage> createState() => _FriendsPostsPageState();
}

class _FriendsPostsPageState extends State<FriendsPostsPage> {
  late Stream<FriendsPostsInfo> _stream;
  late FriendsPostsInfo lastFriendsPostsInfo;

  @override
  void initState() {
    super.initState();
    lastFriendsPostsInfo = FriendsPostsInfo.empty();
    _stream = getData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<ComplexSearchRes> getDatum(String userName) async {
    var days = 7;
    var url = "$v2Host/search.php?mode=post&key=&owner=$userName&board=&rated=&days=$days&titleonly=&timeorder=1";
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return ComplexSearchRes.error(errorMessage: networkErrorText);
    }
    return parsePostSearch(resp.body);
  }

  updateFriendsPostsItem(List<FriendsPostsItem> oldItems, ComplexSearchRes csr, String userName) {
    for (var item in csr.resItems) {
      for (var textItem in item.shortTexts) {
        oldItems.add(FriendsPostsItem(
          oriAuthor: item.userName, author: userName, info: textItem,
          title: item.title, boardName: item.boardName,
        ));
      }
    }
    oldItems.sort((a, b) {
      return b.formatedTimeString.compareTo(a.formatedTimeString);
    });
  }

  Stream<FriendsPostsInfo> getData() async* {
    int curIdx = 1;
    var extraUsers = <IDandName>[
      IDandName(id: "", name: globalUInfo.username),
    ];
    var items = <FriendsPostsItem>[];
    int listCount = widget.friendsInfo.users.length + extraUsers.length;
    for (var u in widget.friendsInfo.users + extraUsers) {
      var datum = u as IDandName;
      var res = await getDatum(datum.name);
      if (res.errorMessage != null) {
        yield FriendsPostsInfo.error(errorMessage: res.errorMessage);
      } else {
        updateFriendsPostsItem(items, res, datum.name);
        yield FriendsPostsInfo(processedCount: curIdx, curUserName: datum.name, items: items);
      }
      if (curIdx != listCount) {
      }
      await Future<void>.delayed(const Duration(seconds: 5));
      curIdx += 1;
    }
  }

  Widget _oneItem(FriendsPostsItem item, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          naviGotoThreadByLink(context, item.info.link, item.boardName);
        },
        child: Container(
          padding: const EdgeInsets.all(5.0),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: bdwmPrimaryColor, width: 1.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 18),
                  children: [
                    TextSpan(text: item.title),
                    const TextSpan(text: " "),
                    TextSpan(text: item.boardName, style: const TextStyle(color: Colors.grey)),
                  ]
                )
              ),
              // const Divider(),
              Row(
                children: [
                  Text(item.author, style: const TextStyle(color: Colors.deepOrangeAccent),),
                  const Spacer(),
                  Text(item.info.time),
                ],
              ),
              const Divider(),
              Text(item.info.text),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _stream,
      initialData: FriendsPostsInfo.empty(),
      builder:(context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // return const Center(child: CircularProgressIndicator());
          return const Center(child: CircularProgressIndicator());
        }
        if ((snapshot.connectionState != ConnectionState.active)
          && (snapshot.connectionState != ConnectionState.done)) {
          // return const Center(child: CircularProgressIndicator());
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("错误：${snapshot.error}"),);
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("错误：未获取数据"),);
        }
        var friendsPostsInfo = snapshot.data as FriendsPostsInfo;
        if (friendsPostsInfo.errorMessage != null) {
          friendsPostsInfo = lastFriendsPostsInfo;
        } else {
          lastFriendsPostsInfo = friendsPostsInfo;
        }
        var listBuilder = ListView.builder(
          itemCount: friendsPostsInfo.items.length,
          itemBuilder: (context, index) {
            return _oneItem(friendsPostsInfo.items[index], context);
          },
        );
        if (snapshot.connectionState == ConnectionState.done) {
        // if (friendsPostsInfo.processedCount == widget.friendsInfo.users.length + 1) {
          return listBuilder;
        }
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(5.0),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(text: friendsPostsInfo.processedCount.toString()),
                    TextSpan(text: "/(${widget.friendsInfo.users.length}+1)"),
                    TextSpan(text: " ${friendsPostsInfo.curUserName}"),
                    TextSpan(text: " 共 ${friendsPostsInfo.items.length} 条"),
                  ]
                )
              ),
            ),
            const Divider(),
            Expanded(child: listBuilder),
          ],
        );
      },
    );
  }
}
