import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as hdom;

import './utils.dart' show checkError, getTrimmedString, absThreadLink;
import '../utils.dart' show TextAndLink;
import './board_parser.dart' show AdminInfo;

class BlockBoardItem {
  String boardName = "";
  String engName = "";
  String bid = "";
  bool thereIsAdmin = false;
  bool isSub = false;
  bool readOnly = false;
  bool likeIt = false;
  List<AdminInfo> admin = <AdminInfo>[];
  TextAndLink lastUpdate = TextAndLink.empty();
  String? lastPostTitle;
  String people = "";

  BlockBoardItem.empty();
  BlockBoardItem({
    required this.boardName,
    required this.engName,
    required this.bid,
    required this.thereIsAdmin,
    required this.isSub,
    required this.readOnly,
    required this.likeIt,
    required this.admin,
    required this.lastUpdate,
    required this.people,
    this.lastPostTitle,
  });
}

class BlockBoardSet {
  String title = "";
  bool isHot = false;
  List<BlockBoardItem> blockBoardItems = <BlockBoardItem>[];

  BlockBoardSet.empty();
  BlockBoardSet({
    required this.title,
    required this.blockBoardItems,
    required this.isHot,
  });
}

class BlockInfo {
  String name = "";
  String bid = "";
  List<BlockBoardSet> blockBoardSets = <BlockBoardSet>[];
  String? errorMessage;

  BlockInfo.empty();
  BlockInfo.error({required this.errorMessage});
  BlockInfo({
    required this.name,
    required this.bid,
    required this.blockBoardSets,
    this.errorMessage,
  });
}

