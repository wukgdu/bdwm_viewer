import 'dart:convert';

import './req.dart';
import '../globalvars.dart';

class UnreadMailItemSimple {
  String owner = "";
  int uid = 0;
  String title = "";
  String content = "";
  String filename = "";
  int time = 0;

  UnreadMailItemSimple({
    required this.owner,
    required this.uid,
    required this.title,
    required this.content,
    required this.filename,
    required this.time,
  });
}

class UnreadMailInfo {
  bool success = true;
  int count = 0;
  List<UnreadMailItemSimple> unreadMailList = <UnreadMailItemSimple>[];

  UnreadMailInfo.empty();
  UnreadMailInfo({
    required this.success,
    required this.count,
    required this.unreadMailList,
  });
}

Future<UnreadMailInfo?> bdwmGetUnreadMailCount() async {
  var actionUrl = "$v2Host/ajax/get_new_mails.php";
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: {});
  var resContent = json.decode(resp.body);
  if (!resContent['success']) {
    return null;
  }
  var unreadMailList = <UnreadMailItemSimple>[];
  for (var element in resContent['newest']) {
    unreadMailList.add(UnreadMailItemSimple(
      owner: element['owner'],
      uid: element['ownuid'],
      title: element['title'],
      content: element['content'],
      time: element['time'],
      filename: element['filename'],
    ));
  }
  // List<String> res = parseCookie(resp.headers['set-cookie'] ?? "");
  // if (res.isNotEmpty) {
  //   globalUInfo.setInfo(res[1], res[0], username);
  // }
  return UnreadMailInfo(success: resContent['success'], count: resContent['count'] ?? 0, unreadMailList: unreadMailList);
}
