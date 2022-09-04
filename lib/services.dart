import './bdwm/message.dart';
import './bdwm/mail.dart';
import './utils.dart';
import 'package:flutter/foundation.dart';

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

  bool notifyP(List<UnreadMessageInfo> value) {
    bool notifyIt = false;
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
    return notifyIt;
  }

  void clearOne(String withWho) {
    lastUnreadInfo.remove(withWho);
  }

  void updateValue(Function callBack) {
    // return;
    bdwmGetUnreadMessageCount().then((value) {
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
    bdwmGetUnreadMailCount().then((value) {
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
  MessageBriefNotifier(List<TextAndLink> value): super(value);

  void newArray(NotifyMessageInfo nmi) {
    value.clear();
    for (var nsi in nmi.value) {
      value.add(TextAndLink(nsi.withWho, nsi.count.toString()));
    }
    notifyListeners();
  }
}