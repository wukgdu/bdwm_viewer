import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart' show UrlElement, LinkifyOptions, LinkifySpan;

import '../views/constants.dart';
import '../views/utils.dart';
import '../bdwm/message.dart';
import "../bdwm/search.dart";
import '../globalvars.dart';
import '../utils.dart';
import '../services_instance.dart';
import '../router.dart' show nv2Push;
import './html_widget.dart' show SimpleCachedImage, innerLinkJump;

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
            const Text("错误：用户不存在"),
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

class MessageListView extends StatefulWidget {
  final String filterName;
  const MessageListView({super.key, required this.filterName});

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
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
      valueListenable: messageBrief,
      builder: (context, value, child) {
        var clist = globalContactInfo.contact.toList(growable: false);
        var users = value.map((e) => TextAndLink(e.text, e.link)).toList();
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
                  showConfirmDialog(context, "删除此对话？", e.text,).then((value) {
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

class MessagePersonView extends StatefulWidget {
  final String withWho;
  final int count;
  const MessagePersonView({super.key, required this.withWho, this.count=50});

  @override
  State<MessagePersonView> createState() => _MessagePersonViewState();
}

class _MessagePersonViewState extends State<MessagePersonView> {
  late CancelableOperation getDataCancelable;
  final ScrollController _controller = ScrollController();
  TextEditingController contentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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
    _focusNode.addListener(afterFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // _controller.jumpTo(_controller.position.maxScrollExtent);
      var res = await bdwmSetMessagesRead(widget.withWho);
      if (res == true) {
        unreadMessage.clearOne(widget.withWho);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MessagePersonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    update();
  }

  @override
  void dispose() {
    _controller.dispose();
    contentController.dispose();
    _focusNode.removeListener(afterFocus);
    _focusNode.dispose();
    Future.microtask(() => getDataCancelable.cancel(),);
    super.dispose();
  }

  void afterFocus() {
    if (_focusNode.hasFocus) {
      _controller.animateTo(0.0, duration: const Duration(milliseconds: 1000), curve: Curves.ease);
    }
  }

  void update() {
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      },);
    });
  }

  bool isDeliver() {
    return widget.withWho == "deliver";
  }

  LinkifySpan genLinkify(String text) {
    return LinkifySpan(
      onOpen: (link) {
        if (link is UrlElement) {
          innerLinkJump(link.url, context);
        }
      },
      text: text,
      linkStyle: TextStyle(color: bdwmPrimaryColor, decoration: TextDecoration.none),
      options: const LinkifyOptions(humanize: false),
    );
  }

  TextSpan genContentTextSpan(String rawContent) {
    if (!globalConfigInfo.getUseImgInMessage()) {
      // return TextSpan(text: replaceWithEmoji(rawContent));
      return genLinkify(replaceWithEmoji(rawContent));
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
          return WidgetSpan(child: SimpleCachedImage(imgLink: "$v2Host/images/emoji/Expression_$emojiIdx.png", height: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16,));
        }
        return genLinkify(e);
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
      child: Container(
        margin: const EdgeInsets.all(2.5),
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
                if (link.isNotEmpty) ...[
                  // const TextSpan(text: "\n"),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () {
                        innerLinkJump(link, context);
                      },
                      child: const Text("[点击查看]", style: textLinkStyle),
                    ),
                  ),
                ],
              ]
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
              return GestureDetector(
                onTap: () {
                  _focusNode.unfocus();
                },
                child: ListView.builder(
                  key: PageStorageKey(widget.withWho),
                  reverse: true,
                  controller: _controller,
                  itemCount: messageinfo.messages.length,
                  itemBuilder: ((context, index) {
                    return oneItem(messageinfo.messages[index]);
                  }),
                ),
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
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 3,
                  readOnly: isDeliver() ? true : false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8.0),
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  color: bdwmPrimaryColor,
                  disabledColor: Colors.grey,
                  onPressed: isDeliver() ? null : () async {
                    if (!contentController.selection.isValid) {
                      contentController.selection = const TextSelection(
                        baseOffset: 0,
                        extentOffset: 0,
                      );
                    }
                    var emojiIdx = await showModalBottomSheet<int?>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (context1) {
                        return SafeArea(child: Wrap(
                          children: [
                            for (int i=0; i<emojiKeyList.length; i+=1) ...[
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop(i);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: SimpleCachedImage(imgLink: "$v2Host/images/emoji/Expression_${i+1}.png", height: 32,)
                                )
                              ),
                            ],
                          ],
                        ),);
                      },
                    );
                    if (emojiIdx == null) { return; }
                    var curIdx = contentController.selection.base.offset;
                    var curText = contentController.text;
                    contentController.text = "${curText.substring(0, curIdx)}${emojiKeyList[emojiIdx]}${curText.substring(curIdx)}";
                    contentController.selection = TextSelection(
                      baseOffset: curIdx + emojiKeyList[emojiIdx].length,
                      extentOffset: curIdx + emojiKeyList[emojiIdx].length,
                    );
                  },
                  icon: const Icon(Icons.emoji_emotions, size: 16),
                ),
              ),
              TextButton(
                onPressed: isDeliver() ? null : () {
                  var txt = contentController.text;
                  if (txt.isEmpty) {
                    return;
                  }
                  bdwmSendMessages(widget.withWho, txt)
                  .then((value) {
                    if (value.success == false) {
                      var errStr = value.desc ?? "错误代码：${value.error}";
                      showInformDialog(context, "发送失败", errStr);
                      return;
                    }
                    if (!mounted) { return; }
                    contentController.clear();
                    update();
                  },);
                },
                child: const Text("发送", style: TextStyle(fontSize: 16),),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
