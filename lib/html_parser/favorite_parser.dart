import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import './utils.dart' show getTrimmedString, absThreadLink, checkError;
import '../utils.dart' show TextAndLink;
import './board_parser.dart' show AdminInfo;

class FavoriteBoard {
  String boardName = "";
  String engName = "";
  String people = "";
  List<AdminInfo> admin = <AdminInfo>[];
  bool unread = true;
  String boardLink = "";
  TextAndLink lastUpdate = TextAndLink.empty();
  bool readOnly = false;

  FavoriteBoard.init({
    required this.boardName,
    required this.engName,
    required this.people,
    required this.admin,
    required this.unread,
    required this.boardLink,
    required this.lastUpdate,
    required this.readOnly,
  });

  @override
  String toString() {
    return "$boardName($engName): $people $unread ${admin.length}";
  }
}

class FavoriteBoardInfo {
  String? errorMessage;
  List<FavoriteBoard> favoriteBoards = <FavoriteBoard>[];

  FavoriteBoardInfo.empty();
  FavoriteBoardInfo.error({this.errorMessage});
  FavoriteBoardInfo({
    this.errorMessage,
    required this.favoriteBoards,
  });
}

FavoriteBoardInfo parseFavoriteBoard(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return FavoriteBoardInfo.error(errorMessage: errorMessage);
  }
  List<Element>? boardList = document.querySelector("#favorites-list")?.querySelectorAll(".favorite-block");
  List<FavoriteBoard> favoriteBoards = <FavoriteBoard>[];
  if (boardList == null || boardList.isEmpty) {
    return FavoriteBoardInfo(favoriteBoards: favoriteBoards);
  }
  for (var item in boardList) {
    final boardName = getTrimmedString(item.querySelector(".name"));
    final engName = getTrimmedString(item.querySelector(".eng-name"));
    final people = getTrimmedString(item.querySelector(".people"));
    final boardLink = absThreadLink(item.querySelector(".block-link")?.attributes['href'] ?? "");
    final unread = item.querySelector(".dot.red") != null ? true : false;
    var adminDom = item.querySelector(".admin")?.querySelectorAll(".inline-link");
    var adminTL = <AdminInfo>[];
    if ((adminDom != null) && (adminDom.isNotEmpty)) {
      for (var ad in adminDom) {
        var adminName = getTrimmedString(ad);
        var adminLink = absThreadLink(ad.attributes['href'] ?? "");
        var uid = ad.attributes['href']?.split("=").last ?? "15265";
        adminTL.add(AdminInfo(userName: adminName, link: adminLink, uid: uid));
      }
    }
    var readOnly = item.querySelector(".readonly") != null;
    final lastUpdateTime = getTrimmedString(item.querySelector(".update"));
    final lastUpdatePost = absThreadLink(item.querySelector(".update")?.attributes['href'] ?? "");
    favoriteBoards.add(FavoriteBoard.init(
      boardName: boardName, engName: engName, people: people, admin: adminTL, unread: unread,
      boardLink: boardLink, lastUpdate: TextAndLink(lastUpdateTime, lastUpdatePost), readOnly: readOnly,
    ));
  }
    return FavoriteBoardInfo(favoriteBoards: favoriteBoards);
}

FavoriteBoardInfo getExampleFavoriteBoard() {
  const filename = '../favorite.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseFavoriteBoard(htmlStr);
  return items;
}
