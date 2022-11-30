import 'package:html/parser.dart' show parse;

import './utils.dart';

class BoardNoteInfo {
  String note = "";
  String? errorMessage;

  BoardNoteInfo.empty();
  BoardNoteInfo({
    required this.note,
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
  return BoardNoteInfo(note: note);
}
