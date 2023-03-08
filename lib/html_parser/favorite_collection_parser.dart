import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import './utils.dart';

class FavoriteCollectionItem {
  String dataPath;
  String link;
  String collectionName;
  String name;
  String lastTime;

  FavoriteCollectionItem({
    required this.dataPath,
    required this.link,
    required this.collectionName,
    required this.name,
    required this.lastTime
  });
}

class FavoriteCollectionInfo {
  String? errorMessage;
  List<FavoriteCollectionItem> items = [];

  FavoriteCollectionInfo.empty();
  FavoriteCollectionInfo.error({required this.errorMessage});
  FavoriteCollectionInfo({
    required this.items,
    this.errorMessage,
  });
}

FavoriteCollectionInfo parseFavoriteCollection(String htmlStr) {
  var document = parse(htmlStr);
  List<Element>? topicList = document.querySelector("#favorites-list")?.querySelectorAll(".favorite-block");
  if (topicList == null) {
    return FavoriteCollectionInfo.empty();
  }
  List<FavoriteCollectionItem> favoriteCollectionItems = [];
  for (var item in topicList) {
    final dataPath = item.attributes['data-path'] ?? "";
    final link = absThreadLink(item.querySelector(".block-link")?.attributes['href'] ?? "");
    final name = getTrimmedString(item.querySelector(".name"));
    final collectionName = getTrimmedString(item.querySelector(".eng-name"));
    final lastTime = getTrimmedString(item.querySelector(".admin"));
    favoriteCollectionItems.add(FavoriteCollectionItem(link: link, name: name, collectionName: collectionName, dataPath: dataPath, lastTime: lastTime));
  }
  return FavoriteCollectionInfo(items: favoriteCollectionItems);
}
