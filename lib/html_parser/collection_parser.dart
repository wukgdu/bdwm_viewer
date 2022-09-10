import 'dart:io';

import 'package:html/parser.dart' show parse;
// import 'package:html/dom.dart';

import '../globalvars.dart';
import './utils.dart';
import './read_thread_parser.dart';

class CollectionItem {
  int id = 0;
  String name = "";
  String type = "";
  String path = "";
  String author = "";
  String time = "";
  String link = "";

  CollectionItem.empty();
  CollectionItem({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    required this.author,
    required this.time,
    required this.link,
  });
}

class CollectionList {
  List<CollectionItem> collectionItems = <CollectionItem>[];
  int maxPage = 0;
  String? errorMessage;

  CollectionList.empty();
  CollectionList.error({
    required this.errorMessage,
  });
  CollectionList({
    required this.collectionItems,
    this.errorMessage,
    required this.maxPage,
  });
}

CollectionList parseCollectionList(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return CollectionList.error(errorMessage: errorMessage);
  }
  var listDom = document.querySelector(".collection-list");
  if (listDom == null) {
    return CollectionList.empty();
  }
  var listItemsDom = listDom.querySelectorAll(".collection-item");
  List<CollectionItem> collectionItems = <CollectionItem>[];
  for (var item in listItemsDom) {
    int id = int.parse(getTrimmedString(item.querySelector(".item-id")));
    String name = getTrimmedString(item.querySelector(".item-name"));
    String type = item.attributes['data-type'] ?? "file";
    String author = getTrimmedString(item.querySelector(".item-author"));
    String time = getTrimmedString(item.querySelector(".item-time"));
    String path = item.querySelector(".item-name")?.attributes['href'] ?? "";
    String link = absThreadLink(path);
    collectionItems.add(CollectionItem(id: id, name: name, type: type, path: path, author: author, time: time, link: link));
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
  return CollectionList(collectionItems: collectionItems, maxPage: maxPage);
}

CollectionList getExampleCollectionList() {
  const filename = '../collection.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseCollectionList(htmlStr);
  return items;
}

CollectionArticle getExampleCollectionArticle() {
  const filename = '../collection-article.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseCollectionArticle(htmlStr);
  return items;
}

class CollectionArticle {
  String user = "";
  String uid = "";
  String avatar = absImgSrc(defaultAvator);
  String title = "";
  String content = "";
  String time = "";
  String attachmentHtml = "";
  List<AttachmentInfo> attachmentInfo = <AttachmentInfo>[];
  String? errorMessage;

  CollectionArticle.empty();
  CollectionArticle.error({required this.errorMessage,});
  CollectionArticle({
    required this.user,
    required this.uid,
    required this.avatar,
    required this.title,
    required this.content,
    required this.attachmentHtml,
    required this.attachmentInfo,
    required this.time,
    this.errorMessage,
  });
}

CollectionArticle parseCollectionArticle(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return CollectionArticle.error(errorMessage: errorMessage);
  }
  var contentDom = document.querySelector(".collection-body");
  if (contentDom == null) {
    return CollectionArticle.empty();
  }
  String title = "";
  String uid = "";
  String user = "";
  String avatar = absImgSrc(contentDom.querySelector(".portrait")?.attributes['src'] ?? defaultAvator);
  var titleDom = contentDom.querySelector(".title");
  if (titleDom != null) {
    title = getTrimmedString(titleDom.children.first);
    uid = (titleDom.querySelector(".sender a")?.attributes['href'] ?? "").split("=").last;
    user = getTrimmedString(titleDom.querySelector(".sender a"));
  }
  var content = getTrimmedHtml(contentDom.querySelector(".file-read"));
  var attachmentInfo = <AttachmentInfo>[];
  var attachmentDom = contentDom.querySelector(".attachment");
  var attachmentHtml = "";
  // int attachmentSlidesCount = 0;
  if (attachmentDom != null) {
    var attachmentsDom = attachmentDom.querySelectorAll("li");
    attachmentHtml = getTrimmedOuterHtml(attachmentDom.querySelector("ul"));
    for (var adom in attachmentsDom) {
      var a = adom.querySelector("a");
      if (a == null) {
        continue;
      }
      var name = getTrimmedString(a);
      var link = a.attributes['href']?.trim() ?? "";
      var size = getTrimmedString(adom.querySelector(".size"));
      var thumbnailLink = "";
      AttachmentType aType = AttachmentType.showText;
      if (a.classes.contains("highslide")) {
        aType = AttachmentType.showThumbnail;
        thumbnailLink = getTrimmedString(adom.querySelector("img")?.attributes['src']);
        name = getTrimmedString(adom.querySelector("img")?.attributes['alt']);
        // attachmentSlidesCount += 1;
      }
      attachmentInfo.add(AttachmentInfo(text: name, link: link, size: size, type: aType, thumbnailLink: thumbnailLink));
    }
  }
  var time = getTrimmedString(contentDom.querySelector(".content .right"));
  return CollectionArticle(
    user: user, uid: uid, avatar: avatar, title: title, content: content,
    attachmentHtml: attachmentHtml, attachmentInfo: attachmentInfo, time: time,
  );
}