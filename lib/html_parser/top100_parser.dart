import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import '../globalvars.dart';
import './utils.dart';

class Top100Item {
  int id = 0;
  String title = "";
  String author = "";
  String uid = "";
  String avatarLink = "";
  String board = "";
  String postTime = "";
  String contentLink = "";
  String boardLink = "";

  Top100Item(this.id, this.title, this.author, this.uid, this.avatarLink, this.board, this.postTime, this.contentLink, this.boardLink);
}

class Top100Info {
  String? errorMessage;
  List<Top100Item> items = <Top100Item>[];

  Top100Info.empty();
  Top100Info.error({required this.errorMessage});
  Top100Info({
    required this.items,
    this.errorMessage,
  });
}

Top100Info parseTop100(String htmlStr) {
  var document = parse(htmlStr);
  List<Element>? topicList = document.querySelector("#hot-topic-body")?.querySelectorAll(".list-item");
  if (topicList == null) {
    return Top100Info.empty();
  }
  List<Top100Item> top100Items = <Top100Item>[];
  for (var item in topicList) {
    final itemID = int.parse(getTrimmedString(item.querySelector(".id")));
    final itemTitle = getTrimmedString(item.querySelector(".title"));
    final itemAuthor = getTrimmedString(item.querySelector(".name"));
    final itemAuthorRelaLink = item.querySelector(".author")?.querySelector(".link")?.attributes['href'] ?? "";
    final itemUID = itemAuthorRelaLink.isNotEmpty ? itemAuthorRelaLink.split("=")[1] : "";
    final itemTime = getTrimmedString(item.querySelector(".time"));
    final itemAvatar = absImgSrc(item.querySelector(".avatar")?.querySelector("img")?.attributes['src'] ?? defaultAvator);
    final itemBoard = getTrimmedString(item.querySelector(".board"));
    final itemLink = absThreadLink(item.querySelector(".link")?.attributes['href'] ?? "");
    final itemBoardLink = absThreadLink(item.querySelector(".board-cont")?.querySelector(".link")?.attributes['href'] ?? "");
    top100Items.add(Top100Item(itemID, itemTitle, itemAuthor, itemUID, itemAvatar, itemBoard, itemTime, itemLink, itemBoardLink));
  }
  return Top100Info(items: top100Items);
}

Top100Info getExampleTop100() {
  const filename = '../top100raw.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseTop100(htmlStr);
  return items;
}
