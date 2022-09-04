import 'dart:convert';

import './req.dart';
import '../globalvars.dart';

class UnreadMessageInfo {
  String withWho = "";
  int count = 0;

  UnreadMessageInfo(this.withWho, this.count);
}

Future<List<UnreadMessageInfo>?> bdwmGetUnreadMessageCount() async {
  var actionUrl = "$v2Host/ajax/get_unread_message_counts.php";
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: {});
  if (resp == null) {
    return null;
  }
  var resContent = json.decode(resp.body);
  if (!resContent['success']) {
    return null;
  }
  var unreadMessageList = <UnreadMessageInfo>[];
  for (var element in resContent['result']) {
    unreadMessageList.add(UnreadMessageInfo(element['with'], element['count']));
  }
  // List<String> res = parseCookie(resp.headers['set-cookie'] ?? "");
  // if (res.isNotEmpty) {
  //   globalUInfo.setInfo(res[1], res[0], username);
  // }
  return unreadMessageList;
}
