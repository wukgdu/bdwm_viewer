import 'dart:io';
import 'dart:convert';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as hdom;

import './utils.dart';

class PostNewInfo {
  String bid = "";
  List<SignatureItem> quoteInfo = <SignatureItem>[];
  List<SignatureItem> signatureInfo = <SignatureItem>[];
  bool canNoreply = false;
  bool canRemind = false;
  bool canForward = false;
  bool canAnony = false;
  String? errorMessage;
  String? titleText;
  String? contentText;
  String? contentHtml;
  String? oriSignature;
  String attachpath = "";
  List<String> attachFiles = [];

  PostNewInfo.empty();
  PostNewInfo.error({required this.errorMessage});
  PostNewInfo({
    required this.bid,
    required this.signatureInfo,
    required this.canNoreply,
    required this.canRemind,
    required this.canForward,
    required this.canAnony,
    this.errorMessage,
    this.titleText,
    this.contentText,
    this.contentHtml,
    this.oriSignature,
    required this.quoteInfo,
    required this.attachpath,
    required this.attachFiles,
  });
}

PostNewInfo parsePostNew(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return PostNewInfo.error(errorMessage: errorMessage);
  }
  var editorDom = document.querySelector(".bdwm-editor");
  if (editorDom == null) {
    return PostNewInfo.empty();
  }

  var bid = editorDom.attributes['data-bid'] ?? "";

  var canNoreply = false;
  var noreplyBoxDom = editorDom.querySelector("input#input-noreply");
  if (noreplyBoxDom != null) {
    canNoreply = noreplyBoxDom.attributes['disabled']!=null ? false : true;
  }

  var canRemind = false;
  var remindBoxDom = editorDom.querySelector("input#input-remind");
  if (remindBoxDom != null) {
    canRemind = remindBoxDom.attributes['disabled']!=null ? false : true;
  }

  var canForward = false;
  var forwardBoxDom = editorDom.querySelector("input#input-forward");
  if (forwardBoxDom != null) {
    canForward = forwardBoxDom.attributes['disabled']!=null ? false : true;
  }

  var canAnony = false;
  var anonymousBoxDom = editorDom.querySelector("input#input-anonymous");
  if (anonymousBoxDom != null) {
    canAnony = anonymousBoxDom.attributes['disabled']!=null ? false : true;
  }

  var selectionsDom = editorDom.querySelectorAll(".row select.cs-select");
  hdom.Element? selectOptionDom;
  hdom.Element? quoteOptionDom;
  for (var sd in selectionsDom) {
    if (sd.attributes['data-role'] == "signature") {
      selectOptionDom = sd;
    }
    if (sd.attributes['data-role'] == "quote-mode") {
      quoteOptionDom = sd;
    }
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

  var signatureInfo = <SignatureItem>[];
  if (selectOptionDom != null) {
    for (var sodom in selectOptionDom.querySelectorAll("option")) {
      var key = getTrimmedString(sodom);
      var value = sodom.attributes['value'] ?? "";
      signatureInfo.add(SignatureItem(key: key, value: value));
    }
  }

  var quoteInfo = <SignatureItem>[];
  if (quoteOptionDom != null) {
    for (var qodom in quoteOptionDom.querySelectorAll("option")) {
      var key = getTrimmedString(qodom);
      var value = qodom.attributes['value'] ?? "";
      quoteInfo.add(SignatureItem(key: key, value: value));
    }
  }

  var titleDom = editorDom.querySelector(".title-input input");
  var titleText = titleDom?.attributes['value'] ?? "";
  var contentDom = editorDom.querySelector("#post-origin");
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

  String? oriSignature;
  var oriSigDom = editorDom.querySelector("#signature-origin");
  if (oriSigDom != null) {
    oriSignature = getTrimmedString(oriSigDom);
  }

  return PostNewInfo(
    bid: bid, signatureInfo: signatureInfo, canNoreply: canNoreply, canRemind: canRemind, canForward: canForward, canAnony: canAnony,
    titleText: titleText, contentText: contentText, contentHtml: contentHtml, oriSignature: oriSignature, quoteInfo: quoteInfo,
    attachpath: attachpath, attachFiles: attachFiles,
  );
}

PostNewInfo getExamplePostNew() {
  const filename = '../postnew.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parsePostNew(htmlStr);
  return items;
}
