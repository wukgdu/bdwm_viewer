import 'dart:convert';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as hdom;

import './constants.dart';
import '../html_parser/utils.dart';
import './html_widget.dart';

class QuillText {
  dynamic insert = "";
  Map<String, dynamic>? attributes;

  QuillText({
    required this.insert,
    this.attributes,
  });

  QuillText.attr({
    required this.insert,
    required this.attributes,
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
  // document.querySelectorAll("br").forEach((element) {
  //   element.remove();
  // });
  for (var cdom in document.nodes) {
    if (cdom.nodeType == hdom.Node.TEXT_NODE) {
      if (cdom.text == "\n") {
        continue;
      }
      res.add(QuillText(insert: getNormalSpaceString(cdom.text ?? ""), attributes: attributes));
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
          if (ele.classes.contains('quotehead')) {
            // retain quotehead info
            res.add(QuillText(insert: getNormalSpaceString(ele.text)));
            res.add(QuillText(insert: '\n', attributes: {'blockquote': true, 'quotehead': true,
              'data-username': ele.attributes['data-username'] ?? "",
              'data-nickname': ele.attributes['data-nickname'] ?? "",
              'data-mail': ele.attributes['data-mail'] ?? false,
            }));
          } else {
            res.add(QuillText(insert: getNormalSpaceString(ele.text)));
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
          res.add(QuillText(insert: "[未知图片]"));
        } else if (ele.classes.contains("tex")) {
          res.add(QuillText(insert: ele.attributes['alt'] ?? "[未知tex]"));
        // } else if (src.startsWith("data")) {
        //   res.add(QuillText(insert: "[不支持data图片]"));
        } else {
          res.add(QuillText(insert: {"image": absImgSrc(src)}));
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
        var hereColor = bdwmPrimaryColor.toARGB32().toRadixString(16);
        if (hereColor.length > 6) {
          hereColor = hereColor.substring(hereColor.length-6);
        }
        hereColor = "#$hereColor";
        res.add(QuillText(insert: getTrimmedString(ele), attributes: {'link': link, 'color': hereColor}));
      } else if (ele.localName == "br") {
        if (cdom != document.nodes.last) {
          res.add(QuillText(insert: "\n"));
        }
      } else {
        res.add(QuillText(insert: getTrimmedString(ele)));
      }
    }
  }
}

String quill2BDWMtext(List<dynamic> quillDelta, {bool removeLastReturn=false}) {
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
        if (attr['quotehead']!=null && attr['quotehead']==true) {
          quillDelta.insert(cidx+1, {"insert": newInsert, "attributes": {'quoteheadProcessed': true,
            'data-username': attr['data-username'] ?? "",
            'data-nickname': attr['data-nickname'] ?? "",
            'data-mail': attr['data-mail'] ?? false,
          }});
        } else {
          quillDelta.insert(cidx+1, {"insert": newInsert, "attributes": {'blockquoteProcessed': true}});
        }
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
      } else if (attr['quoteheadProcessed']!=null && attr['quoteheadProcessed']==true) {
        res.add(BDWMQuoteText(mail: attr['data-mail'], type: "quotehead", nickname: attr['data-nickname'], username: attr['data-username']));
      } else {
        // normal, bold, underline, color, background color
        res.add(BDWMAnsiText(type: "ansi", bold: bold, underline: underline, foreColor: foreColor, backColor: backColor, content: content));
      }
    }
  }
  if (removeLastReturn && res.isNotEmpty) {
    if (res.last is BDWMAnsiText) {
      var l = res.last as BDWMAnsiText;
      if (l.content.endsWith("\n")) {
        l.content = l.content.substring(0, l.content.length-1);
        if (l.content.isEmpty) {
          res.removeLast();
        }
      }
    }
  }
  return jsonEncode(res);
}
