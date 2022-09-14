import 'dart:convert';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as hdom;

import './constants.dart';
import '../html_parser/utils.dart';
import './html_widget.dart';

class QuillText {
  dynamic insert = "";
  Map<String, dynamic>? attributes;
  Map<String, dynamic>? info;

  QuillText({
    required this.insert,
    this.attributes,
    this.info,
  });

  QuillText.attr({
    required this.insert,
    required this.attributes,
    this.info,
  });

  static copyAttribute(Map<String, dynamic>? attr) {
    if (attr == null) { return <String, dynamic>{}; }
    return jsonDecode(jsonEncode(attr));
  }

  Map<String, dynamic> toJson() {
    var data = <String, dynamic>{'insert': insert};
    if (attributes != null) {
      data['attributes'] = attributes;
    }
    if (info != null) {
      data['info'] = info;
    }
    return data;
  }
}

List<Map> html2Quill(String htmlStr) {
  hdom.Document? document;
  try {
    document = parse(htmlStr);
  } catch (e) {
    document = null;
  }
  var res = <QuillText>[];
  if (document == null) {
    return [];
  }
  travelHtml2Quill(document.querySelector("body"), {}, res);
  return res.map((e) => e.toJson()).toList();
}

void travelHtml2Quill(hdom.Element? document, Map<String, dynamic>? attributes, List<QuillText> res) {
  if (document == null) {
    return;
  }
  document.querySelectorAll("br").forEach((element) {
    element.remove();
  });
  for (var cdom in document.nodes) {
    if (cdom.nodeType == hdom.Node.TEXT_NODE) {
      if (cdom.text == "\n") {
        continue;
      }
      res.add(QuillText(insert: cdom.text ?? "", attributes: attributes));
    } else if (cdom.nodeType == hdom.Node.ELEMENT_NODE) {
      var ele = cdom as hdom.Element;
      if (ele.localName == "font") {
        // for color
        var colorHex = ele.attributes['color'];
        var attributes2 = QuillText.copyAttribute(attributes);
        if (colorHex != null) {
          attributes2['color'] = colorHex;
        }
        travelHtml2Quill(ele, attributes2, res);
      } else if (ele.localName == "span") {
        // for background color
        var spanStyle = ele.attributes['style'];
        // var color = ele.attributes['color'];
        var bColor = ele.attributes['backgroundColor'];
        if (spanStyle != null) {
          var bcp1 = spanStyle.indexOf("background-color");
          if (bcp1 != -1) {
            var bcp2 = spanStyle.indexOf("#", bcp1);
            bColor = spanStyle.substring(bcp2, bcp2+7);
          }
        }
        var attributes2 = QuillText.copyAttribute(attributes);
        if (bColor != null) {
          attributes2['background'] = bColor;
        }
        travelHtml2Quill(ele, attributes2, res);
      } else if (ele.localName == "p") {
        if (ele.classes.contains('quotehead') || ele.classes.contains('blockquote')) {
          // 不再处理quotehead，引用部分单独处理，此处代码无用
          if (ele.classes.contains('quotehead')) {
            // res.add(QuillText(insert: '" ${ele.text}', attributes: {'color': "#aaaaaa", 'quotehead': true,
            //   'data-username': ele.attributes['data-username'] ?? "", 'data-nickname': ele.attributes['data-nickname'] ?? ""}));
            res.add(QuillText(insert: ele.text, attributes: {'color': "#aaaaaa"}, info: {'quotehead': true,
              'data-username': ele.attributes['data-username'] ?? "", 'data-nickname': ele.attributes['data-nickname'] ?? "" }));
            res.add(QuillText(insert: '\n', attributes: {'blockquote': true}));
          } else {
            res.add(QuillText(insert: ele.text, attributes: {'color': "#aaaaaa"}, info: {'blockquote': true}));
            res.add(QuillText(insert: '\n', attributes: {'blockquote': true}));
          }
        } else {
          // travelHtml2Quill(ele, {'color': "#000000"}, res);
          travelHtml2Quill(ele, {}, res);
          res.add(QuillText(insert: "\n"));
        }
        // if (cdom != document.nodes.last) {
        //   res.add(QuillText(insert: "\n"));
        // }
      } else if (ele.localName == "h5") {
        res.add(QuillText(insert: ele.text, attributes: {'bold': true, 'size': 12}));
        if (cdom != document.nodes.last) {
          res.add(QuillText(insert: "\n"));
        }
      } else if (ele.localName == "img") {
        var src = ele.attributes['src'];
        if (src == null) {
          res.add(QuillText(insert: "图片"));
        } else {
          res.add(QuillText(insert: {"image": src}));
        }
        // if (cdom != document.nodes.last) {
        //   res.add(const TextSpan(text: "\n"));
        // }
      } else if (ele.localName == "b") {
        var attributes2 = QuillText.copyAttribute(attributes);
        attributes2['bold'] = true;
        travelHtml2Quill(ele, attributes2, res);
      } else if (ele.localName == "u") {
        var attributes2 = QuillText.copyAttribute(attributes);
        attributes2['underline'] = true;
        travelHtml2Quill(ele, attributes2, res);
      } else if (ele.localName == "a") {
        var href = ele.attributes['href'];
        var link = absThreadLink(href ?? "");
        var hereColor = bdwmPrimaryColor.value.toRadixString(16);
        if (hereColor.length > 6) {
          hereColor = hereColor.substring(hereColor.length-6);
        }
        hereColor = "#$hereColor";
        res.add(QuillText(insert: getTrimmedString(ele), attributes: {'link': link, 'color': hereColor}));
      } else {
        res.add(QuillText(insert: getTrimmedString(ele)));
      }
    }
  }
}

