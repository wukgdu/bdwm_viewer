import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

import './bdwm/message.dart';
import './bdwm/mail.dart';
import './utils.dart';
import './globalvars.dart';

class NotifyMessageInfo {
  List<UnreadMessageInfo> value = <UnreadMessageInfo>[];
  int count = 0;
  NotifyMessageInfo({required this.value, required this.count});
  NotifyMessageInfo.empty();
}

class NotifyMessage {
  var lastUnreadInfo = <String, int>{};
  List<UnreadMessageInfo> value = <UnreadMessageInfo>[];
  int count = 0;

  final pFromWorker = ReceivePort();
  late SendPort pToWorker;
  late Isolate worker;
  late StreamQueue<dynamic> events;
  Future<void> initWorker() async {
    worker = await Isolate.spawn(
      (List<dynamic> argv) { messageWorkerWork(argv[0], argv[1]); },
      [pFromWorker.sendPort, globalUInfo],
    );
    events = StreamQueue<dynamic>(pFromWorker);
    pToWorker = await events.next;
  }
  Future<List<UnreadMessageInfo>?> updateByWorker() async {
    pToWorker.send("");
    List<UnreadMessageInfo>? res = await events.next;
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
  void disposeWorker() async {
    pToWorker.send(null);
    await events.cancel();
  }

  bool notifyP(List<UnreadMessageInfo> value) {
    bool notifyIt = false;
    var nKey = Set<String>.from(value.map((e) => e.withWho));
    for (var e in value) {
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

  void updateValue(Function callBack) {
    // return;
    if (globalUInfo.login == false) { return; }
    // bdwmGetUnreadMessageCount().then((value) {
    updateByWorker().then((value) {
      if (value == null) {
        return;
      }
      this.value = value;
      int countSum = value.fold(0, (num0, a) {
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
    String content = value.map((e) {
      return "${e.withWho}: ${e.count}条";
    },).join(", ");
    if (content.length > 30) {
      content = content.substring(0, 30);
    }
    quickNotify("$count条消息", content);
  }
}

class NotifyMail {
  int lastUnreadTime = 0;
  UnreadMailInfo unreadMailInfo = UnreadMailInfo.empty();

  final pFromWorker = ReceivePort();
  late SendPort pToWorker;
  late Isolate worker;
  late StreamQueue<dynamic> events;
  Future<void> initWorker() async {
    worker = await Isolate.spawn(
      (List<dynamic> argv) { mailWorkerWork(argv[0], argv[1]); },
      [pFromWorker.sendPort, globalUInfo],
    );
    events = StreamQueue<dynamic>(pFromWorker);
    events = StreamQueue<dynamic>(pFromWorker);
    pToWorker = await events.next;
  }
  Future<UnreadMailInfo?> updateByWorker() async {
    pToWorker.send("");
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
  void disposeWorker() async {
    pToWorker.send(null);
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

  void updateValue(Function callBack) {
    // return;
    if (globalUInfo.login == false) { return; }
    // bdwmGetUnreadMailCount().then((value) {
    updateByWorker().then((value) {
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
    String title = "站内信 ${unreadMailInfo.count} 封未读";
    var newestItem = unreadMailInfo.unreadMailList.first;
    String content = "${newestItem.owner} ${newestItem.title} ${newestItem.content}";
    if (content.length > 40) {
      content = content.substring(0, 40);
    }
    quickNotify(title, content);
  }
}

class MessageBriefNotifier extends ValueNotifier<List<TextAndLink>> {
  String lastStr = "";
  MessageBriefNotifier(List<TextAndLink> value): super(value);

  String arr2Str(List<UnreadMessageInfo> uv) {
    if (uv.isEmpty) { return ""; }
    uv.sort((a, b) {
      return a.withWho.compareTo(b.withWho);
    },);
    return uv.map((e) => "${e.withWho}[${e.count}]").join(",");
  }

  void newArray(NotifyMessageInfo nmi) {
    String curStr = arr2Str(nmi.value);
    if (curStr == lastStr) {
      return;
    }
    lastStr = curStr;
    value.clear();
    for (var nsi in nmi.value) {
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