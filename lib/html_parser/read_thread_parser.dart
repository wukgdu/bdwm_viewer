import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:characters/characters.dart';

import '../utils.dart' show TextAndLink, getQueryValue;
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
  int vipIdentity = -1;

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
    required this.vipIdentity,
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
  bool canSetReply = false;
  bool isBaoLiu = false;
  bool isWenZhai = false;
  bool isJingHua = false;
  bool isYuanChuang = false;
  bool canOpt = false;
  bool isGaoLiang = false;
  bool isLock = false;
  bool isZhiDing = false;

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
    required this.canSetReply,
    required this.isBaoLiu,
    required this.isWenZhai,
    required this.isJingHua,
    required this.isYuanChuang,
    required this.canOpt,
    required this.isGaoLiang,
    required this.isLock,
    required this.isZhiDing,
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

  int vipIdentity = -1;
  var nickDom = document.querySelector(".nickname");
  if (nickDom != null) {
    if (nickDom.className.contains("identity-1")) {
      vipIdentity = 1;
    } else if (nickDom.className.contains("identity-0")) {
      vipIdentity = 0;
    } else if (nickDom.className.contains("identity-2")) {
      vipIdentity = 2;
    }
  }

  String rating = "", postCount = "";
  var detailDom = document.querySelector(".detail");
  if (detailDom != null) {
    var texts = getTrimmedString(detailDom).split(" ");
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
    rating: rating, avatarLink: avatarLink, avatarFrame: avatarFrame, rankName: rankName, score: score,
    vipIdentity: vipIdentity,
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
      var splitArray = modifyTime.split(" ");
      splitArray.removeWhere((element) => element.isEmpty);
      modifyTime = splitArray.join(" ");
    } else {
      postTime = getTrimmedString(trDom.querySelector("span"));
    }
  }

  var postNumber = getTrimmedString(document.querySelector(".post-id"));
  var postIDDom = document.querySelector(".post-id");
  bool isBaoLiu = false, isWenZhai = false, isJingHua = false, isYuanChuang = false;
  if (postIDDom != null) {
    for (var idom in postIDDom.querySelectorAll("img")) {
      var src = idom.attributes['src'] ?? "";
      if (src.contains("topics/wz")) {
        isWenZhai = true;
      } else if (src.contains("topics/diamond")) {
        isJingHua = true;
      } else if (src.contains("topics/bl")) {
        isBaoLiu = true;
      } else if (src.contains("topics/yc")) {
        isYuanChuang = true;
      }
    }
  }
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
      var vdt = getTrimmedString(vd);
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
      if (optext == "回帖") {
        canReply = canDoIt;
        break;
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

  var canSetReply = false;
  if (document.querySelector("a[data-action=noreply-post]")!=null
  || document.querySelector("a[data-action=clear-noreply-post]")!=null) {
    canSetReply = true;
  }

  bool canOpt = (document.querySelector("a[data-action=top-post]")!=null || document.querySelector("a[data-action=clear-top-post]")!=null);
  bool isGaoLiang = document.querySelector("a[data-action=clear-highlight-post]")!=null;
  bool isLock = document.querySelector("a[data-action=clear-noreply-post]")!=null;
  bool isZhiDing = document.querySelector("a[data-action=clear-top-post]")!=null;
  isBaoLiu = isBaoLiu || (document.querySelector("a[data-action=clear-mark-post]")!=null);
  isWenZhai = isWenZhai || (document.querySelector("a[data-action=clear-digest-post]")!=null);

  return OnePostInfo(
    authorInfo: authorInfo, postTime: postTime, postID: postID, modifyTime: modifyTime,
    upCount: upCount, downCount: downCount, content: content, signature: signature,
    postNumber: postNumber, postOwner: postOwner, iVoteUp: iVoteUp, iVoteDown: iVoteDown,
    attachmentInfo: attachmentInfo, attachmentHtml: attachmentHtml, attachmentSlidesCount: attachmentSlidesCount,
    canReply: canReply, canDelete: canDelete, canModify: canModify, canSetReply: canSetReply,
    isBaoLiu: isBaoLiu, isWenZhai: isWenZhai, isJingHua: isJingHua, isYuanChuang: isYuanChuang,
    canOpt: canOpt, isGaoLiang: isGaoLiang, isLock: isLock, isZhiDing: isZhiDing,
  );
}

String getEqualValue(String a, {String del="="}) {
  var vs = a.split(del);
  if (vs.length > 1) {
    return vs.last;
  }
  return "";
}

ThreadPageInfo parseThread(String htmlStr, {bool simple=false}) {
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
  var blockid = "", boardid = "", threadid = "";
  var linkDom = document.querySelector(".breadcrumb-trail");
  var boardName = "", boardLink = "";
  if (linkDom != null) {
    var linksDom = linkDom.querySelectorAll("a");
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
        threadid = getQueryValue(href, "threadid") ?? "";
        title = getTrimmedString(ld);
      }
    }
  }
  var posts = <OnePostInfo>[];
  var postCards = document.querySelectorAll(".post-card");
  for (var pc in postCards) {
    posts.add(parseOnePost(pc));
    if (simple==true) {
      break;
    }
  }
  return ThreadPageInfo(page: page, pageNum: pageNum, blockid: blockid, boardid: boardid, threadid: threadid, title: title, board: TextAndLink(boardName, boardLink), posts: posts);
}

ThreadPageInfo getExampleThread() {
  const filename = '../bid-thread.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseThread(htmlStr);
  return items;
}

List<String> getShortInfoFromContent(String htmlStr) {
  var res = <String>[];
  var document = parse(htmlStr);
  var fpdom = document.querySelector("p");
  var firstLineText = getTrimmedString(fpdom);
  if (firstLineText.length != firstLineText.runes.length) {
    // remove emoji
    var tmpArr = firstLineText.characters.split("".characters).toList();
    tmpArr.removeWhere((element) => element.string.codeUnits.length > 1);
    firstLineText = tmpArr.join("");
  }
  if (firstLineText.length != firstLineText.characters.length) {
    // remove special character
    var tmpArr = firstLineText.characters.split("".characters).toList();
    tmpArr = tmpArr.map((e) {
      if (e.string.length > 1) {
        return Characters(String.fromCharCode(e.string.codeUnits[0]));
      }
      return e;
    }).toList();
    firstLineText = tmpArr.join("");
  }
  res.add(firstLineText);
  var pdoms = document.querySelectorAll("p").reversed.toList();
  int idx = 0;
  var findQuoteP = false;
  for (var pdom in pdoms) {
    var pdomText = getTrimmedString(pdom);
    if (pdomText.contains("在 ta 的帖子中提到：")) {
      findQuoteP = true;
      res.add(pdomText.split(" (").first);
      if (idx >= 1) {
        if (pdoms[idx-1].classes.contains("blockquote")) {
          res.add(getTrimmedString(pdoms[idx-1]));
        } else {
          res.add("");
        }
      } else {
        res.add("");
      }
      break;
    }
    idx += 1;
  }
  if (findQuoteP == false) {
    res.add("");
    res.add("");
  }
  return res;
}