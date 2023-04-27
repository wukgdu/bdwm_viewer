import 'package:html/parser.dart' show parse;

import './utils.dart';

class BoardNoteInfo {
  String note = "";
  String? boardName = "";
  String? errorMessage;

  BoardNoteInfo.empty();
  BoardNoteInfo({
    required this.note,
    this.boardName,
  });
  BoardNoteInfo.error({
    required this.errorMessage,
  });
}

BoardNoteInfo parseBoardNoteInfo(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return BoardNoteInfo.error(errorMessage: errorMessage);
  }
  String note = "";
  var noteDom = document.querySelector("#note-content");
  if (noteDom != null) {
    note = noteDom.innerHtml;
  }

  String? boardName;
  var headDom = document.querySelector("#board-head");
  if (headDom != null) {
    boardName = getTrimmedString(headDom.querySelector('#title .black'));
  }
  return BoardNoteInfo(note: note, boardName: boardName);
}
