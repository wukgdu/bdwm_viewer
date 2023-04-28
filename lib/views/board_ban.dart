import 'package:bdwm_viewer/views/utils.dart';
import 'package:flutter/material.dart';

import '../bdwm/admin_board.dart';
import '../html_parser/board_ban_parser.dart' show BoardBanInfo;
import './board.dart' show getOptOptions, SimpleTuple2;
import './read_thread.dart' show BanUserDialog;

class BoardBanView extends StatefulWidget {
  final String bid;
  final BoardBanInfo boardBanInfo;
  final Function refresh;
  const BoardBanView({super.key, required this.bid, required this.boardBanInfo, required this.refresh});

  @override
  State<BoardBanView> createState() => _BoardBanViewState();
}

class _BoardBanViewState extends State<BoardBanView> {
  TextEditingController userNameValue = TextEditingController();
  TextEditingController dayValue = TextEditingController();
  TextEditingController reasonValue = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    userNameValue.dispose();
    dayValue.dispose();
    reasonValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.boardBanInfo.banItems.length,
      itemBuilder: (context, index) {
        var e = widget.boardBanInfo.banItems[index];
        return Card(child: ListTile(
          onTap: () async {
            var opt = await getOptOptions(context, [
              SimpleTuple2(name: "修改", action: "edit"),
              SimpleTuple2(name: "解封", action: "delete"),
            ]);
            if (opt == null) { return; }
            if (opt == "delete") {
              var optRes = await bdwmAdminBoardBanUser(bid: widget.bid, action: opt, day: 0, reason: "", userName: e.userName, uid: e.uid);
              if (!mounted) { return; }
              if (optRes.success) {
                await showInformDialog(context, "解封成功", "rt");
                widget.refresh();
              } else {
                showInformDialog(context, "解封失败", optRes.errorMessage ?? "解封失败，请稍后重试");
              }
            } else if (opt == "edit") {
              if (!mounted) { return; }
              var result = await showAlertDialog2(context, BanUserDialog(
                boardName: widget.boardBanInfo.boardName, bid: widget.bid, userName: e.userName, postid: null, uid: e.uid,
                reason: e.reason, showPostid: false, isEdit: true,
              ));
              if (result == "success") {
                widget.refresh();
              }
            }
          },
          title: Text("${e.userName} (uid: ${e.uid})"),
          subtitle: Text.rich(TextSpan(children: [
            TextSpan(text: "结束时间：${e.endTime}"),
            const TextSpan(text: "\n"),
            TextSpan(text: "禁言原因：${e.reason}"),
          ])),
          isThreeLine: true,
        ));
      },
    );
  }
}
