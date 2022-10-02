import '../globalvars.dart';

import 'package:html/dom.dart' show Text, Document;
import 'package:html_unescape/html_unescape_small.dart';

var _unescapeInstance = HtmlUnescape();
String unescapeHtmlStr(String htmlStr) {
  return _unescapeInstance.convert(htmlStr);
}

String? checkError(Document document) {
  if (document.querySelector("#page-error") != null) {
    var errBodyDom = document.querySelector("#error-body p");
    var errorMessage = errBodyDom?.firstChild?.text ?? "出错啦";
    return errorMessage;
  }
  return null;
}

String? tryGetNormalSpaceString(String? dom) {
  if (dom == null) { return null; }
  return dom.replaceAll("\u00a0", " ");
}

String getNormalSpaceString(String dom) {
  return dom.replaceAll("\u00a0", " ");
}

String getTrimmedString(var dom) {
  if (dom == null) {
    return "";
  }
  var resStr = "";
  if (dom is String) {
    resStr = dom.trim();
  } else {
    resStr = dom.text.trim();
  }
  // &nbsp;[\u00a0;160] -> [\u0020;32]
  resStr = resStr.replaceAll("\u00a0", " ");
  return resStr;
}

String getTrimmedHtml(var dom) {
  if (dom == null) {
    return "";
  }
  var resStr = "";
  if (dom is Text) {
    resStr = dom.text.trim();
  } else {
    resStr = dom.innerHtml.trim();
  }
  resStr = resStr.replaceAll("\u00a0", " ");
  return resStr;
}

String getTrimmedOuterHtml(var dom) {
  if (dom == null) {
    return "";
  }
  var resStr = "";
  if (dom is Text) {
    resStr = dom.text.trim();
  } else {
    resStr = dom.outerHtml.trim();
  }
  resStr = resStr.replaceAll("\u00a0", " ");
  return resStr;
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
  if (link.startsWith("http")) {
    return link;
  }
  if (link.startsWith('/')) {
    var res = bbsHost + link;
    return res;
  }
  return "$v2Host/$link";
}

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
