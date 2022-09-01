import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import '../utils.dart';
import './utils.dart';

class AuthorPostInfo {
  String userName = "";
  String uid = "";
  String status = "";
  String nickName = "";
  String rankName = "";
  String score = "";
  String postCount = "";
  String rating = "";
  String avatarLink = "";
  String avatarFrame = "";

  AuthorPostInfo.empty();
  AuthorPostInfo({
    required this.userName,
    required this.uid,
    required this.score,
    required this.nickName,
    required this.rankName,
    required this.status,
    required this.postCount,
    required this.rating,
    required this.avatarLink,
    required this.avatarFrame,
  });
}

enum AttachmentType {
  showText,
  showThumbnail,
}

class AttachmentInfo {
  String text = "";
  String link = "";
  String size = "";
  String thumbnailLink = "";
  AttachmentType type = AttachmentType.showText;

  AttachmentInfo.empty();
  AttachmentInfo({
    required this.text,
    required this.link,
    required this.size,
    required this.type,
    required this.thumbnailLink,
  });
}

class OnePostInfo {
  var authorInfo = AuthorPostInfo.empty();
  String postTime = "";
  String postID = "";
  String postNumber = "";
  bool postOwner = false;
  String modifyTime = "";
  int upCount = 0;
  int downCount = 0;
  String content = "";
  String signature = "";
  bool iVoteUp = false;
  bool iVoteDown = false;
  List<AttachmentInfo> attachmentInfo = <AttachmentInfo>[];
  int attachmentSlidesCount = 0;
  String attachmentHtml = "";
  bool canReply = true;
  bool canModify = false;
  bool canDelete = false;

  OnePostInfo.empty();
  OnePostInfo({
    required this.authorInfo,
    required this.postTime,
    required this.postID,
    required this.postNumber,
    required this.postOwner,
    required this.modifyTime,
    required this.upCount,
    required this.downCount,
    required this.content,
    required this.signature,
    required this.iVoteUp,
    required this.iVoteDown,
    required this.attachmentInfo,
    required this.attachmentHtml,
    required this.attachmentSlidesCount,
    required this.canReply,
    required this.canModify,
    required this.canDelete,
  });
}

class ThreadPageInfo {
  int page = 0;
  int pageNum = 0;
  String blockid = "";
  String boardid = "";
  String threadid = "";
  String title = "";
  TextAndLink board = TextAndLink.empty();
  List<OnePostInfo> posts = <OnePostInfo>[];
  String? errorMessage;

  ThreadPageInfo.empty();
  ThreadPageInfo.error({this.errorMessage});
  ThreadPageInfo({
    required this.page,
    required this.pageNum,
    required this.blockid,
    required this.boardid,
    required this.threadid,
    required this.title,
    required this.board,
    required this.posts,
    this.errorMessage,
  });
}

AuthorPostInfo parseUserPost(Element? document) {
  if (document == null) {
    return AuthorPostInfo.empty();
  }
  String uid = getEqualValue(document.querySelector(".portrait-container")?.attributes['href'] ?? "");
  String userName = getTrimmedString(document.querySelector(".username a"));
  String nickName = getTrimmedHtml(document.querySelector(".nickname"));
  String status = getTrimmedString(document.querySelector(".username span"));

  String rating = "", postCount = "";
  var detailDom = document.querySelector(".detail");
  if (detailDom != null) {
    var texts = detailDom.text.trim().split(" ");
    texts.removeWhere((element) => element.isEmpty);
    for (var text in texts) {
      var values = text.split("：");
      if (values[0] == '发帖数') {
        postCount = values[1];
      } else if (values[0] == "原创分") {
        rating = values[1];
      }
    }
  }

  String rankName = getTrimmedString(document.querySelector('.level'));
  String score = getTrimmedString(document.querySelector('.score'));
  var imgLinks = document.querySelector(".portrait-container")?.querySelectorAll("img");
  String avatarLink = "";
  String avatarFrame = "";
  if ((imgLinks != null && imgLinks.isNotEmpty)) {
    if (imgLinks.length == 1) {
      avatarLink = absImgSrc(imgLinks[0].attributes['src'] ?? "");
    } else {
      avatarLink = absImgSrc(imgLinks[0].attributes['src'] ?? "");
      avatarFrame = absImgSrc(imgLinks[1].attributes['src'] ?? "");
    }
  }

  return AuthorPostInfo(
    userName: userName, uid: uid, nickName: nickName, status: status, postCount: postCount,
    rating: rating, avatarLink: avatarLink, avatarFrame: avatarFrame, rankName: rankName, score: score
  );
}

