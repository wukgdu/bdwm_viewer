import '../globalvars.dart';
import 'package:html/dom.dart' show Text;

String getTrimmedString(var dom) {
  if (dom == null) {
    return "";
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
