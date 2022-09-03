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
