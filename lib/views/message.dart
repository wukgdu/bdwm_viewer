import 'package:async/async.dart';
import 'package:flutter/material.dart';

import '../views/constants.dart';
import '../html_parser/board_parser.dart';
import '../pages/read_thread.dart';
import '../views/utils.dart';
import '../bdwm/message.dart';
import '../bdwm/req.dart';
import '../globalvars.dart';
import '../utils.dart';
import '../services.dart' show MessageBriefNotifier;

class MessageListPage extends StatefulWidget {
  final MessageBriefNotifier users;
  const MessageListPage({super.key, required this.users});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.users,
      builder: (context, value, child) {
        var users = value as List<TextAndLink>;
        bool deliver = false;
        for (var u in users) {
          if (u.text == "deliver") {
            deliver = true;
            break;
          }
        }
        if (deliver == false) {
          users.insert(0, TextAndLink("deliver", "0"));
        }
        return Container(
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            children: users.map((e) {
              return Card(
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).pushNamed('/messagePerson', arguments: e.text);
                  },
                  leading: const Icon(Icons.person, color: bdwmPrimaryColor,),
                  title: Text(e.text),
                  trailing: e.link!=null && e.link!="0"
                    ? Container(
                      alignment: Alignment.center,
                      width: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: bdwmPrimaryColor,
                      ),
                      child: Text(e.link!, style: const TextStyle(color: Colors.white)),
                    )
                    : null,
                ),
              );
            }).toList(),
          ),
        );
      }
    );
  }
}

class MessagePersonPage extends StatefulWidget {
  final String withWho;
  final int count = 50;
  const MessagePersonPage({super.key, required this.withWho});

  @override
  State<MessagePersonPage> createState() => _MessagePersonPageState();
}

class _MessagePersonPageState extends State<MessagePersonPage> {
  late CancelableOperation getDataCancelable;
  final ScrollController _controller = ScrollController();

  Future<MessageInfo> getData() async {
    // return getExampleCollectionList();
    var resp = await bdwmGetMessages(widget.withWho, widget.count);
    if (resp.success == false) {
      if (resp.error == -1) {
        return MessageInfo.error(success: false, error: -1, desc: networkErrorText);
      }
      return MessageInfo.empty();
    }
    return resp;
  }

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    },);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // _controller.jumpTo(_controller.position.maxScrollExtent);
      var _ = await bdwmSetMessagesRead(widget.withWho);
    });
  }

  @override
  void dispose() {
    Future.microtask(() => getDataCancelable.cancel(),);
    super.dispose();
  }

  Widget oneItem(MessageItem mi) {
    var dWidth = MediaQuery.of(context).size.width;
    var content = mi.content;
    var hp1 = content.indexOf("https");
    var hp2 = content.lastIndexOf("(");
    var rawContent = content;
    var link = "";
    if (hp1 != -1) {
      rawContent = content.substring(0, hp1);
      link = content.substring(hp1, hp2==-1? content.length : hp2);
    }
    rawContent = rawContent.trim();
    link = link.trim();
    return Align(
      alignment: mi.dir == 0 ? Alignment.centerLeft : Alignment.centerRight,
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
          ),
          constraints: BoxConstraints(
            maxWidth: dWidth/1.7,
          ),
          child: SelectionArea(
            child: Text.rich(
              TextSpan(
                text: rawContent,
                children: [
                  if (link.isNotEmpty)
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          if (link.startsWith("https://bbs.pku.edu.cn/v2/user.php")) {
                            var uid = link.split("=").last;
                            Navigator.of(context).pushNamed("/user", arguments: uid);
                          } else if (link.startsWith("https://bbs.pku.edu.cn/v2/post-read-single.php")) {
                            bdwmClient.get(link, headers: genHeaders2()).then((value) {
                              if (value == null) {
                                showNetWorkDialog(context);
                              } else {
                                var link2 = directToThread(value.body, needLink: true);
                                if (link2.isEmpty) { return; }
                                naviGotoThreadByLink(context, link2, "", pageDefault: "a");
                              }
                            });
                          }
                        },
                        child: const Text("点击查看", style: TextStyle(color: bdwmPrimaryColor)),
                      ),
                    ),
                ]
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
          // return const Center(child: Text("加载中"));
        }
        if (snapshot.hasError) {
          return Center(child: Text("错误：${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("错误：未获取数据"));
        }
        var messageinfo = snapshot.data as MessageInfo;
        if (messageinfo.desc != null) {
          return Center(child: Text(messageinfo.desc!),);
        }
        return ListView.builder(
          reverse: true,
          controller: _controller,
          itemCount: widget.count,
          itemBuilder: ((context, index) {
            return oneItem(messageinfo.messages[index]);
          }),
        );
      },
    );
  }
}