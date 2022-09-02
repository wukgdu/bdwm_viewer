import 'dart:io';

import 'package:html/parser.dart' show parse;

import './utils.dart';
import '../utils.dart' show TextAndLink;

class ZoneItemInfo {
  String number = "";
  String name = "";
  String bid = "";
  List<TextAndLink> boards = <TextAndLink>[];
  List<TextAndLink> admins = <TextAndLink>[];

  ZoneItemInfo.empty();
  ZoneItemInfo({
    required this.number,
    required this.name,
    required this.boards,
    required this.bid,
    required this.admins,
  });
}

class ZoneInfo {
  String? errorMessage;
  List<ZoneItemInfo> zoneItems = <ZoneItemInfo>[];

  ZoneInfo.empty();
  ZoneInfo.error({required this.errorMessage});
  ZoneInfo({
    required this.zoneItems,
    this.errorMessage,
  });
}


ZoneInfo parseZone(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return ZoneInfo.error(errorMessage: errorMessage);
  }
  var boardListDom = document.querySelector("#boards-list");
  if (boardListDom == null) {
    return ZoneInfo.empty();
  }
  var zoneItems = <ZoneItemInfo>[];
  for (var bbdom in boardListDom.querySelectorAll(".board-block")) {
    var number = getTrimmedString(bbdom.querySelector(".number"));
    var name = getTrimmedString(bbdom.querySelector(".name"));
    var bid = (bbdom.querySelector(".block-link")?.attributes['href'] ?? "").split("=").last;
    var boards = <TextAndLink>[];
    for (var tbdom in bbdom.querySelectorAll(".lower .inline-link")) {
      var boardName = getTrimmedString(tbdom);
      var tbid = tbdom.attributes['href']?.split("=").last ?? "";
      boards.add(TextAndLink(boardName, tbid));
    }
    var admins = <TextAndLink>[];
    for (var tbdom in bbdom.querySelectorAll(".upper .inline-link")) {
      var aName = getTrimmedString(tbdom);
      var auid = tbdom.attributes['href']?.split("=").last ?? "";
      admins.add(TextAndLink(aName, auid));
    }
    zoneItems.add(ZoneItemInfo(number: number, name: name, boards: boards, bid: bid, admins: admins));
  }
  return ZoneInfo(zoneItems: zoneItems);
}

ZoneInfo getExampleZone() {
  const filename = '../zone.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseZone(htmlStr);
  return items;
}
