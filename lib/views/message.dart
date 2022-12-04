import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';

import '../views/constants.dart';
import '../html_parser/board_parser.dart';
import '../pages/read_thread.dart';
import '../views/utils.dart';
import '../bdwm/message.dart';
import "../bdwm/search.dart";
import '../bdwm/req.dart';
import '../globalvars.dart';
import '../utils.dart';
import '../services_instance.dart';
import '../services.dart' show MessageBriefNotifier;
import '../router.dart' show nv2Push;

class UserJumpByNameComponent extends StatefulWidget {
  final String userName;
  final void Function(String uid)? callBack;
  const UserJumpByNameComponent({super.key, required this.userName, this.callBack});

  @override
  State<UserJumpByNameComponent> createState() => _UserJumpByNameComponentState();
}

class _UserJumpByNameComponentState extends State<UserJumpByNameComponent> {
  late CancelableOperation getDataCancelable;

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(bdwmUserInfoSearch([widget.userName]));
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  AlertDialog genDialog(Widget content) {
    return AlertDialog(
      title: const Text("查询用户中"),
      content: content,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              getDataCancelable.cancel();
              getDataCancelable = CancelableOperation.fromFuture(bdwmUserInfoSearch([widget.userName]));
            });
          },
          child: const Text("刷新"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return genDialog(
            const LinearProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return genDialog(
            Text("错误：${snapshot.error}"),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return genDialog(
            const Text("错误：未获取数据"),
          );
        }
        UserInfoRes userInfoRes = snapshot.data as UserInfoRes;
        if (userInfoRes.desc != null) {
          return genDialog(
            Text(userInfoRes.desc!),
          );
        }
        if (userInfoRes.success == false) {
          return genDialog(
            const Text("错误：获取用户数据失败"),
          );
        }
        if (userInfoRes.users.isEmpty || userInfoRes.users.first is bool) {
          return genDialog(
            const Text("错误：未获取数据"),
          );
        }
        var ian = userInfoRes.users.first as IDandName;
        if (widget.callBack != null) {
          widget.callBack!(ian.id);
        }
        return AlertDialog(
          title: const Text("查询完成"),
          content: Text("${ian.name}：${ian.id}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                nv2Push(context, '/user', arguments: ian.id);
              },
              child: const Text("前往"),
            ),
          ],
        );
      },
    );
  }
}

class MessageListPage extends StatefulWidget {
  final MessageBriefNotifier users;
  final String filterName;
  const MessageListPage({super.key, required this.users, required this.filterName});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  final _controller = ScrollController();
  Map<String, String> uName2ID = {};

