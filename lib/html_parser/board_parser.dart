import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import '../globalvars.dart';
import './utils.dart';

class BoardPostInfo {
  String bpID = "";
  bool isNew = false;
  String title = "";
  String link = "";
  String itemid = "";
  String userName = "";
  String uid = "";
  String avatarLink = "";
  String pTime = "";
  String commentCount = "";
  String lastUser = "";
  String lastTime = "";
  bool lock = false;
  bool hasAttachment = false;
  bool isBaoLiu = false;
  bool isWenZhai = false;
  bool isJingHua = false;
  bool isZhiDing = false;
  bool isYuanChuang = false;
  bool isGaoLiang = false;

  BoardPostInfo.empty();
  BoardPostInfo({
    required this.bpID,
    required this.isNew,
    required this.title,
    required this.link,
    required this.itemid,
    required this.userName,
    required this.uid,
    required this.avatarLink,
    required this.pTime,
    required this.commentCount,
    required this.lastUser,
    required this.lastTime,
    required this.lock,
    required this.hasAttachment,
    required this.isBaoLiu,
    required this.isWenZhai,
    required this.isJingHua,
    required this.isZhiDing,
    required this.isYuanChuang,
    required this.isGaoLiang,
  });
}

class AdminInfo {
  String userName = "";
  String uid = "";
  String link = "";

  AdminInfo.empyt();
  AdminInfo({
    required this.userName,
    required this.uid,
    required this.link,
  });
}

class BoardInfo {
  String bid = "";
  String boardName = "";
  String engName = "";
  String onlineCount = "";
  String todayCount = "";
  String topicCount = "";
  String postCount = "";
  String likeCount = "0";
  String ycfCount = "";
  String intro = "";
  bool canEditIntro = false;
  bool canOpt = false;
  int pageNum = 0;
  bool iLike = false;
  List<AdminInfo> admins = <AdminInfo>[];
  List<BoardPostInfo> boardPostInfo = <BoardPostInfo>[];
  String collectionLink = "";
  String? errorMessage;

  BoardInfo.empty();
  BoardInfo.error({this.errorMessage});
  BoardInfo({
    required this.bid,
    required this.boardName,
    required this.engName,
    required this.onlineCount,
    required this.todayCount,
    required this.topicCount,
    required this.postCount,
    required this.likeCount,
    required this.iLike,
    required this.intro,
    required this.pageNum,
    required this.admins,
    required this.boardPostInfo,
    required this.ycfCount,
    required this.canEditIntro,
    required this.canOpt,
    this.errorMessage,
    required this.collectionLink,
  });
}

List<BoardPostInfo> parseBoardPost(Element? docu) {
  List<BoardPostInfo> boardPostInfo = <BoardPostInfo>[];
  if (docu==null) {
    return boardPostInfo;
  }
  var postsDom = docu.querySelectorAll(".list-item");
  for (var pdom in postsDom) {
    String bpID = getTrimmedString(pdom.querySelector(".id"));
    if (bpID == "-1") {
      continue;
    }
    var pid = int.tryParse(bpID);
    if (pid != null && pid < 0) {
      continue;
    }
    bool isNew = false;
    if (pdom.querySelector(".dot.unread") != null) {
      isNew = true;
    }
    var titleCont = pdom.querySelector(".title-cont");
    bool lock = false;
    bool hasAttachment = false;
    bool isBaoLiu = false, isWenZhai = false, isJingHua = false;
    bool isZhiDing = false, isYuanChuang = false, isGaoLiang = false;

    String title = getTrimmedString(titleCont);
    if (titleCont != null) {
      if (titleCont.classes.contains("gl")) {
        isGaoLiang = true;
      }
      for (var idom in titleCont.querySelectorAll("img")) {
        var src = idom.attributes['src'] ?? "";
        if (src.contains("topics/lock")) {
          lock = true;
        } else if (src.contains("topics/attach")) {
          hasAttachment = true;
        } else if (src.contains("topics/wz")) {
          isWenZhai = true;
        } else if (src.contains("topics/diamond")) {
          isJingHua = true;
        } else if (src.contains("topics/bl")) {
          isBaoLiu = true;
        } else if (src.contains("topics/yc")) {
          isYuanChuang = true;
        } else if (src.contains("topics/zd")) {
          isZhiDing = true;
        }
      }
    }
    String link = absThreadLink(pdom.querySelector(".link")?.attributes['href'] ?? "");
    String itemid = pdom.attributes['data-itemid']?.trim() ?? "";
    // var tid = int.tryParse(itemid);
    // if (tid == null || tid < 0) {
    //   continue;
    // }
    String userName = getTrimmedString(pdom.querySelector(".author .name"));
    String avatarLink = absImgSrc(pdom.querySelector(".avatar img")?.attributes['src'] ?? defaultAvator);
    String uid = getTrimmedString(pdom.querySelector(".author a")?.attributes['href']?.split("=").last ?? "");
    String pTime = getTrimmedString(pdom.querySelector(".author .time"));
    String commentCount = getTrimmedString(pdom.querySelector(".reply-num"));
    var authorsDom = pdom.querySelectorAll(".author");
    String lastUser = "";
    String lastTime = "";
    if (authorsDom.length > 1) {
      var author2 = authorsDom[1];
      lastUser = getTrimmedString(author2.querySelector(".author .name"));
      lastTime = getTrimmedString(author2.querySelector(".author .time"));
    }
    boardPostInfo.add(BoardPostInfo(
      bpID: bpID, isNew: isNew, title: title, link: link, itemid: itemid,
      userName: userName, avatarLink: avatarLink, pTime: pTime, uid: uid, hasAttachment: hasAttachment,
      commentCount: commentCount, lastUser: lastUser, lastTime: lastTime, lock: lock,
      isBaoLiu: isBaoLiu, isWenZhai: isWenZhai, isJingHua: isJingHua,
      isZhiDing: isZhiDing, isYuanChuang: isYuanChuang, isGaoLiang: isGaoLiang,
    ));
  }
  return boardPostInfo;
}