BlockInfo parseBlock(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return BlockInfo.error(errorMessage: errorMessage);
  }
  var boardSetsDom = document.querySelectorAll(".section");
  if (boardSetsDom.isEmpty) {
    return BlockInfo.empty();
  }
  hdom.Element? hotBoardSetDom;
  hdom.Element? otherBoardSetDom;
  if (boardSetsDom.length == 1) {
    hotBoardSetDom = null;
  } else {
    hotBoardSetDom = boardSetsDom.first;
    otherBoardSetDom = boardSetsDom[1];
  }
  var name = "";
  var bid = "";
  var trailDom = document.querySelector(".breadcrumb-trail");
  if (trailDom != null) {
    for (var td in trailDom.querySelectorAll("a")) {
      var href = td.attributes['href'] ?? "";
      if (href.contains("bid")) {
        name = getTrimmedString(td);
        bid = href.split("=").last;
        break;
      }
    }
  }

  var blockBoardSets = <BlockBoardSet>[];
  if (hotBoardSetDom != null) {
    var blockBoardItems = <BlockBoardItem>[];
    var title = "热门版面";
    for (var bbdom in hotBoardSetDom.querySelectorAll(".boards-wrapper .board-block")) {
      var subbid = bbdom.attributes['data-bid'] ?? "";
      var thereIsAdmin = false;
      var boardName = getTrimmedString(bbdom.querySelector(".name"));
      var engName = getTrimmedString(bbdom.querySelector(".eng-name"));
      if (bbdom.querySelectorAll(".admin .inline-link").isNotEmpty) {
        thereIsAdmin = true;
      }
      var adminDom = bbdom.querySelector(".admin")?.querySelectorAll(".inline-link");
      var adminTL = <AdminInfo>[];
      if ((adminDom != null) && (adminDom.isNotEmpty)) {
        for (var ad in adminDom) {
          var adminName = getTrimmedString(ad);
          var adminLink = absThreadLink(ad.attributes['href'] ?? "");
          var uid = ad.attributes['href']?.split("=").last ?? "15265";
          adminTL.add(AdminInfo(userName: adminName, link: adminLink, uid: uid));
        }
      }
      var isSub = false;
      if (bbdom.classes.contains("sub-block")) {
        isSub = true;
      }
      var likeIt = false;
      if (bbdom.querySelector(".star.active") != null) {
        likeIt = true;
      }
      var readOnly = false;
      if (bbdom.querySelector(".readonly") != null) {
        readOnly = true;
      }
      String lastUpdateTime = bbdom.querySelectorAll(".right .post .info span").map((e) => getTrimmedString(e)).join(" ");
      if (lastUpdateTime.isEmpty) {
        lastUpdateTime = "遇到了问题";
      }
      String lastUpdatePost = absThreadLink(bbdom.querySelector(".right .post .title")?.attributes['href'] ?? "");
      String lastPostTitle = getTrimmedString(bbdom.querySelector(".right .post .title"));
      blockBoardItems.add(BlockBoardItem(
        boardName: boardName, engName: engName, bid: subbid, thereIsAdmin: thereIsAdmin, isSub: isSub, readOnly: readOnly, likeIt: likeIt, admin: adminTL,
        lastUpdate: TextAndLink(lastUpdateTime, lastUpdatePost), lastPostTitle: lastPostTitle, people: "",
      ));
    }
    blockBoardSets.add(BlockBoardSet(title: title, blockBoardItems: blockBoardItems, isHot: true));
  }

  if (otherBoardSetDom != null) {
    for (var obsd in otherBoardSetDom.querySelectorAll(".sub-section")) {
      var blockBoardItems = <BlockBoardItem>[];
      var title = getTrimmedString(obsd.querySelector(".sub-section-title")?.children.first);
      var sectionContentDom = obsd.querySelector(".section-content");
      if (sectionContentDom == null) {
        continue;
      }
      var listDom = sectionContentDom.querySelector(".boards-wrapper.list");
      if (listDom == null) {
        continue;
      }
      for (var bbdom in listDom.querySelectorAll(".board-block")) {
        var subbid = bbdom.attributes['data-bid'] ?? "";
        var thereIsAdmin = false;
        var boardName = getTrimmedString(bbdom.querySelector(".name"));
        var engName = getTrimmedString(bbdom.querySelector(".eng-name"));
        final people = getTrimmedString(bbdom.querySelector(".people"));
        if (bbdom.querySelectorAll(".admin .inline-link").isNotEmpty) {
          thereIsAdmin = true;
        }
        var adminDom = bbdom.querySelector(".admin")?.querySelectorAll(".inline-link");
        var adminTL = <AdminInfo>[];
        if ((adminDom != null) && (adminDom.isNotEmpty)) {
          for (var ad in adminDom) {
            var adminName = getTrimmedString(ad);
            var adminLink = absThreadLink(ad.attributes['href'] ?? "");
            var uid = ad.attributes['href']?.split("=").last ?? "15265";
            adminTL.add(AdminInfo(userName: adminName, link: adminLink, uid: uid));
          }
        }
        var isSub = false;
        if (bbdom.classes.contains("sub-block")) {
          isSub = true;
        }
        var likeIt = false;
        if (bbdom.querySelector(".star.active") != null) {
          likeIt = true;
        }
        var readOnly = false;
        if (bbdom.querySelector(".readonly") != null) {
          readOnly = true;
        }
        String lastUpdateTime = getTrimmedString(bbdom.querySelector(".update"));
        if (lastUpdateTime.isEmpty) {
          lastUpdateTime = "您没有权限访问该页面";
        }
        String lastUpdatePost = absThreadLink(bbdom.querySelector(".update")?.attributes['href'] ?? "");
        blockBoardItems.add(BlockBoardItem(
          boardName: boardName, engName: engName, bid: subbid, thereIsAdmin: thereIsAdmin, isSub: isSub, readOnly: readOnly, likeIt: likeIt, admin: adminTL,
          lastUpdate: TextAndLink(lastUpdateTime, lastUpdatePost), people: people,
        ));
      }
      blockBoardSets.add(BlockBoardSet(title: title, blockBoardItems: blockBoardItems, isHot: false));
    }
  }
  return BlockInfo(name: name, bid: bid, blockBoardSets: blockBoardSets);
}

BlockInfo getExampleBlockInfo() {
  const filename = '../block.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseBlock(htmlStr);
  return items;
}
