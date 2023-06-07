import 'package:flutter/material.dart';

import '../views/message.dart';
import '../views/utils.dart';
import '../bdwm/search.dart';
import '../services_instance.dart' show unreadMessage;
import '../views/constants.dart' show bdwmPrimaryColor;
import '../globalvars.dart' show globalContactInfo, globalUInfo, globalConfigInfo;

class MessagelistPage extends StatefulWidget {
  const MessagelistPage({Key? key}) : super(key: key);

  @override
  State<MessagelistPage> createState() => _MessagelistPageState();
}

class _MessagelistPageState extends State<MessagelistPage> {
  TextEditingController contentController = TextEditingController();
  String filterName = "";
  // Set<String> extraUsers = {};
  @override
  void initState() {
    super.initState();
    // extraUsers = globalContactInfo.contact;
    filterName = "";
  }
  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(5.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(5.0),
                      hintText: "筛选对话",
                    ),
                    onChanged: (value) {
                      var newName = value.trim().toLowerCase();
                      if (newName == filterName) {
                        return;
                      }
                      filterName = newName;
                      setState(() { });
                    },
                  ),
                ),
                IconButton(
                  color: bdwmPrimaryColor,
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    contentController.clear();
                    if (filterName.isEmpty) { return; }
                    filterName = "";
                    setState(() { });
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            )
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: MessageListView(filterName: filterName),
            ),
          ),
        ],
      )
    );
  }
}

class MessagePersonPage extends StatefulWidget {
  final String userName;
  const MessagePersonPage({super.key, required this.userName});

  @override
  State<MessagePersonPage> createState() => _MessagePersonPageState();
}

class _MessagePersonPageState extends State<MessagePersonPage> {
  int count = 50;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        actions: [
          TextButton(
            onPressed: () {
              if (count < 300) {
                setState(() {
                  count += 50;
                });
              }
            },
            child: Text("$count", style: TextStyle(color: globalConfigInfo.getUseMD3() ? null : Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white)),
          ),
        ],
      ),
      body: MessagePersonView(withWho: widget.userName, count: count,),
    );
  }
}
