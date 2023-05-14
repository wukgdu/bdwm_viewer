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
  String userName = "";
  List<UnreadMailItemSimple> unreadMailList = <UnreadMailItemSimple>[];

  UnreadMailInfo.empty();
  UnreadMailInfo({
    required this.success,
    required this.count,
    required this.unreadMailList,
    required this.userName,
  });
}

Future<UnreadMailInfo?> bdwmGetUnreadMailCount() async {
  var actionUrl = "$v2Host/ajax/get_new_mails.php";
  var userName = globalUInfo.username;
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: {});
  if (resp==null) {
    return null;
  }
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
  return UnreadMailInfo(success: resContent['success'], count: resContent['count'] ?? 0, unreadMailList: unreadMailList, userName: userName);
}

class MailRes {
  bool success = false;
  int error = 0;
  String? result;

  MailRes({
    required this.success,
    required this.error,
    this.result,
  });
  MailRes.error({
    required this.success,
    required this.error,
    this.result,
  });
}

Future<MailRes> bdwmGetMailQuote({required String postid, String mode="simple"}) async {
  var actionUrl = "$v2Host/ajax/get_mail_quote.php";
  var data = {
    "postid": postid,
    "mode": mode,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return MailRes.error(success: false, error: -1, result: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  MailRes mailRes = MailRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
    result: respContent['quote'],
  );
  return mailRes;
}

class MailSendRes {
  bool success = false;
  int error = 0;
  String? result;
  List<int> sent = [];


  MailSendRes({
    required this.success,
    required this.error,
    this.result,
    required this.sent,
  });
  MailSendRes.error({
    required this.success,
    required this.error,
    this.result,
  });
}

Future<MailSendRes> bdwmCreateMail({required String title, required String content, required String signature, String? bid, String? parentid, String? attachpath, required List<int> rcvuids}) async {
  var actionUrl = "$v2Host/ajax/create_mail.php";
  var data = {
    'rcvuids': jsonEncode(rcvuids),
    'title': title,
    'content': content,
    'postinfo': <String, dynamic>{},
    "attachpath": attachpath ?? "",
    "signature": signature,
  };
  if (parentid != null && bid == null) {
    (data['postinfo'] as Map)['parentid'] = int.parse(parentid);
  }
  data['postinfo'] = jsonEncode(data['postinfo']);
  // print(data['postinfo']);
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return MailSendRes.error(success: false, error: -1, result: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  var sent = <int>[];
  if (respContent['success']==true) {
    for (var s in respContent['sent']) {
      sent.add(s as int);
    }
  }
  MailSendRes res = MailSendRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
    sent: sent,
  );
  return res;
}

Future<MailRes> bdwmOperateMail({required String postid, required String action}) async {
  var actionUrl = "$v2Host/ajax/operate_mail.php";
  var data = {
    "list": '[$postid]',
    "action": action,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return MailRes.error(success: false, error: -1, result: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  MailRes res = MailRes(
    success: (respContent['success']==true) && (respContent['results'][0]==false),
    error: respContent['error'] ?? 0,
  );
  return res;
}