String quill2BDWMtext(List<dynamic> quillDelta) {
  var res = <BDWMtext>[];
  int idx = quillDelta.length-1;
  while (idx >= 0) {
    var qd = quillDelta[idx];
    var attr = qd['attributes'];
    var insert = qd['insert'];
    if (attr != null) {
      if (attr['blockquote']!=null && attr['blockquote']==true) {
        // {insert: \n, attributes: {blockquote: true}}
        qd['del'] = true;
        var cidx = idx-1;
        var newInsert = insert; // \n
        while (cidx >= 0) {
          var cqd = quillDelta[cidx];
          var cinsert = cqd['insert'];
          if (cinsert is String) {
            var returnIdx = cinsert.lastIndexOf("\n");
            if (returnIdx != -1) {
              cqd['insert'] = cinsert.substring(0, returnIdx+1);
              newInsert = "${cinsert.substring(returnIdx+1)}$newInsert";
              break;
            }
          } else {
            // image
            break;
          }
          newInsert = cinsert + newInsert;
          cqd['del'] = true;
          cidx -= 1;
        }
        idx = cidx;
        quillDelta.removeWhere((element) => element['del']!=null);
        quillDelta.insert(cidx+1, {"insert": newInsert, "attributes": {'blockquoteProcessed': true}});
        continue;
      }
    }
    idx -= 1;
  }
  for (var qd in quillDelta) {
    var attr = qd['attributes'];
    var insert = qd['insert'];
    if ((insert is String)==false) { // image
      res.add(BDWMImgText(type: 'img', src: insert['image'] ?? ""));
      continue;
    }
    if (attr == null) {
      res.add(BDWMAnsiText.raw(insert));
    } else {
      bool bold = (attr['bold'] as bool?) ?? false;
      bool underline = (attr['underline'] as bool?) ?? false;
      var color = attr['color'] ?? "";
      var colorIdx = (bdwmRichText['fc'] as Map<String, int>)[color];
      var bColor = attr['background'] ?? "";
      var bColorIdx = (bdwmRichText['bc'] as Map<String, int>)[bColor];
      int foreColor = colorIdx ?? 9;
      int backColor = bColorIdx ?? 9;
      var content = insert;
      if (attr['blockquote']!=null && attr['blockquote']==true) {
        // shall not reach here
        res.add(BDWMAnsiText(type: "quote", bold: bold, underline: underline, foreColor: foreColor, backColor: backColor, content: content));
      } else if (attr['blockquoteProcessed']!=null && attr['blockquoteProcessed']==true) {
        res.add(BDWMAnsiText(type: "quote", bold: bold, underline: underline, foreColor: foreColor, backColor: backColor, content: content));
      } else {
        // normal, bold, underline, color, background color
        res.add(BDWMAnsiText(type: "ansi", bold: bold, underline: underline, foreColor: foreColor, backColor: backColor, content: content));
      }
    }
  }
  return jsonEncode(res);
}
