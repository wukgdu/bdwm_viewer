import 'dart:async';

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
import '../services_instance.dart';
import '../services.dart' show MessageBriefNotifier;

class MessageListPage extends StatefulWidget {
  final MessageBriefNotifier users;
  const MessageListPage({super.key, required this.users});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.users,
      builder: (context, value, child) {
        var users = (value as List<TextAndLink>).map((e) => TextAndLink(e.text, e.link)).toList();
        bool deliver = false;
        Set<String> usersSet = Set.from(users.map((e) => e.text));
        var clist = globalContactInfo.contact.toList(growable: false);
        clist.sort();
        for (var u in clist) {
          if (!usersSet.contains(u)) {
            users.add(TextAndLink(u, "0"));
          }
        }
        if (usersSet.isNotEmpty) {
          globalContactInfo.addAll(usersSet);
        }
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
            controller: _controller,
            children: users.map((e) {
              return Card(
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).pushNamed('/messagePerson', arguments: e.text);
                  },
                  onLongPress: () {
                    if (e.text == "deliver") { return; }
                    showAlertDialog(context, "", const Text("删除此对话？"),
                      actions1: TextButton(
                        child: const Text("不了"), 
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      actions2: TextButton(
                        child: const Text("对的"), 
                        onPressed: () {
                          Navigator.of(context).pop("yes");
                        },
                      ),
                    ).then((value) {
                      if (value!=null && value=="yes") {
                        globalContactInfo.removeOne(e.text).then((value) {
                          setState(() { });
                        });
                      }
                    },);
                  },
                  leading: const Icon(Icons.person, color: bdwmPrimaryColor,),
                  title: Text(e.text),
                  trailing: e.link!=null && e.link!="0"
                    ? Container(
                      alignment: Alignment.center,
                      width: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: bdwmPrimaryColor,
                      ),
                      child: Text(int.parse(e.link!) > 9 ? "9+" : e.link!, style: const TextStyle(color: Colors.white)),
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
  TextEditingController contentController = TextEditingController();

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
      var res = await bdwmSetMessagesRead(widget.withWho);
      if (res == true) {
        unreadMessage.clearOne(widget.withWho);
      }
    });
  }

  void update() {
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      },);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    contentController.dispose();
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
    if ((mi.withWho == "deliver") && (hp1 != -1)) {
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
            maxWidth: dWidth*0.7,
          ),
          child: SelectionArea(
            child: Text.rich(
              TextSpan(
                text: "${DateTime.fromMillisecondsSinceEpoch(mi.time*1000).toString().split('.').first}\n",
                children: [
                  TextSpan(text: rawContent),
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
                        child: const Text("[点击查看]", style: TextStyle(color: bdwmPrimaryColor)),
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
    return Column(
      children: [
        Expanded(
          child: FutureBuilder(
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
              if (messageinfo.success == false) {
                if (messageinfo.desc != null) {
                  return Center(child: Text(messageinfo.desc!),);
                } else {
                  return const Center(child: Text("出错啦"),);
                }
              }
              return ListView(
                reverse: true,
                controller: _controller,
                // itemCount: widget.count,
                // itemBuilder: ((context, index) {
                //   return oneItem(messageinfo.messages[index]);
                // }),
                children: messageinfo.messages.map((e) {
                  return oneItem(e);
                }).toList(),
              );
            }
          )
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 5, top: 5),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  update();
                },
                icon: const Icon(Icons.refresh, color: bdwmPrimaryColor,),
              ),
              Expanded(
                child: TextField(
                  controller: contentController,
                  minLines: 1,
                  maxLines: 3,
                  readOnly: widget.withWho == "deliver" ? true : false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  var txt = contentController.text;
                  if (txt.isEmpty) {
                    return;
                  }
                  bdwmSendMessages(widget.withWho, txt)
                  .then((value) {
                    if (value.success == false) {
                      return;
                    }
                    if (!mounted) { return; }
                    update();
                  },);
                },
                child: const Text("发送"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}