OnePostInfo parseOnePost(Element document) {
  var authorInfo = parseUserPost(document.querySelector(".post-owner"));
  var postID = document.attributes['data-postid'] ?? "";
  var postTime = "";
  var modifyTime = "";
  var trDom = document.querySelector(".sl-triangle-container");
  if (trDom != null) {
    var downDom = trDom.querySelector(".down-list");
    if (downDom != null) {
      postTime = getTrimmedString(downDom);
      modifyTime = getTrimmedString(trDom.querySelector("span"));
    } else {
      postTime = getTrimmedString(trDom.querySelector("span"));
    }
  }

  var postNumber = getTrimmedString(document.querySelector(".post-id"));
  var postOwner = false;
  if (document.querySelector(".lz-tag") != null) {
    postOwner = true;
  }

  var upCount = 0;
  var downCount = 0;
  var voteDom = document.querySelector(".post-vote-line");
  bool iVoteUp = false, iVoteDown = false;
  if (voteDom != null) {
    var votesDom = voteDom.querySelectorAll(".text");
    for (var vd in votesDom) {
      var vdt = vd.text;
      var p1 = vdt.indexOf('(');
      var p2 = vdt.indexOf(')');
      var value = int.parse(vdt.substring(p1+1, p2));
      if (vdt.startsWith("赞")) {
        upCount = value;
      } else {
        downCount = value;
      }
      var checkDom = voteDom.querySelectorAll(".checked");
      for (var cdom in checkDom) {
        if (cdom.attributes['data-action'] == "upvote") {
          iVoteUp = true;
        } else if (cdom.attributes['data-action'] == "downvote") {
          iVoteDown = true;
        }
      }
    }
  }

  var content = "";
  var signature = "";
  var contentDom = document.querySelector(".content");
  if (contentDom != null) {
    var contentBodyDom = contentDom.querySelector(".body");
    content = getTrimmedHtml(contentBodyDom);
    var signatureDom = contentDom.querySelector(".signature");
    signature = getTrimmedHtml(signatureDom);
  }

  var attachmentInfo = <AttachmentInfo>[];
  var attachmentDom = document.querySelector(".attachment");
  var attachmentHtml = "";
  int attachmentSlidesCount = 0;
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
        attachmentSlidesCount += 1;
      }
      attachmentInfo.add(AttachmentInfo(text: name, link: link, size: size, type: aType, thumbnailLink: thumbnailLink));
    }
  }

  bool canReply = true;
  var operationDom = document.querySelector(".operations .toolbox");
  if (operationDom != null) {
    var operationsDom = operationDom.querySelectorAll("li");
    for (var oDom in operationsDom) {
      var optext = getTrimmedString(oDom);
      var aDom = oDom.querySelector("a");
      if (aDom == null) {
        continue;
      }
      var canDoIt = !aDom.classes.contains("disable");
      switch (optext) {
        case "回帖":
          canReply = canDoIt;
          break;
        default:
      }
    }
  }
  var canDelete = false;
  var canModify = false;
  var moreOperationDom = document.querySelector(".operations .ops");
  if (moreOperationDom != null) {
    var moreOpsDom = moreOperationDom.querySelectorAll("li");
    for (var oDom in moreOpsDom) {
      var optext = getTrimmedString(oDom);
      var aDom = oDom.querySelector("a");
      if (aDom == null) {
        continue;
      }
      switch (optext) {
        case "修改":
          canModify = true;
          break;
        case "删除":
          canDelete = true;
          break;
        default:
      }
    }
  }

  return OnePostInfo(
    authorInfo: authorInfo, postTime: postTime, postID: postID, modifyTime: modifyTime,
    upCount: upCount, downCount: downCount, content: content, signature: signature,
    postNumber: postNumber, postOwner: postOwner, iVoteUp: iVoteUp, iVoteDown: iVoteDown,
    attachmentInfo: attachmentInfo, attachmentHtml: attachmentHtml, attachmentSlidesCount: attachmentSlidesCount,
    canReply: canReply, canDelete: canDelete, canModify: canModify,
  );
}

String getEqualValue(String a, {String del="="}) {
  var vs = a.split(del);
  if (vs.length > 1) {
    return vs.last;
  }
  return "";
}

ThreadPageInfo parseThread(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return ThreadPageInfo.error(errorMessage: errorMessage);
  }
  var pagingDom = document.querySelector(".paging-top");
  var title = getTrimmedString(document.querySelector('header')?.children[0]);
  var page = 0, pageNum = 0;
  if (pagingDom != null) {
    page = int.parse(getTrimmedString(pagingDom.querySelector(".active")));
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
  var blockid = "", boardid = "", threadid = "";
  var linkDom = document.querySelector(".breadcrumb-trail");
  var boardName = "", boardLink = "";
  if (linkDom != null) {
    var linksDom = linkDom.querySelectorAll("a");
    if (linksDom.isNotEmpty) {
      for (var ld in linksDom) {
        var href = ld.attributes['href'];
        if (href==null) {
          continue;
        }
        if (href.startsWith("board")) {
          blockid = getEqualValue(href);
        } else if (href.startsWith("thread")) {
          boardid = getEqualValue(href);
          boardName = getTrimmedString(ld);
          boardLink = absThreadLink(href);
        } else if (href.contains("post-read")) {
          threadid = getEqualValue(href);
          title = getTrimmedString(ld);
        }
      }
    }
  }
  var posts = <OnePostInfo>[];
  var postCards = document.querySelectorAll(".post-card");
  for (var pc in postCards) {
    posts.add(parseOnePost(pc));
  }
  return ThreadPageInfo(page: page, pageNum: pageNum, blockid: blockid, boardid: boardid, threadid: threadid, title: title, board: TextAndLink(boardName, boardLink), posts: posts);
}

ThreadPageInfo getExampleThread() {
  const filename = '../bid-thread.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseThread(htmlStr);
  return items;
}
