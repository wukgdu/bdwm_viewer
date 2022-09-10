import 'package:html/parser.dart' show parse;

import '../globalvars.dart';
import '../utils.dart';
import './utils.dart';

class MailItemInfo {
  String title = "";
  String content = "";
  String time = "";
  String userName = "";
  String nickName = "";
  String avatar = "";
  String id = "";
  String uid = "";
  bool unread = false;
  bool hasAttachment = false;

  MailItemInfo.empty();
  MailItemInfo({
    required this.title,
    required this.content,
    required this.time,
    required this.userName,
    required this.nickName,
    required this.avatar,
    required this.unread,
    required this.id,
    required this.uid,
    required this.hasAttachment,
  });
}

class MailListInfo {
  int maxPage = 0;
  String? errorMessage;
  List<MailItemInfo> mailItems = [];

  MailListInfo.empty();
  MailListInfo.error({
    required this.errorMessage,
  });
  MailListInfo({
    required this.mailItems,
    this.errorMessage,
    required this.maxPage,
  });
}

MailListInfo parseMailList(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return MailListInfo.error(errorMessage: errorMessage);
  }
  var listDom = document.querySelector("#mail-list");
  if (listDom == null) {
    return MailListInfo.empty();
  }
  var mailItems = <MailItemInfo>[];
  for (var mdom in listDom.querySelectorAll(".list-item")) {
    var id = mdom.attributes['data-itemid'] ?? "";
    var mailDom = mdom.querySelector("span.mail");
    String uid = "";
    String avatar = "";
    var uDom = mdom.querySelector(".portrait");
    if (uDom != null) {
      uid = getQueryValue(uDom.attributes['href'] ?? "", "uid") ?? "";
      avatar = absImgSrc(uDom.querySelector("img.pic")?.attributes["src"] ?? defaultAvator);
    }
    String title = "";
    String content = "";
    bool hasAttachment = false;
    String userName = "";
    String nickName = "";
    String time = "";
    bool unread = false;
    if (mailDom != null) {
      title = getTrimmedString(mailDom.querySelector("div.title"));
      content = getTrimmedString(mailDom.querySelector("div.content"));
      var img = mailDom.querySelector("img");
      if (img!=null && (img.attributes['src'] ?? "").contains("topics/attach")) {
        hasAttachment = true;
      }
      var uinfoDom = mailDom.querySelector("div.from");
      if (uinfoDom != null) {
        userName = getTrimmedString(uinfoDom.querySelector("span.id"));
        nickName = getTrimmedString(uinfoDom.querySelector("span.nickname"));
        time = getTrimmedString(uinfoDom.querySelector("span.info .time"));
        if (uinfoDom.querySelector("span.info .unread")!=null) {
          unread = true;
        }
      }
    }
    mailItems.add(MailItemInfo(title: title, content: content, time: time, userName: userName, nickName: nickName, avatar: avatar, unread: unread, id: id, uid: uid, hasAttachment: hasAttachment));
  }
  int maxPage = 0;
  var pagingDivsDom = document.querySelectorAll(".paging div");
  for (var pdd in pagingDivsDom) {
    var txt = pdd.text;
    if (txt.startsWith("/")) {
      maxPage = int.parse(txt.substring(2)); // <div>/ 2</div>
      break;
    }
  }
  return MailListInfo(mailItems: mailItems, maxPage: maxPage);
}