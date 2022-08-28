import 'dart:convert';

import 'package:bdwm_viewer/pages/detail_image.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as hdom;

import "./utils.dart";

class HtmlComponent extends StatefulWidget {
  final String htmlStr;
  final bool? needSelect;
  final TextStyle? ts;
  const HtmlComponent(this.htmlStr, {Key? key, this.needSelect, this.ts}) : super(key: key);

  @override
  State<HtmlComponent> createState() => _HtmlComponentState();
}

class _HtmlComponentState extends State<HtmlComponent> {
  String htmlStr = "";
  bool? needSelect;
  TextStyle? ts;
  
  @override
  void initState() {
    super.initState();
    htmlStr = widget.htmlStr;
    needSelect = widget.needSelect;
    ts = widget.ts;
  }

  TextSpan travel(hdom.Element? document) {
    var res = <InlineSpan>[];
    if (document == null) {
      return TextSpan(
        children: res,
      );
    }
    document.querySelectorAll("br").forEach((element) {
      element.remove();
    });
    for (var cdom in document.nodes) {
      if (cdom.nodeType == hdom.Node.TEXT_NODE) {
        res.add(TextSpan(text: cdom.text));
      } else if (cdom.nodeType == hdom.Node.ELEMENT_NODE) {
        var ele = cdom as hdom.Element;
        if (ele.localName == "font") {
          var color = ele.attributes['color'];
          var bColor = ele.attributes['backgroundColor'];
          res.add(TextSpan(children: travel(ele).children,
            style: TextStyle(
              color: color!=null?Color(int.parse("0xff${color.substring(1)}")):null,
              backgroundColor: bColor!=null?Color(int.parse("0xff${bColor.substring(1)}")) : null,
            ),),
          );
        } else if (ele.localName == "p") {
          if (ele.classes.contains('quotehead') || ele.classes.contains('blockquote')) {
            res.add(const WidgetSpan(child: Icon(Icons.format_quote, size: 14, color: Color(0xffA6DDE3))));
            res.add(TextSpan(text: ele.text, style: const TextStyle(color: Colors.grey, fontSize: 12)));
          } else {
            res.add(travel(ele));
          }
          if (cdom != document.nodes.last) {
            res.add(const TextSpan(text: "\n"));
          }
        } else if (ele.localName == "h5") {
          res.add(TextSpan(text: ele.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
          res.add(const TextSpan(text: "\n"));
        } else if (ele.localName == "img") {
          var src = ele.attributes['src'];
          if (src == null) {
            res.add(const WidgetSpan(child: Text("图片"),));
          } else {
            if (src.startsWith("data")) {
              var p1 = src.indexOf("base64,");
              var str = src.substring(p1+7);
              var data = base64Decode(str);
              res.add(WidgetSpan(
                child: GestureDetector(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    // alignment: Alignment.centerLeft,
                    child: Image.memory(data,)
                  ),
                  onTap: () {
                    gotoDetailImage(context: context, link: "", imgData: data, name: "image.jpg");
                  },
                )));
            } else {
              res.add(WidgetSpan(
                child: GestureDetector(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    // alignment: Alignment.centerLeft,
                    child: Image.network(src,)
                  ),
                  onTap: () {
                    gotoDetailImage(context: context, link: src, imgData: null, name: "image.jpg");
                  }),
              ));
            }
          }
          if (cdom != document.nodes.last) {
            res.add(const TextSpan(text: "\n"));
          }
        } else if (ele.localName == "b") {
          res.add(TextSpan(children: travel(ele).children, style: const TextStyle(fontWeight: FontWeight.bold)));
        } else if (ele.localName == "u") {
          res.add(TextSpan(children: travel(ele).children, style: const TextStyle(decoration: TextDecoration.underline)));
        }
      }
    }
    return TextSpan(
      children: res,
      style: ts,
    );
  }

  @override
  Widget build(BuildContext context) {
    // return renderHtml(htmlStr, ts: ts, context: context, needSelect: needSelect);
    var document = parse(htmlStr);
    if (needSelect != null && needSelect == true) {
      return SelectableText.rich(
        travel(document.querySelector("body")),
        cursorWidth: 0,
      );
    }
    return Text.rich(
      travel(document.querySelector("body")),
    );
  }
}