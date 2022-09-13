import 'package:flutter/material.dart';

import '../views/message.dart';
import '../services.dart' show MessageBriefNotifier, NotifyMessage;
import '../views/utils.dart';
import '../bdwm/search.dart';

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

class MessagePersonApp extends StatelessWidget {
  final String userName;
  final NotifyMessage notifier;
  const MessagePersonApp({super.key, required this.userName, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),
      body: MessagePersonPage(withWho: userName, notifier: notifier,),
    );
  }
}