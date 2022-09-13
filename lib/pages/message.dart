import 'package:flutter/material.dart';

import '../views/message.dart';
import '../services.dart' show MessageBriefNotifier;
import '../views/utils.dart';
import '../bdwm/search.dart';
import '../bdwm/message.dart';
import '../views/constants.dart';

class MessagelistApp extends StatefulWidget {
  final MessageBriefNotifier brief;
  final Set<String> extraUsers;
  final Function callBack;
  const MessagelistApp({Key? key, required this.brief, required this.extraUsers, required this.callBack}) : super(key: key);

  @override
  State<MessagelistApp> createState() => _MessagelistAppState();
}

class _MessagelistAppState extends State<MessagelistApp> {
  Set<String> extraUsers = {};
  @override
  void initState() {
    super.initState();
    extraUsers = widget.extraUsers;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("消息"),
        actions: [
          IconButton(
            onPressed: () async {
              var userNew = await showTextDialog(context, "添加对话");
              if (userNew == null) {
                return;
              }
              var userRes = await bdwmUserInfoSearch([userNew]);
              if (userRes.success == false) {
                if (!mounted) { return; }
                await showAlertDialog(context, "添加对话失败", const Text("查找用户失败"),
                  actions1: TextButton(
                    onPressed: () { Navigator.of(context).pop(); },
                    child: const Text("知道了"),
                  ),
                );
                return;
              } else {
                for (var r in userRes.users) {
                  // only one result
                  if (r == false) {
                    if (!mounted) { return; }
                    await showAlertDialog(context, "添加对话失败", Text("用户 $userNew 不存在"),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      ),
                    );
                    return;
                  }
                }
              }
              if (extraUsers.contains(userNew)) {
                return;
              }
              widget.callBack(userNew);
              extraUsers.add(userNew);
              setState(() {
              });
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: MessageListPage(users: widget.brief, extraUsers: extraUsers,),
    );
  }
}

class MessagePersonApp extends StatefulWidget {
  final String userName;
  const MessagePersonApp({super.key, required this.userName});

  @override
  State<MessagePersonApp> createState() => _MessagePersonAppState();
}

class _MessagePersonAppState extends State<MessagePersonApp> {
  TextEditingController contentController = TextEditingController();
  var childKey = GlobalKey<MessagePersonPageState>();

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
      ),
      body: MessagePersonPage(withWho: widget.userName, key: childKey),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        // color: Colors.blue,
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                var curState = childKey.currentState;
                if (curState == null) { return; }
                curState.update();
              },
              icon: const Icon(Icons.refresh, color: bdwmPrimaryColor,),
            ),
            Expanded(
              child: TextField(
                controller: contentController,
                minLines: 1,
                maxLines: 3,
                readOnly: widget.userName == "deliver" ? true : false,
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
                bdwmSendMessages(widget.userName, txt)
                .then((value) {
                  if (value.success == false) {
                    return;
                  }
                  if (!mounted) { return; }
                  var curState = childKey.currentState;
                  if (curState == null) { return; }
                  curState.update();
                },);
              },
              child: const Text("发送"),
            ),
          ],
        ),
      ),
    );
  }
}
