import 'package:html/parser.dart' show parse;
// import 'package:csslib/parser.dart' as css_parser show parse;

import '../globalvars.dart';
import '../utils.dart';
import './utils.dart';
import './read_thread_parser.dart' show AttachmentInfo, AttachmentType;

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
  bool hasStar = false;
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
    required this.hasStar,
    required this.hasAttachment,
  });
}

class MailListInfo {
  int maxPage = 0;
  String? errorMessage;
  double capacity = 0.0;
  String sizeString = "";
  List<MailItemInfo> mailItems = [];

  MailListInfo.empty();
  MailListInfo.error({
    required this.errorMessage,
  });
  MailListInfo({
    required this.mailItems,
    this.errorMessage,
    required this.maxPage,
    required this.capacity,
    required this.sizeString,
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

  double capacity = 0.0;
  String sizeString = "";
  var capacityDom = document.querySelector(".top-right-capacity");
  var capDomStyleString = capacityDom?.querySelector("span.capacity")?.attributes['style'] ?? "width:0.0";
  var widthStyleRegExp = RegExp(r"\s*width\s*:\s*(-?[\d\.]+)(%?)");
  var match = widthStyleRegExp.firstMatch(capDomStyleString);
  capacity = double.parse(match?.group(1) ?? "0.0");
  bool hasPercent = match?.group(2) == "%";
  if (hasPercent) {
    capacity /= 100.0;
  }
  if (capacity < 0.0) {
    capacity = 0.0;
  }
  sizeString = getTrimmedString(capacityDom?.querySelector("span.size"));

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
    bool hasStar = mdom.querySelector(".star.active") != null;
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
    mailItems.add(MailItemInfo(
      title: title, content: content, time: time, userName: userName, nickName: nickName, avatar: avatar, unread: unread, id: id, uid: uid, hasAttachment: hasAttachment,
      hasStar: hasStar,
    ));
  }
  int maxPage = 0;
  var pagingDivsDom = document.querySelectorAll(".paging div");
  for (var pdd in pagingDivsDom) {
    var txt = getTrimmedString(pdd);
    if (txt.startsWith("/")) {
      maxPage = int.parse(txt.substring(2)); // <div>/ 2</div>
      break;
    }
  }
  return MailListInfo(mailItems: mailItems, maxPage: maxPage, capacity: capacity, sizeString: sizeString);
}

class MailDetailInfo {
  String user = "";
  String uid = "";
  String avatar = absImgSrc(defaultAvator);
  String title = "";
  String content = "";
  String signatureHtml = "";
  String time = "";
  String attachmentHtml = "";
  String userDescription = "";
  List<AttachmentInfo> attachmentInfo = <AttachmentInfo>[];
  String? errorMessage;

  MailDetailInfo.empty();
  MailDetailInfo.error({required this.errorMessage,});
  MailDetailInfo({
    required this.user,
    required this.uid,
    required this.avatar,
    required this.title,
    required this.content,
    required this.signatureHtml,
    required this.attachmentHtml,
    required this.attachmentInfo,
    required this.time,
    required this.userDescription,
    this.errorMessage,
  });
}

MailDetailInfo parseMailDetailInfo(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return MailDetailInfo.error(errorMessage: errorMessage);
  }
  var contentDom = document.querySelector(".mail-body");
  if (contentDom == null) {
    return MailDetailInfo.empty();
  }
  String title = "";
  String uid = "";
  String user = "";
  String userDescription = "";
  String avatar = absImgSrc(contentDom.querySelector("img.avatar")?.attributes['src'] ?? defaultAvator);
  var titleDom = contentDom.querySelector(".title");
  if (titleDom != null) {
    title = getTrimmedString(titleDom.children.first);
    uid = (titleDom.querySelector(".sender a")?.attributes['href'] ?? "").split("=").last;
    user = getTrimmedString(titleDom.querySelector(".sender a"));
    var tmpStr = titleDom.querySelector(".sender")?.text ?? "";
    userDescription = tmpStr.split("：")[0];
  }
  var content = getTrimmedHtml(contentDom.querySelector(".file-read"));
  var attachmentInfo = <AttachmentInfo>[];
  var attachmentDom = contentDom.querySelector(".attachment");
  var attachmentHtml = "";
  // int attachmentSlidesCount = 0;
  if (attachmentDom != null) {
    var attachmentsDom = attachmentDom.querySelectorAll("li");
    attachmentHtml = getTrimmedOuterHtml(attachmentDom.querySelector("ul"));
    for (var adom in attachmentsDom) {
      var a = adom.querySelector("a");
      if (a == null) {
        continue;
      }
      var name = getTrimmedString(a);
      var link = a.attributes['href']?.trim() ?? "";
      var size = getTrimmedString(adom.querySelector(".size"));
      var thumbnailLink = "";
      AttachmentType aType = AttachmentType.showText;
      if (a.classes.contains("highslide")) {
        aType = AttachmentType.showThumbnail;
        thumbnailLink = getTrimmedString(adom.querySelector("img")?.attributes['src']);
        name = getTrimmedString(adom.querySelector("img")?.attributes['alt']);
        // attachmentSlidesCount += 1;
      }
      attachmentInfo.add(AttachmentInfo(text: name, link: link, size: size, type: aType, thumbnailLink: thumbnailLink));
    }
  }
  var signatureHtml = getTrimmedHtml(contentDom.querySelector(".signature.file-read"));
  var time = getTrimmedString(contentDom.querySelector(".content .right"));
  return MailDetailInfo(
    user: user, uid: uid, avatar: avatar, title: title, content: content,
    attachmentHtml: attachmentHtml, attachmentInfo: attachmentInfo,
    time: time, signatureHtml: signatureHtml, userDescription: userDescription,
  );
}