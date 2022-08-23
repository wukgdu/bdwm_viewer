import '../globalvars.dart';

String getTrimmedString(var dom) {
  return dom?.text.trim();
}

String getTrimmedHtml(var dom) {
  return dom?.innerHtml.trim();
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
