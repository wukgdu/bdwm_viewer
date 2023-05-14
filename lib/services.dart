import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

import './bdwm/message.dart';
import './bdwm/mail.dart';
import './utils.dart';
import './globalvars.dart';
import './notification.dart' show sendNotification;

class NotifyMessageInfo {
  UnreadMessageInfo value = UnreadMessageInfo.empty();
  int count = 0;
  NotifyMessageInfo({required this.value, required this.count});
  NotifyMessageInfo.empty();
}

class NotifyMessage {
  var lastUnreadInfo = <String, int>{};
  UnreadMessageInfo value = UnreadMessageInfo.empty();
  int count = 0;

  late ReceivePort pFromWorker;
  SendPort? pToWorker;
  late Isolate worker;
  late StreamQueue<dynamic> events;
  Future<void> reInitWorker() async {
    if (globalConfigInfo.getExtraThread() == false) { return; }
    // should call after initWork
    await disposeWorker();
    pToWorker = null;
    await initWorker();
  }
  Future<void> initWorker() async {
    if (globalConfigInfo.getExtraThread() == false) { return; }
    pFromWorker = ReceivePort();
    worker = await Isolate.spawn(
      (List<dynamic> argv) { messageWorkerWork(argv[0], argv[1]); },
      [pFromWorker.sendPort, globalUInfo],
    );
    events = StreamQueue<dynamic>(pFromWorker);
    pToWorker = await events.next;
  }
  Future<UnreadMessageInfo?> updateByWorker() async {
    if (pToWorker == null) { return null; }
    pToWorker!.send("");
    UnreadMessageInfo? res = await events.next;
    return res;
  }
  static Future<void> messageWorkerWork(SendPort p, Uinfo globalUInfo_) async {
    globalUInfo = globalUInfo_;
    final commandPort = ReceivePort();
    p.send(commandPort.sendPort);
    commandPort.listen((message) async {
      if (message == null) {
        Isolate.exit();
      }
      var res = await bdwmGetUnreadMessageCount();
      p.send(res);
    });
  }
  Future<void> disposeWorker() async {
    if (pToWorker == null) { return; }
    pToWorker!.send(null);
    pFromWorker.close();
    await events.cancel();
  }

  bool notifyP(UnreadMessageInfo value) {
    bool notifyIt = false;
    var nKey = Set<String>.from(value.unreadMessageItem.map((e) => e.withWho));
    for (var e in value.unreadMessageItem) {
      if (lastUnreadInfo.containsKey(e.withWho)) {
        var thatCount = lastUnreadInfo[e.withWho]!;
        if (e.count != thatCount) {
          lastUnreadInfo[e.withWho] = e.count;
          notifyIt = true;
        }
      } else {
        lastUnreadInfo[e.withWho] = e.count;
        notifyIt = true;
      }
    }
    for (var p in lastUnreadInfo.keys.toList()) {
      if (!nKey.contains(p)) {
        // lastUnreadInfo[p] = 0;
        lastUnreadInfo.remove(p);
      }
    }
    return notifyIt;
  }

  void clearOne(String withWho) {
    lastUnreadInfo.remove(withWho);
  }

  void clearAll() {
    lastUnreadInfo.clear();
  }

  Future<UnreadMessageInfo?> getData() async {
    if (globalConfigInfo.getExtraThread() == false) {
      return bdwmGetUnreadMessageCount();
    }
    return updateByWorker();
  }

  void updateValue(Function callBack) {
    // return;
    if (globalUInfo.login == false) { return; }
    // bdwmGetUnreadMessageCount().then((value) {
    getData().then((value) {
      if (value == null) {
        return;
      }
      this.value = value;
      int countSum = value.unreadMessageItem.fold(0, (num0, a) {
        return a.count + num0;
      });
      count = countSum;
      callBack(NotifyMessageInfo(value: value, count: count));
      notify();
      return;
    });
  }

  void notify() {
    if (count == 0) {
      return;
    }
    bool notifyIt = notifyP(value);
    if (!notifyIt) {
      return;
    }
    String content = value.unreadMessageItem.map((e) {
      return "${e.withWho}: ${e.count}条";
    },).join(", ");
    if (content.length > 30) {
      content = content.substring(0, 30);
    }
    sendNotification("${value.userName}：$count条消息", content, payload: "/message");
  }
}

