import 'dart:io';

// import 'package:flutter/material.dart' show debugPrint;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import './utils.dart';

class _BasicInfo {
  String title = "";
  String board = "";
  String link = "";
  String countComments = "";

  _BasicInfo({
    required this.title,
    required this.board,
    required this.link,
    required this.countComments,
  });
}

class Top10Item extends _BasicInfo {
  int id = 0;
  Top10Item({
    required this.id,
    required title,
    required board,
    required link,
    required countComments,
  }) : super(title: title, board: board, link: link, countComments: countComments);
}

class BlockItem extends _BasicInfo {
  BlockItem({
    required title,
    required board,
    required link,
    required countComments,
  }) : super(title: title, board: board, link: link, countComments: countComments);
}

class BlockOne {
  String blockName = "";
  String blockLink = "";
  List<BlockItem> blockItems = <BlockItem>[];

  BlockOne({
    required this.blockName,
    required this.blockLink,
    required this.blockItems,
  });
}

class WelcomeInfo {
  String imgLink = "";
  String actionLink = "";
  String? errorMessage;

  WelcomeInfo.empty();
  WelcomeInfo.error({
    required this.errorMessage,
  });
  WelcomeInfo({
    required this.imgLink,
    required this.actionLink,
  });
}

class HomeInfo {
  List<Top10Item>? top10Info = <Top10Item>[];
  List<BlockOne> blockInfo = <BlockOne>[];
  String? errorMessage;

  HomeInfo({
    required this.top10Info,
    required this.blockInfo,
    this.errorMessage,
  });

  HomeInfo.empty();
  HomeInfo.error({required this.errorMessage});
}

List<Top10Item>? parseTop10(Document document) {
  var topList = document.querySelector(".big-ten")?.querySelectorAll("li");
  List<Top10Item> top10Items = <Top10Item>[];
  if (topList == null) {
    return top10Items;
  }
  if (topList.length == 1) {
    var oneItem = topList[0];
    if (oneItem.querySelector(".post-title")==null) {
      top10Items.add(Top10Item(id: -1, title: "校外游客暂不能访问十大热门话题，请您登录", board: "", link: "", countComments: ""));
      return top10Items;
    }
  }
  for (var item in topList) {
    // debugPrint(item.innerHtml);
    final itemID = int.parse(getTrimmedString(item.querySelector(".rank-digit")));
    final itemTitle = getTrimmedString(item.querySelector(".post-title"));
    final itemLink = absThreadLink(item.querySelector(".post-link")?.attributes['href'] ?? "");
    final domInfo = item.querySelector(".post-info");
    String countComments = "";
    String itemBoard = "";
    if (domInfo != null) {
      var domInfoNodes = domInfo.nodes;
      if (domInfoNodes.length < 3) {
        domInfo.querySelector(".iconfont")?.remove();
        List<String> infos = getTrimmedString(domInfo).split(" ");
        infos.removeWhere((element) => element.isEmpty);
        if (infos.length >= 2) {
          itemBoard = infos.getRange(0, infos.length-1).join(" ");
          countComments = infos.last;
        }
      } else {
        itemBoard = getTrimmedString(domInfoNodes[0]);
        countComments = getTrimmedString(domInfoNodes[2]);
      }
    }
    top10Items.add(Top10Item(id: itemID, title: itemTitle, board: itemBoard, link: itemLink, countComments: countComments));
  }
  return top10Items;
}

List<BlockItem> parseBlockItem(Element document) {
  var topList = document.querySelectorAll("li");
  List<BlockItem> blockItems = <BlockItem>[];
  if (topList.isEmpty) {
    return blockItems;
  }
  if (document.querySelector(".not-available") != null) {
    return blockItems;
  }
  for (var item in topList) {
    final itemTitle = getTrimmedString(item.querySelector(".post-title"));
    final itemLink = absThreadLink(item.querySelector(".post-link")?.attributes['href'] ?? "");
    final domInfo = item.querySelector(".post-info");
    String countComments = "";
    String itemBoard = "";
    if (domInfo != null) {
      var domInfoNodes = domInfo.nodes;
      if (domInfoNodes.length < 3) {
        domInfo.querySelector(".iconfont")?.remove();
        List<String> infos = getTrimmedString(domInfo).split(" ");
        infos.removeWhere((element) => element.isEmpty);
        if (infos.length >= 2) {
          itemBoard = infos.getRange(0, infos.length-1).join(" ");
          countComments = infos.last;
        } else if (infos.length == 1) {
          itemBoard = infos[0];
          countComments = "";
        }
      } else {
        itemBoard = getTrimmedString(domInfoNodes[0]);
        countComments = getTrimmedString(domInfoNodes[2]);
      }
    }
    blockItems.add(BlockItem(title: itemTitle, board: itemBoard, link: itemLink, countComments: countComments));
  }
  return blockItems;
}

List<BlockOne> parseBlock(Document document) {
  List<BlockOne> blockInfo = <BlockOne>[];
  var cards = document.querySelectorAll(".card");
  cards.removeWhere((element) {
    var moreLink = element.querySelector(".more-link");
    if (moreLink == null) {
      return true;
    }
    var href = moreLink.attributes['href'];
    if (href == null) {
      return true;
    }
    if (href.startsWith("board")) {
      return false;
    }
    return true;
  });
  for (var element in cards) {
    var blockName = getTrimmedString(element.querySelector(".name"));
    var blockLink = absThreadLink(element.querySelector(".more-link")?.attributes['href'] ?? "");
    var blockItems = parseBlockItem(element);
    blockInfo.add(BlockOne(blockName: blockName, blockLink: blockLink, blockItems: blockItems));
  }
  return blockInfo;
}

HomeInfo parseHome(String htmlStr) {
  var document = parse(htmlStr);
  var top10Info = parseTop10(document);
  var blockInfo = parseBlock(document);
  return HomeInfo(top10Info: top10Info, blockInfo: blockInfo);
}

HomeInfo getExampleHomeInfo() {
  const filename = '../mobilehome.html';
  var htmlStr = File(filename).readAsStringSync();
  final item = parseHome(htmlStr);
  return item;
}

List<Top10Item>? parseBigTen(String htmlStr) {
  var document = parse(htmlStr);
  var top10Info = parseTop10(document);
  return top10Info;
}

WelcomeInfo parseWelcomeFromHtml(String htmlStr) {
  var document = parse(htmlStr);
  WelcomeInfo welcomeInfo = WelcomeInfo.empty();
  var dialogWelcomeDom = document.querySelector("#dialog-welcome");
  if (dialogWelcomeDom != null) {
    var welcomeImgLink = dialogWelcomeDom.querySelector("#welcome-image")?.attributes['src'];
    if (welcomeImgLink != null) {
      welcomeInfo.imgLink = absImgSrc(welcomeImgLink);
    }
    var imgDom = dialogWelcomeDom.querySelector("a.image");
    if (imgDom != null) {
      var href = imgDom.attributes['href'] ?? "";
      if (href.isNotEmpty) {
        welcomeInfo.actionLink = absThreadLink(href);
      }
    }
  }
  return welcomeInfo;
}
