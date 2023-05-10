import 'package:flutter/material.dart';

import '../globalvars.dart' show globalUInfo, accountChinese, guestUitem, Uitem;
import './utils.dart' show showConfirmDialog;
import '../bdwm/logout.dart' show bdwmLogout;
import '../router.dart' show nv2RawPush;

Future<void> processSwitchUsersDialog(String? res, {void Function(String?)? refresh}) async {
  if (res == null) { return; }
  if (res == "") {
    nv2RawPush('/login', arguments: {
      "needBack": true,
    });
    return;
  }
  await globalUInfo.switchByUid(res);
  if (refresh!=null) {
    refresh(res);
  }
}

class SwitchUsersComponent extends StatefulWidget {
  final bool showLogin;
  final void Function(String?)? refresh;
  const SwitchUsersComponent({super.key, this.showLogin=false, this.refresh});

  @override
  State<SwitchUsersComponent> createState() => _SwitchUsersComponentState();
}

class _SwitchUsersComponentState extends State<SwitchUsersComponent> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        var res = await showSwitchUsersDialog(context, showLogin: widget.showLogin);
        if (!mounted) { return; }
        await processSwitchUsersDialog(res, refresh: widget.refresh);
        if (widget.refresh == null) {
          setState(() { });
        }
      },
      child: Text.rich(TextSpan(children: [
        const WidgetSpan(child: Icon(Icons.switch_account), alignment: PlaceholderAlignment.middle),
        const TextSpan(text: " "),
        TextSpan(text: globalUInfo.username),
      ])),
    );
  }
}

class SwitchUsersDialogContent extends StatefulWidget {
  const SwitchUsersDialogContent({super.key});

  @override
  State<SwitchUsersDialogContent> createState() => _SwitchUsersDialogContentState();
}

class _SwitchUsersDialogContentState extends State<SwitchUsersDialogContent> {
  List<Uitem> users = [];

  void genUsers() {
    users = [...globalUInfo.users];
    if (!globalUInfo.containsGuest()) {
      users.add(guestUitem);
    }
  }

  @override
  void initState() {
    super.initState();
    genUsers();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: users.map((e) {
          return ListTile(
            title: Text(e.briefInfo()),
            onTap: () {
              Navigator.of(context).pop(e.uid);
            },
            trailing: IconButton(
              onPressed: () async {
                var yes = await showConfirmDialog(context, "移除该$accountChinese的登录", "退出登录并移除");
                if (yes != "yes") { return; }
                if (e.username == guestUitem.username) {
                  await globalUInfo.removeUser(guestUitem.uid, guestUitem.username, save: true, force: true, updateP: true);
                } else {
                  await bdwmLogout(skey: e.skey, uid: e.uid);
                }
                genUsers();
                setState(() { });
              },
              icon: const Icon(Icons.remove),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Future<String?> showSwitchUsersDialog(BuildContext context, {bool showLogin=false}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("切换$accountChinese"),
        content: const SwitchUsersDialogContent(),
        actions: [
          TextButton(
            onPressed: () { Navigator.of(context).pop(); },
            child: const Text("取消"),
          ),
          if (showLogin == true) ...[
            TextButton(
              onPressed: globalUInfo.isFull() ? null : () { Navigator.of(context).pop(""); },
              child: const Text("去登录新$accountChinese"),
            ),
          ],
        ],
      );
    },
  );
}
