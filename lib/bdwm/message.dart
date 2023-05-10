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
  return unreadMessageList;
}

class MessageItem {
  int id = 0;
  String withWho = "";
  int withuid = 0;
  int dir = 0;
  bool unread = true;
  int time = 0;
  String content = "";

  MessageItem({
    required this.id,
    required this.withWho,
    required this.withuid,
    required this.dir,
    required this.unread,
    required this.time,
    required this.content,
  });
  MessageItem.fromMap(Map element) {
    id = element['id'];
    withWho = element['with'];
    withuid = element['withuid'];
    dir = element['dir'];
    unread = element['unread'];
    time = element['time'];
    content = element['content'];
  }
}

class MessageInfo {
  bool success = true;
  int error = 0;
  String? desc;
  List<MessageItem> messages = <MessageItem>[];

  MessageInfo.empty();
  MessageInfo.error({
    required this.success,
    required this.error,
    this.desc,
  });
  MessageInfo({
    required this.success,
    required this.error,
    this.desc,
    required this.messages,
  });
}

Future<MessageInfo> bdwmGetMessages(String withWho, int count) async {
  var actionUrl = "$v2Host/ajax/get_messages.php";
  var data = {
    'with': withWho,
    'num': count.toString(),
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return MessageInfo.error(success: false, error: -1, desc: networkErrorText);
  }
  var resContent = json.decode(resp.body);
  if (resContent['success']==false) {
    return MessageInfo.empty();
  }
  var messages = <MessageItem>[];
  for (var element in resContent['result']) {
    messages.add(MessageItem.fromMap(element));
  }
  return MessageInfo(success: true, error: 0, messages: messages);
}

Future<bool> bdwmSetMessagesRead(String withWho) async {
  var actionUrl = "$v2Host/ajax/set_user_message_read.php";
  var data = {
    'with': withWho,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return false;
  }
  var resContent = json.decode(resp.body);
  if (resContent['success']==false) {
    return false;
  }
  return true;
}

class MessageSendRes {
  bool success = false;
  int error = 0;
  MessageItem? name;
  String? desc;
  MessageSendRes({
    required this.success,
    required this.name,
    required this.error,
  });
  MessageSendRes.error({
    required this.success,
    required this.error,
    required this.desc,
  });
}

Future<MessageSendRes> bdwmSendMessages(String withWho, String content) async {
  var actionUrl = "$v2Host/ajax/send_message.php";
  var data = {
    'user': withWho,
    'content': content,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return MessageSendRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var resContent = json.decode(resp.body);
  if (resContent['success']==false) {
    return MessageSendRes.error(success: false, error: resContent['error'] ?? 0, desc: null);
  }
  return MessageSendRes(
    success: true,
    error: resContent['error'] ?? 0,
    name: MessageItem.fromMap(resContent['name']),
  );
}
