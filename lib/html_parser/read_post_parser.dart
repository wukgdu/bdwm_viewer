import 'package:html/parser.dart' show parse;

import '../utils.dart' show TextAndLink, getQueryValue;
import './utils.dart';
import './read_thread_parser.dart' show parseOnePost, OnePostInfo;

class SinglePostInfo {
  String blockid = "";
  String boardid = "";
  String threadid = "";
  String title = "";
  String threadLink = "";
  TextAndLink board = TextAndLink.empty();
  OnePostInfo postInfo = OnePostInfo.empty();
  String? errorMessage;

  SinglePostInfo.empty();
  SinglePostInfo.error({this.errorMessage});
  SinglePostInfo({
    required this.blockid,
    required this.boardid,
    required this.threadid,
    required this.title,
    required this.board,
    required this.postInfo,
    required this.threadLink,
    this.errorMessage,
  });
}

SinglePostInfo parseSinglePost(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return SinglePostInfo.error(errorMessage: errorMessage);
  }
  var title = "";
  var blockid = "", boardid = "", threadid = "";
  var linkDom = document.querySelector(".breadcrumb-trail");
  var boardName = "", boardLink = "";
  if (linkDom != null) {
    var linksDom = linkDom.querySelectorAll("a");
    for (var ld in linksDom) {
      var href = ld.attributes['href'];
      if (href==null) {
        continue;
      }
      if (href.startsWith("board")) {
        blockid = getQueryValue(href, 'bid') ?? "";
      } else if (href.startsWith("thread")) {
        boardid = getQueryValue(href, 'bid') ?? "";
        boardName = getTrimmedString(ld);
        boardLink = absThreadLink(href);
      } else if (href.contains("post-read")) {
        threadid = getQueryValue(href, "threadid") ?? "";
        title = getTrimmedString(ld);
      }
    }
  }
  var postInfo = OnePostInfo.empty();
  var postCardDom = document.querySelector(".post-card");
  if (postCardDom != null) {
    postInfo = parseOnePost(postCardDom);
  }
  var threadLink = document.querySelector(".view-full-post")?.attributes['href'] ?? "";
  if (threadLink.isNotEmpty) {
    threadLink = absThreadLink(threadLink);
  }
  return SinglePostInfo(
    blockid: blockid, boardid: boardid, threadid: threadid, title: title, board: TextAndLink(boardName, boardLink),
    postInfo: postInfo, threadLink: threadLink,
  );
}
