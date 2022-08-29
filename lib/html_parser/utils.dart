import '../globalvars.dart';
import 'package:html/dom.dart' show Text, Document;

String? checkError(Document document) {
  if (document.querySelector("#page-error") != null) {
    var errBodyDom = document.querySelector("#error-body p");
    var errorMessage = errBodyDom?.firstChild?.text ?? "出错啦";
    return errorMessage;
  }
  return null;
}

String getTrimmedString(var dom) {
  if (dom == null) {
    return "";
  }
  if (dom is String) {
    return dom.trim();
  }
  return dom.text.trim();
}

String getTrimmedHtml(var dom) {
  if (dom == null) {
    return "";
  }
  if (dom is Text) {
    return dom.text.trim();
  }
  return dom.innerHtml.trim();
}

String getTrimmedOuterHtml(var dom) {
  if (dom == null) {
    return "";
  }
  if (dom is Text) {
    return dom.text.trim();
  }
  return dom.outerHtml.trim();
}

String absImgSrc(String src) {
  var res = src;
  if (src.startsWith("http")) {
    return res;
  }
  if (src.startsWith('/')) {
    res = bbsHost + src;
  } else {
    res = "$v2Host/$src";
  }
  return res;
}

String absThreadLink(String link) {
  return "$v2Host/$link";
}