BoardInfo parseBoardInfo(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return BoardInfo.error(errorMessage: errorMessage);
  }
  var headDom = document.querySelector("#board-head");
  String bid = "";
  String boardName = "";
  String engName = "";
  String onlineCount = "";
  String todayCount = "";
  String topicCount = "";
  String postCount = "";
  String likeCount = "0";
  String ycfCount = "";
  bool iLike = false;
  String intro = "";
  bool canEditIntro = false;
  List<AdminInfo> admins = <AdminInfo>[];
  if (headDom != null) {
    bid = getTrimmedString(headDom.attributes['data-bid']);
    boardName = getTrimmedString(headDom.querySelector('#title .black'));
    engName = getTrimmedString(headDom.querySelector('#title .eng'));
    var statDom = headDom.querySelector("#stat");
    if (statDom != null) {
      var numsDom = statDom.querySelectorAll('span');
      var statText = getTrimmedString(statDom);
      var startPos = 0;
      var spanI = 0;
      while (true) {
        var p1 = statText.indexOf("：", startPos);
        if (p1 == -1) { break; }
        var pKey = statText.substring(p1-2, p1);
        switch (pKey) {
          case "在线":
            onlineCount = numsDom[spanI].text;
            break;
          case "今日":
            todayCount = numsDom[spanI].text;
            break;
          case "主题":
            topicCount = numsDom[spanI].text;
            break;
          case "帖数":
            postCount = numsDom[spanI].text;
            break;
          case "创分": // 原创分
            ycfCount = numsDom[spanI].text;
            break;
          default:
        }
        startPos  = p1+1;
        spanI += 1;
      }
    }
    if (headDom.querySelector("#intro.input-wrapper") != null) {
      intro = getTrimmedString(headDom.querySelector("#intro .intro-content"));
      canEditIntro = headDom.querySelector("#intro .intro-edit-button") != null;
    } else {
      intro = getTrimmedString(headDom.querySelector("#intro"));
    }
    likeCount = getTrimmedString(headDom.querySelector("#add-fav .num"));
    var starDom = headDom.querySelector("#add-fav .star");
    if (starDom != null && starDom.classes.contains('active')) {
      iLike = true;
    }
    var adminDom = headDom.querySelector("#admin");
    if (adminDom != null) {
      var adminsDom = adminDom.querySelectorAll("a");
      for (var adom in adminsDom) {
        var userName = getTrimmedString(adom);
        var link = absThreadLink(adom.attributes['href'] ?? "");
        var uid = adom.attributes['href']?.split("=").last ?? "15265";
        admins.add(AdminInfo(userName: userName, link: link, uid: uid));
      }
    }
  }
  var pagingDom = document.querySelector(".paging");
  var pageNum = 0;
  if (pagingDom != null) {
    var pagingsDom = pagingDom.querySelectorAll(".paging-button");
    if (pagingsDom.isNotEmpty) {
      pagingsDom.removeWhere((element) {
        var etext = getTrimmedString(element);
        return etext.contains("返回") || etext.contains("页") || etext.contains("跳");
      });
      pagingsDom.map((e) {
        var txt = getTrimmedString(e);
        if (txt.contains(".")) {
          txt = txt.replaceAll(".", "");
        }
        return int.parse(txt);
      },).toList().forEach((e) {
        if (pageNum < e) {
          pageNum = e;
        }
      });
    }
  }
  String path = document.querySelector("#tab-button-collection a")?.attributes['href'] ?? "";
  String collectionLink = path.isEmpty ? "" : absThreadLink(path);
  var boardPostInfo = parseBoardPost(document.querySelector('#list-body'));
  bool canOpt = document.querySelector(".thread-opt") != null;
  return BoardInfo(
    bid: bid, boardName: boardName, engName: engName, onlineCount: onlineCount, pageNum: pageNum,
    todayCount: todayCount, topicCount: topicCount, postCount: postCount, iLike: iLike,
    likeCount: likeCount, intro: intro, admins: admins, boardPostInfo: boardPostInfo, collectionLink: collectionLink,
    canEditIntro: canEditIntro, ycfCount: ycfCount, canOpt: canOpt,
  );
}

BoardInfo getExampleBoard() {
  const filename = '../board.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseBoardInfo(htmlStr);
  return items;
}

String directToThread(String htmlStr, {bool? needLink=false}) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return errorMessage;
  }
  var link = document.querySelector(".view-full-post")?.attributes['href'];
  if (link == null) {
    return "";
  }
  var p1 = link.indexOf("threadid=");
  var p2 = link.indexOf("&", p1);
  if (needLink==true) { return link; }
  return link.substring(p1+9, p2);
}