  @override
  void dispose() {
    globalContactInfo.update(order: false);
    _controller.dispose();
    uName2ID.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.users,
      builder: (context, value, child) {
        var clist = globalContactInfo.contact.toList(growable: false);
        var users = (value as List<TextAndLink>).map((e) => TextAndLink(e.text, e.link)).toList();
        if (users.isNotEmpty) {
          globalContactInfo.memInsertMany(users.map((e) => e.text).toList());
          globalContactInfo.update(order: false);
        }
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
        Set<String> usersSet = Set.from(users.map((e) => e.text));
        // clist.sort();
        for (var u in clist) {
          if (!usersSet.contains(u)) {
            users.add(TextAndLink(u, "0"));
          }
        }
        if (widget.filterName.isNotEmpty) {
          users.removeWhere((element) => !element.text.toLowerCase().contains(widget.filterName));
        }
        return ListView.builder(
          controller: _controller,
          itemCount: users.length,
          itemBuilder: (context, index) {
            var e = users[index];
            return Card(
              child: ListTile(
                onTap: () {
                  globalContactInfo.memInsertOne(e.text);
                  setState(() { });
                  nv2Push(context, '/messagePerson', arguments: e.text);
                },
                onLongPress: () {
                  if (e.text == "deliver") { return; }
                  showConfirmDialog(context, "", "删除此对话？",).then((value) {
                    if (value!=null && value=="yes") {
                      globalContactInfo.removeOne(e.text).then((value) {
                        setState(() { });
                      });
                    }
                  },);
                },
                leading: GestureDetector(
                  onTap: () {
                    if (e.text == 'deliver') { return; }
                    if (uName2ID.containsKey(e.text)) {
                      nv2Push(context, '/user', arguments: uName2ID[e.text]);
                    } else {
                      showAlertDialog2(context, UserJumpByNameComponent(userName: e.text, callBack: (String uid) {
                        uName2ID[e.text] = uid;
                      },));
                    }
                  },
                  child: e.text == 'deliver'
                  ? Icon(Icons.person, color: bdwmPrimaryColor,)
                  : Icon(Icons.person_search, color: bdwmPrimaryColor,),
                ),
                title: Text(e.text),
                trailing: e.link!=null && e.link!="0"
                  ? Container(
                    alignment: Alignment.center,
                    width: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bdwmPrimaryColor,
                    ),
                    child: Text(int.parse(e.link!) > 9 ? "9+" : e.link!, style: const TextStyle(color: Colors.white)),
                  )
                  : null,
              ),
            );
          },
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
  final emojiKeyList = messageEmojis.keys.toList();

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

  TextSpan genContentTextSpan(String rawContent) {
    if (!globalConfigInfo.getUseImgInMessage()) {
      return TextSpan(text: replaceWithEmoji(rawContent));
    }
    String tmpK = UniqueKey().toString();
    String tmpK2 = UniqueKey().toString();
    var newContent = rawContent;
    for (int i=0; i<emojiKeyList.length; i+=1) {
      var emojiText = emojiKeyList[i];
      newContent = newContent.replaceAll(emojiText, "$tmpK$tmpK2-${i+1}-$emojiText$tmpK");
    }
    List<String> stringChildren = newContent.split(tmpK);
    return TextSpan(
      children: stringChildren.map((e) {
        if (e.startsWith(tmpK2)) {
          var arr = e.split('-');
          String emojiIdx = arr[1];
          return WidgetSpan(child: Image.network("$v2Host/images/emoji/Expression_$emojiIdx.png", height: Theme.of(context).textTheme.bodyText2?.fontSize ?? 16,));
        }
        return TextSpan(text: e);
      },).toList(),
    );
  }
  String replaceWithEmoji(String rawContent) {
    var newContent = rawContent;
    for (var emojiText in messageEmojis.keys) {
      var emoji = messageEmojis[emojiText];
      if (emoji == null) { continue; }
      if (emoji.isEmpty) { continue; }
      newContent = newContent.replaceAll(emojiText, emoji);
    }
    return newContent;
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
                  genContentTextSpan(rawContent),
                  if (link.isNotEmpty)
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          if (link.startsWith("https://bbs.pku.edu.cn/v2/user.php")) {
                            var uid = link.split("=").last;
                            nv2Push(context, "/user", arguments: uid);
                          } else if (link.startsWith("https://bbs.pku.edu.cn/v2/post-read-single.php")) {
                            bdwmClient.get(link, headers: genHeaders2()).then((value) {
                              if (value == null) {
                                showNetWorkDialog(context);
                              } else {
                                var link2 = directToThread(value.body, needLink: true);
                                if (link2.isEmpty) { return; }
                                int? link2Int = int.tryParse(link2);
                                if (link2Int == null && link2.startsWith("post-read.php")==false) {
                                  if (!mounted) { return; }
                                  showAlertDialog(context, "跳转失败", Text(link2),
                                    actions1: TextButton(
                                      onPressed: () { Navigator.of(context).pop(); },
                                      child: const Text("知道了"),
                                    ),
                                  );
                                }
                                if (!mounted) { return; }
                                naviGotoThreadByLink(context, link2, "", pageDefault: "a", needToBoard: true);
                              }
                            });
                          }
                        },
                        child: const Text("[点击查看]", style: textLinkStyle),
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
              return ListView.builder(
                reverse: true,
                controller: _controller,
                itemCount: messageinfo.messages.length,
                itemBuilder: ((context, index) {
                  return oneItem(messageinfo.messages[index]);
                }),
              );
            }
          )
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 5, top: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  update();
                },
                icon: Icon(Icons.refresh, color: bdwmPrimaryColor,),
              ),
              Expanded(
                child: TextField(
                  controller: contentController,
                  minLines: 1,
                  maxLines: 3,
                  readOnly: widget.withWho == "deliver" ? true : false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8.0),
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