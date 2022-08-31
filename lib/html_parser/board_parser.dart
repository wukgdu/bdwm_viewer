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
  String threadID = "";
  String userName = "";
  String uid = "";
  String avatarLink = "";
  String pTime = "";
  String commentCount = "";
  String lastUser = "";
  String lastTime = "";
  bool lock = false;

  BoardPostInfo.empty();
  BoardPostInfo({
    required this.bpID,
    required this.isNew,
    required this.title,
    required this.link,
    required this.threadID,
    required this.userName,
    required this.uid,
    required this.avatarLink,
    required this.pTime,
    required this.commentCount,
    required this.lastUser,
    required this.lastTime,
    required this.lock,
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
  String intro = "";
  int pageNum = 0;
  bool iLike = false;
  List<AdminInfo> admins = <AdminInfo>[];
  List<BoardPostInfo> boardPostInfo = <BoardPostInfo>[];
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
    this.errorMessage,
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
    bool isNew = false;
    if (pdom.querySelector(".dot.unread") != null) {
      isNew = true;
    }
    var titleCont = pdom.querySelector(".title-cont");
    String title = getTrimmedString(titleCont);
    bool lock = false;
    if (titleCont != null) {
      for (var idom in titleCont.querySelectorAll("img")) {
        if (idom.attributes['src']?.contains("lock") ?? false) {
          lock = true;
          break;
        }
      }
    }
    String link = absThreadLink(pdom.querySelector(".link")?.attributes['href'] ?? "");
    String threadID = pdom.attributes['data-itemid'] ?? "";
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
      bpID: bpID, isNew: isNew, title: title, link: link, threadID: threadID,
      userName: userName, avatarLink: avatarLink, pTime: pTime, uid: uid,
      commentCount: commentCount, lastUser: lastUser, lastTime: lastTime, lock: lock,
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
  bool iLike = false;
  String intro = "";
  List<AdminInfo> admins = <AdminInfo>[];
  if (headDom != null) {
    bid = getTrimmedString(headDom.attributes['data-bid']);
    boardName = getTrimmedString(headDom.querySelector('#title .black'));
    engName = getTrimmedString(headDom.querySelector('#title .eng'));
    var statDom = headDom.querySelector("#stat");
    if (statDom != null) {
      var numsDom = statDom.querySelectorAll('span');
      var statText = statDom.text;
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
          default:
        }
        startPos  = p1+1;
        spanI += 1;
      }
    }
    intro = getTrimmedString(headDom.querySelector("#intro"));
    likeCount = getTrimmedString(headDom.querySelector("#add-fav .num"));
    var starDom = headDom.querySelector("#add-fav .star");
    if (starDom != null && starDom.classes.contains('active')) {
      iLike = true;
    }
    var adminDom = headDom.querySelector("#admin");
    if (adminDom != null) {
      var adminsDom = adminDom.querySelectorAll("a");
      for (var adom in adminsDom) {
        var userName = adom.text;
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
        var etext = element.text;
        return etext.contains("返回") || etext.contains("页") || etext.contains("跳");
      });
      pagingsDom.map((e) {
        var txt = e.text;
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
  var boardPostInfo = parseBoardPost(document.querySelector('#list-body'));
  return BoardInfo(
    bid: bid, boardName: boardName, engName: engName, onlineCount: onlineCount, pageNum: pageNum,
    todayCount: todayCount, topicCount: topicCount, postCount: postCount, iLike: iLike,
    likeCount: likeCount, intro: intro, admins: admins, boardPostInfo: boardPostInfo,
  );
}

BoardInfo getExampleBoard() {
  const filename = '../board.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseBoardInfo(htmlStr);
  return items;
}

String directToThread(String htmlStr) {
  var document = parse(htmlStr);
  var link = document.querySelector(".view-full-post")?.attributes['href'];
  if (link == null) {
    return "";
  }
  var p1 = link.indexOf("threadid=");
  var p2 = link.indexOf("&", p1);
  return link.substring(p1+9, p2);
}