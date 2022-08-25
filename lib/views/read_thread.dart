import 'package:flutter/material.dart';

import '../bdwm/req.dart';
import '../globalvars.dart';
import './utils.dart';
import '../html_parser/read_thread_parser.dart';

class ReadThreadPage extends StatefulWidget {
  String bid = "";
  String threadid = "";
  String page = "";
  ReadThreadPage({Key? key, required this.bid, required this.threadid, required this.page}) : super(key: key);

  @override
  State<ReadThreadPage> createState() => _ReadThreadPageState();
}

class _ReadThreadPageState extends State<ReadThreadPage> {
  ThreadPageInfo threadPageInfo = ThreadPageInfo.empty();
  final _titleFont = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  Future<ThreadPageInfo> getData() async {
    var bid = widget.bid;
    var threadid = widget.threadid;
    var page = widget.page;
    var url = "$v2Host/post-read.php?bid=$bid&threadid=$threadid";
    if (! (page == "" || page == "1")) {
      url += "&page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    return parseThread(resp.body);
  }

  @override
  void initState() {
    super.initState();
    getData().then((value) {
      setState(() {
        threadPageInfo = value;
      });
    });
  }

  Widget _onePostWideScreen(OnePostInfo item) {
    double deviceWidth = MediaQuery.of(context).size.width;
    return Card(
      child: Row(
        children: [
          Container(
            width: deviceWidth * 0.2,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(item.authorInfo.avatarLink),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text(item.authorInfo.userName), Text(item.authorInfo.status)]
                ),
                Text(item.authorInfo.nickName),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.authorInfo.score),
                    Text(item.authorInfo.rankName),
                  ],
                ),
                Text("发帖数：${item.authorInfo.postCount}"),
                Text("原创分：${item.authorInfo.rating}"),
              ],
            ),
          ),
          Row(
            children: const [
              Text("内容"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _onepostPhoneScreen(OnePostInfo item) {
    double deviceWidth = MediaQuery.of(context).size.width;
    return Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(item.authorInfo.avatarLink),
              ),
            ),
            onTap: () {
              if (item.authorInfo.uid.isEmpty) {
                return;
              }
              Navigator.of(context).pushNamed('/user', arguments: item.authorInfo.uid);
            },
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.authorInfo.userName),
                      Text(' ('),
                      Flexible(child: renderHtml(item.authorInfo.nickName, needSelect: false),),
                      Text(')'),
                      Text(item.authorInfo.status),
                    ],
                  ),
                  if (item.modifyTime.isNotEmpty)
                    Text(
                      item.modifyTime,
                    ),
                  Text(
                    item.postTime,
                  ),
                  Divider(),
                  renderHtml(item.content),
                  Divider(),
                  renderHtml(item.signature),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _onepost(OnePostInfo item) {
    return _onepostPhoneScreen(item);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: ScrollController(),
      padding: const EdgeInsets.all(8),
      children: [
        Text(
          threadPageInfo.title,
          style: _titleFont,
        ),
        ...threadPageInfo.posts.map((OnePostInfo item) {
          return _onepost(item);
        }).toList(),
      ],
    );
  }
}
