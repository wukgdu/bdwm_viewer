import 'package:html/parser.dart' show parse;

import './utils.dart';

class MailNewInfo {
  String? errorMessage;
  List<SignatureItem> quoteInfo = <SignatureItem>[];
  List<SignatureItem> signatureInfo = <SignatureItem>[];
  String attachpath = "";
  int sigCount = 0;
  String title = "";
  String receivers = "";

  MailNewInfo.empty();
  MailNewInfo.error({
    required this.errorMessage,
  });
  MailNewInfo({
    required this.signatureInfo,
    required this.attachpath,
    required this.quoteInfo,
    required this.sigCount,
    required this.title,
    required this.receivers,
  });
}

MailNewInfo parseMailNew(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return MailNewInfo.error(errorMessage: errorMessage);
  }
  var editorDom = document.querySelector(".bdwm-editor");
  if (editorDom == null) {
    return MailNewInfo.empty();
  }
  var selectOptionDom = editorDom.querySelector(".row select.cs-select[data-role=signature]");
  var quoteOptionDom = editorDom.querySelector(".row select.cs-select[data-role=quote-mode]");

  var signatureInfo = <SignatureItem>[];
  int sigCount = 0;
  if (selectOptionDom != null) {
    sigCount = int.parse(selectOptionDom.attributes['data-signature-count'] ?? "0");
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

  var attachpath = "";
  var uploadDom = editorDom.querySelector("a[data-action=file-upload]");
  if (uploadDom != null) {
    attachpath = uploadDom.attributes['data-upload-dir'] ?? "";
  }

  var titleDom = editorDom.querySelector("input[data-role=mail-title]");
  var title = getTrimmedString(titleDom?.attributes['value'] ?? "");
  var rciDom = editorDom.querySelector("input[data-role=receivers]");
  var receivers = getTrimmedString(rciDom?.attributes['value'] ?? "");
  return MailNewInfo(
    signatureInfo: signatureInfo, attachpath: attachpath, quoteInfo: quoteInfo,
    sigCount: sigCount, title: title, receivers: receivers,
  );
}