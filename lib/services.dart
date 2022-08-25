import './bdwm/message.dart';
import './utils.dart';

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
        if (e.count > thatCount) {
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

  void updateValue(Function callBack) {
    // return NotifyMessageInfo.empty();
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
    if (value == null) {
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
