import 'dart:convert';

import 'package:html/parser.dart' show parse;

import './utils.dart';

class CollectionNewInfo {
  String? errorMessage;
  String? titleText;
  String? contentText;
  String? contentHtml;
  String attachpath = "";
  List<String> attachFiles = [];

  CollectionNewInfo.empty();
  CollectionNewInfo.error({required this.errorMessage});
  CollectionNewInfo({
    this.errorMessage,
    this.titleText,
    this.contentText,
    this.contentHtml,
    required this.attachpath,
    required this.attachFiles,
  });
}

CollectionNewInfo parseCollectionNew(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return CollectionNewInfo.error(errorMessage: errorMessage);
  }
  var editorDom = document.querySelector(".bdwm-editor");
  if (editorDom == null) {
    return CollectionNewInfo.empty();
  }

  var attachpath = "";
  var attachFiles = <String>[];
  var uploadDom = editorDom.querySelector("a[data-action=file-upload]");
  if (uploadDom != null) {
    attachpath = uploadDom.attributes['data-upload-dir'] ?? "";
    var attachStr = uploadDom.attributes['data-file-list'] ?? "";
    if (attachStr.isNotEmpty) {
      // attachStr = attachStr.replaceAll("&quot;", '');
      attachStr = unescapeHtmlStr(attachStr);
      var jsonContent = jsonDecode(attachStr);
      for (var jstr in jsonContent) {
        attachFiles.add(jstr);
      }
    }
  }

  var titleDom = editorDom.querySelector(".title-input input");
  var titleText = titleDom?.attributes['value'] ?? "";
  var contentDom = editorDom.querySelector("#collection-origin");
  var contentText = "";
  var pCount = contentDom?.querySelectorAll("p").length ?? 0;
  if (contentDom!=null) {
    for (var cdom in contentDom.querySelectorAll("p")) {
      pCount -= 1;
      contentText += getNormalSpaceString(cdom.text);
      if (pCount > 0) {
        contentText += "\n";
      }
    }
  }
  var contentHtml = getTrimmedHtml(contentDom);

  return CollectionNewInfo(
    titleText: titleText, contentText: contentText, contentHtml: contentHtml,
    attachpath: attachpath, attachFiles: attachFiles,
  );
}
