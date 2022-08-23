import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import './utils.dart';
import '../utils.dart';

class FavoriteBoard {
  String boardName = "";
  String engName = "";
  String people = "";
  List<TextAndLink> admin = <TextAndLink>[];
  bool unread = true;
  String boardLink = "";
  TextAndLink lastUpdate = TextAndLink.empty();

  FavoriteBoard.init({
    required this.boardName,
    required this.engName,
    required this.people,
    required this.admin,
    required this.unread,
    required this.boardLink,
    required this.lastUpdate,
  });

  @override
  String toString() {
    return "$boardName($engName): $people $unread ${admin.length}";
  }
}

List<FavoriteBoard> parseFavoriteBoard(String htmlStr) {
  var document = parse(htmlStr);
  List<Element>? boardList = document.querySelector("#favorites-list")?.querySelectorAll(".favorite-block");
  List<FavoriteBoard> favoriteBoards = <FavoriteBoard>[];
  if (boardList == null || boardList.isEmpty) {
    return favoriteBoards;
  }
  for (var item in boardList) {
    final boardName = getTrimmedString(item.querySelector(".name"));
    final engName = getTrimmedString(item.querySelector(".eng-name"));
    final people = getTrimmedString(item.querySelector(".people"));
    final boardLink = absThreadLink(item.querySelector(".block-link")?.attributes['href'] ?? "");
    final unread = item.querySelector(".dot.red") != null ? true : false;
    var adminDom = item.querySelector(".admin")?.querySelectorAll(".inline-link");
    var adminTL = <TextAndLink>[];
    if ((adminDom != null) && (adminDom.isNotEmpty)) {
      for (var ad in adminDom) {
        var adminName = getTrimmedString(ad);
        var adminLink = absThreadLink(ad.attributes['href'] ?? "");
        adminTL.add(TextAndLink(adminName, adminLink));
      }
    }
    final lastUpdateTime = getTrimmedString(item.querySelector(".update"));
    final lastUpdatePost = absThreadLink(item.querySelector(".update")?.attributes['href'] ?? "");
    favoriteBoards.add(FavoriteBoard.init(
      boardName: boardName, engName: engName, people: people, admin: adminTL, unread: unread,
      boardLink: boardLink, lastUpdate: TextAndLink(lastUpdateTime, lastUpdatePost)
    ));
  }
  return favoriteBoards;
}

List<FavoriteBoard> getExampleFavoriteBoard() {
  const filename = '../favorite.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseFavoriteBoard(htmlStr);
  return items;
}
