import 'dart:io';

import 'package:html/parser.dart' show parse;

import './utils.dart';

class SignatureItem {
  String key = "无";
  String value = "";

  SignatureItem.empty();
  SignatureItem({
    required this.key,
    required this.value,
  });

  @override
  String toString() {
    return key;
  }
}

class PostNewInfo {
  String bid = "";
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

  var signatureInfo = <SignatureItem>[];

  var selectOptionDom = editorDom.querySelector("select.cs-select");
  if (selectOptionDom != null) {
    for (var sodom in selectOptionDom.querySelectorAll("option")) {
      var key = getTrimmedString(sodom);
      var value = sodom.attributes['value'] ?? "";
      signatureInfo.add(SignatureItem(key: key, value: value));
    }
  }

  var titleDom = editorDom.querySelector(".title-input input");
  var titleText = titleDom?.attributes['value'] ?? "";
  var contentDom = editorDom.querySelector("#post-origin");
  var contentText = "";
  var pCount = contentDom?.querySelectorAll("p").length ?? 0;
  for (var cdom in contentDom?.querySelectorAll("p") ?? []) {
    pCount -= 1;
    contentText += cdom.text;
    if (pCount > 0) {
      contentText += "\n";
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
    titleText: titleText, contentText: contentText, contentHtml: contentHtml, oriSignature: oriSignature,
  );
}

PostNewInfo getExamplePostNew() {
  const filename = '../postnew.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parsePostNew(htmlStr);
  return items;
}
