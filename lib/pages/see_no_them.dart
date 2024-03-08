import 'package:flutter/material.dart';

import '../views/see_no_them.dart';
import '../views/utils.dart';
import '../bdwm/search.dart';
import '../globalvars.dart' show globalImmConfigInfo;

class SeeNoThemPage extends StatefulWidget {
  const SeeNoThemPage({super.key});

  @override
  State<SeeNoThemPage> createState() => SeeNoThemPageState();

  static SeeNoThemPageState? of(BuildContext context) {
    return context.findRootAncestorStateOfType<SeeNoThemPageState>();
  }
}

class SeeNoThemPageState extends State<SeeNoThemPage> {
  late List<String> seeNoThemList;

  @override
  void initState() {
    super.initState();
    seeNoThemList = globalImmConfigInfo.getSeeNoThem().toList();
    seeNoThemList.sort();
  }
  void updateData() {
    seeNoThemList = globalImmConfigInfo.getSeeNoThem().toList();
    seeNoThemList.sort();
    if (!mounted) { return; }
    setState(() { });
  }

  void removeOne(String userName) async {
    await globalImmConfigInfo.removeOneSeeNo(userName.toLowerCase());
    updateData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("不看ta"),
        actions: [
          IconButton(
            onPressed: () async {
              var userNew = await showTextDialog(context, "添加");
              if (userNew == null) {
                return;
              }
              userNew = userNew.trim();
              var userRes = await bdwmUserInfoSearch([userNew]);
              if (userRes.success == false) {
                if (!context.mounted) { return; }
                await showAlertDialog(context, "添加失败", const Text("查找用户失败"),
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
                    if (!context.mounted) { return; }
                    var res = await showAlertDialog(context, "添加失败", Text("用户 $userNew 不存在"),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop("add"); },
                        child: const Text("仍要添加"),
                      ),
                      actions2: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      ),
                    );
                    if (res == null) { return; }
                  }
                }
              }
              userNew = userNew.toLowerCase();
              var seeNoThemSet = globalImmConfigInfo.getSeeNoThem();
              if (seeNoThemSet.contains(userNew)) {
                return;
              }
              // widget.callBack(userNew);
              globalImmConfigInfo.addOneSeeNo(userNew).then((value) {
                updateData();
              },);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SeeNoThemView(seeNoThemList: seeNoThemList, removeOne: (String userName) { removeOne(userName); },),
    );
  }
}