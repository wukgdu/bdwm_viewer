import 'package:html/parser.dart' show parse;

import './utils.dart';

class BanItemInfo {
  String uid = "";
  String bid = "";
  String userName = "";
  String endTime = "";
  String reason = "";

  BanItemInfo({
    required this.uid,
    required this.bid,
    required this.userName,
    required this.endTime,
    required this.reason,
  });
}

class BoardBanInfo {
  String bid = "";
  String boardName = "";
  String engName = "";
  List<BanItemInfo> banItems = [];
  String? errorMessage;

  BoardBanInfo({
    required this.bid,
    required this.boardName,
    required this.engName,
    required this.banItems,
    this.errorMessage,
  });
  BoardBanInfo.empty();
  BoardBanInfo.error({
    required this.errorMessage,
  });
}

BoardBanInfo parseBoardBanInfo(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return BoardBanInfo.error(errorMessage: errorMessage);
  }

  var headDom = document.querySelector("#board-head");
  String bid = "";
  String boardName = "";
  String engName = "";
  if (headDom != null) {
    bid = getTrimmedString(headDom.attributes['data-bid']);
    boardName = getTrimmedString(headDom.querySelector('#title .black'));
    engName = getTrimmedString(headDom.querySelector('#title .eng'));
  }

  var banListDom = document.querySelector("#ban-list")?.querySelectorAll(".list-item");
  var banItems = <BanItemInfo>[];
  if (banListDom == null || banListDom.isEmpty) {
    return BoardBanInfo(bid: bid, boardName: boardName, engName: engName, banItems: banItems);
  }
  banListDom.removeWhere((element) => element.classes.contains("editor"));
  for (var item in banListDom) {
    String uid = item.attributes['data-ban-uid'] ?? "";
    String bidItem = item.attributes['data-bid'] ?? "";
    var spanDoms = item.querySelectorAll("span");
    var userNameSpanDom = item.querySelector("span[data-role=ban-username]");
    var reasonSpanDom = item.querySelector("span[data-role=ban-reason]");
    spanDoms.removeWhere((element) => (element == userNameSpanDom) || (element == reasonSpanDom));
    String userName = getTrimmedString(userNameSpanDom);
    String endTime = spanDoms.map((e) => getTrimmedString(e)).join(" ");
    String reason = getTrimmedString(reasonSpanDom);
    banItems.add(BanItemInfo(
      bid: bidItem, uid: uid, userName: userName, endTime: endTime, reason: reason,
    ));
  }
  return BoardBanInfo(bid: bid, boardName: boardName, engName: engName, banItems: banItems);
}
