import 'package:flutter/material.dart';

import '../views/message.dart';
import '../services.dart' show MessageBriefNotifier;
import '../views/utils.dart';
import '../bdwm/search.dart';
import '../services_instance.dart';
import '../globalvars.dart' show globalContactInfo, globalUInfo;

class MessagelistApp extends StatefulWidget {
  final MessageBriefNotifier brief;
  const MessagelistApp({Key? key, required this.brief}) : super(key: key);

  @override
  State<MessagelistApp> createState() => _MessagelistAppState();
}

class _MessagelistAppState extends State<MessagelistApp> {
  // Set<String> extraUsers = {};
  @override
  void initState() {
    super.initState();
    // extraUsers = globalContactInfo.contact;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("消息"),
        actions: [
          IconButton(
            onPressed: () async {
              var value = await showConfirmDialog(context, "强制提醒", "清空消息提醒数据，下次查询时提醒所有新旧未读消息");
              if (value == null) { return; }
              if (value != "yes") { return; }
              unreadMessage.clearAll();
            },
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () async {
              var userNew = await showTextDialog(context, "添加对话");
              if (userNew == null) {
                return;
              }
              userNew = userNew.trim();
              if (userNew.toLowerCase() == globalUInfo.username.toLowerCase()) {
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
                  userNew = (r as IDandName).name;
                  break;
                }
              }
              if (userNew == null) { return; }
              // widget.callBack(userNew);
              globalContactInfo.addOne(userNew).then((value) {
                setState(() { });
              },);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: MessageListPage(users: widget.brief),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
      ),
      body: MessagePersonPage(withWho: widget.userName),
    );
  }
}
