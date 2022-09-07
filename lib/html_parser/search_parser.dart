import 'package:html/parser.dart' show parse;

import './utils.dart';

class SimpleSearchResItem {
  String id = "";
  String name = ""; // nickName
  String engName = ""; // bbsID
  String? avatar = "";

  SimpleSearchResItem.empty();
  SimpleSearchResItem({
    required this.id,
    required this.name,
    required this.engName,
    this.avatar,
  });
}

class SimpleSearchRes {
  String? errorMessage;
  int maxPage = 0;
  List<SimpleSearchResItem> res = <SimpleSearchResItem>[];

  SimpleSearchRes.empty();
  SimpleSearchRes.error({this.errorMessage});
  SimpleSearchRes({
    required this.res,
    this.errorMessage,
    required this.maxPage,
  });
}

SimpleSearchRes parseBoardSearch(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return SimpleSearchRes.error(errorMessage: errorMessage);
  }
  var resultDom = document.querySelector(".search-result");
  if (resultDom == null) {
    return SimpleSearchRes.empty();
  }
  var res = <SimpleSearchResItem>[];
  for (var item in resultDom.querySelectorAll(".board-block")) {
    var name = getTrimmedString(item.querySelector(".name"));
    var engName = getTrimmedString(item.querySelector(".eng-name"));
    var id = item.attributes['data-bid'] ?? "";
    res.add(SimpleSearchResItem(id: id, name: name, engName: engName));
  }
  int maxPage = 0;
  var pagingDivsDom = document.querySelectorAll(".paging div");
  for (var pdd in pagingDivsDom) {
    var txt = pdd.text;
    if (txt.startsWith("/")) {
      maxPage = int.parse(txt.substring(2)); // <div>/ 2</div>
      break;
    }
  }
  return SimpleSearchRes(res: res, maxPage: maxPage);
}

SimpleSearchRes parseUserSearch(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return SimpleSearchRes.error(errorMessage: errorMessage);
  }
  var resultDom = document.querySelector(".search-result");
  if (resultDom == null) {
    return SimpleSearchRes.empty();
  }
  var res = <SimpleSearchResItem>[];
  for (var item in resultDom.querySelectorAll(".user-block")) {
    var name = getTrimmedString(item.querySelector(".name"));
    var engName = getTrimmedString(item.querySelector(".eng-name"));
    var id = item.attributes['data-uid'] ?? "";
    res.add(SimpleSearchResItem(id: id, name: name, engName: engName));
  }
  int maxPage = 0;
  var pagingDivsDom = document.querySelectorAll(".paging div");
  for (var pdd in pagingDivsDom) {
    var txt = pdd.text;
    if (txt.startsWith("/")) {
      maxPage = int.parse(txt.substring(2)); // <div>/ 2</div>
      break;
    }
  }
  return SimpleSearchRes(res: res, maxPage: maxPage);
}

class TextAndLinkAndTime {
  String text = "";
  String link = "";
  String time = "";

  TextAndLinkAndTime.empty();
  TextAndLinkAndTime({
    required this.text,
    required this.link,
    required this.time,
  });
  TextAndLinkAndTime.pos(this.text, this.link, this.time);
}

class ComplexSearchResItem {
  String title = "";
  String boardName = "";
  String boardEngName = "";
  String bid = "";
  String threadid = "";
  String userName = "";
  List<TextAndLinkAndTime> shortTexts = <TextAndLinkAndTime>[];

  ComplexSearchResItem.empty();
  ComplexSearchResItem({
    required this.title,
    required this.boardName,
    required this.boardEngName,
    required this.bid,
    required this.threadid,
    required this.userName,
    required this.shortTexts,
  });
}
class ComplexSearchRes {
  String? errorMessage;
  int maxPage = 0;
  List<ComplexSearchResItem> resItems = <ComplexSearchResItem>[];

  ComplexSearchRes.empty();
  ComplexSearchRes.error({this.errorMessage});
  ComplexSearchRes({
    required this.resItems,
    this.errorMessage,
    required this.maxPage,
  });
}

ComplexSearchRes parsePostSearch(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return ComplexSearchRes.error(errorMessage: errorMessage);
  }
  var resultDom = document.querySelector(".search-result");
  if (resultDom == null) {
    return ComplexSearchRes.empty();
  }
  var res = <ComplexSearchResItem>[];
  for (var item in resultDom.querySelectorAll(".post-block")) {
    var title = getTrimmedString(item.querySelector(".title"));
    var boardInfoDom = item.querySelector(".from");
    var boardName = "";
    var boardEngName = "";
    var bid = "";
    if (boardInfoDom != null) {
      var txt = getTrimmedString(boardInfoDom.querySelector("a"));
      var txts = txt.split(" ");
      txts.removeWhere((element) => element.isEmpty);
      boardName = txts.last;
      boardEngName = txts.first;
      bid = (boardInfoDom.querySelector("a")?.attributes["href"] ?? "").split("=").last;
    }
    var userName = getTrimmedString(item.querySelector(".name"));
    var threadid = item.attributes["data-tid"] ?? "";
    bid = item.attributes["data-bid"] ?? "";

    var shortTexts = <TextAndLinkAndTime>[];
    var briefDom = item.querySelector(".brief");
    if (briefDom != null) {
      for (var bdom in briefDom.querySelectorAll("div")) {
        var txt = getTrimmedString(bdom);
        txt = txt.replaceAll("\n", " ");
        var txtArray = txt.split(" ");
        txtArray.removeWhere((element) => element.isEmpty);
        txt = txtArray.join(" ");
        var rlink = bdom.querySelector("a")?.attributes["href"];
        var link = rlink != null ? absThreadLink(rlink) : "";
        shortTexts.add(TextAndLinkAndTime.pos(txt, link, ""));
      }
    }
    var infoItem = item.querySelector(".info");
    if (infoItem != null) {
      var i = 0;
      for (var idom in infoItem.querySelectorAll("span")) {
        if (i==0) {
          i+=1;
          continue;
        }
        shortTexts[i-1].time = getTrimmedString(idom);
        i+=1;
      }
    }

    res.add(ComplexSearchResItem(
      title: title, boardName: boardName, boardEngName: boardEngName,
      bid: bid, threadid: threadid, userName: userName, shortTexts: shortTexts,
    ));
  }
  int maxPage = 0;
  var pagingDivsDom = document.querySelectorAll(".paging div");
  for (var pdd in pagingDivsDom) {
    var txt = pdd.text;
    if (txt.startsWith("/")) {
      maxPage = int.parse(txt.substring(2)); // <div>/ 2</div>
      break;
    }
  }
  return ComplexSearchRes(resItems: res, maxPage: maxPage);
}