class NotifyMail {
  int lastUnreadTime = 0;
  UnreadMailInfo unreadMailInfo = UnreadMailInfo.empty();

  late ReceivePort pFromWorker;
  SendPort? pToWorker;
  late Isolate worker;
  late StreamQueue<dynamic> events;
  Future<void> reInitWorker() async {
    if (globalConfigInfo.getExtraThread() == false) { return; }
    // should call after initWork
    await disposeWorker();
    pToWorker = null;
    await initWorker();
  }
  Future<void> initWorker() async {
    if (globalConfigInfo.getExtraThread() == false) { return; }
    pFromWorker = ReceivePort();
    worker = await Isolate.spawn(
      (List<dynamic> argv) { mailWorkerWork(argv[0], argv[1]); },
      [pFromWorker.sendPort, globalUInfo],
    );
    events = StreamQueue<dynamic>(pFromWorker);
    pToWorker = await events.next;
  }
  Future<UnreadMailInfo?> updateByWorker() async {
    if (pToWorker == null) { return null; }
    pToWorker!.send("");
    UnreadMailInfo? res = await events.next;
    return res;
  }
  static Future<void> mailWorkerWork(SendPort p, Uinfo globalUInfo_) async {
    globalUInfo = globalUInfo_;
    final commandPort = ReceivePort();
    p.send(commandPort.sendPort);
    commandPort.listen((message) async {
      if (message == null) {
        Isolate.exit();
      }
      var res = await bdwmGetUnreadMailCount();
      p.send(res);
    });
  }
  Future<void> disposeWorker() async {
    if (pToWorker == null) { return; }
    pToWorker!.send(null);
    pFromWorker.close();
    await events.cancel();
  }

  bool notifyP(UnreadMailInfo value) {
    bool notifyIt = false;
    for (var e in value.unreadMailList) {
      if (e.time > lastUnreadTime) {
        lastUnreadTime = e.time;
        notifyIt = true;
        break;
      }
    }
    return notifyIt;
  }

  Future<UnreadMailInfo?> getData() {
    if (globalConfigInfo.getExtraThread() == false) {
      return bdwmGetUnreadMailCount();
    }
    return updateByWorker();
  }

  void updateValue(Function callBack) {
    // return;
    if (globalUInfo.login == false) { return; }
    // bdwmGetUnreadMailCount().then((value) {
    getData().then((value) {
      if (value == null) {
        return;
      }
      if (value.success == false) {
        return;
      }
      unreadMailInfo = value;
      callBack(unreadMailInfo);
      notify();
    });
  }

  void clearAll() {
    lastUnreadTime = 0;
  }

  void notify() {
    if (unreadMailInfo.count == 0) {
      return;
    }
    bool notifyIt = notifyP(unreadMailInfo);
    if (!notifyIt) {
      return;
    }
    String title = "${unreadMailInfo.userName}：站内信 ${unreadMailInfo.count} 封未读";
    var newestItem = unreadMailInfo.unreadMailList.first;
    String content = "${newestItem.owner} ${newestItem.title} ${newestItem.content}";
    if (content.length > 40) {
      content = content.substring(0, 40);
    }
    sendNotification(title, content, payload: "/mail");
  }
}

class MessageBriefNotifier extends ValueNotifier<List<TextAndLink>> {
  String lastStr = "";
  MessageBriefNotifier(List<TextAndLink> value): super(value);

  String arr2Str(UnreadMessageInfo uv) {
    if (uv.unreadMessageItem.isEmpty) { return ""; }
    uv.unreadMessageItem.sort((a, b) {
      return a.withWho.compareTo(b.withWho);
    },);
    return uv.unreadMessageItem.map((e) => "${e.withWho}[${e.count}]").join(",");
  }

  void newArray(NotifyMessageInfo nmi) {
    String curStr = arr2Str(nmi.value);
    if (curStr == lastStr) {
      return;
    }
    lastStr = curStr;
    value.clear();
    for (var nsi in nmi.value.unreadMessageItem) {
      value.add(TextAndLink(nsi.withWho, nsi.count.toString()));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    value.clear();
    super.dispose();
  }
}