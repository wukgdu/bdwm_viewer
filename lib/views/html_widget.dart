import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as hdom;
import 'package:extended_image/extended_image.dart';
// import 'package:csslib/parser.dart' as css_parser;

import "./utils.dart";
import './constants.dart';
import '../pages/read_thread.dart';
import '../html_parser/utils.dart';
import '../pages/detail_image.dart';

class WrapImageNetwork extends StatefulWidget {
  final String imgLink;
  const WrapImageNetwork({Key? key, required this.imgLink}) : super(key: key);

  @override
  State<WrapImageNetwork> createState() => _WrapImageNetworkState();
}

class _WrapImageNetworkState extends State<WrapImageNetwork> {
  CancellationToken cancelIt = CancellationToken();

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    cancelIt.cancel();
    clearMemoryImageCache();
    scheduleMicrotask(clearDiskCachedImages);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      widget.imgLink,
      fit: BoxFit.contain,
      cache: true,
      enableMemoryCache: true,
      clearMemoryCacheWhenDispose: true,
      clearMemoryCacheIfFailed: true,
      handleLoadingProgress: true,
      filterQuality: FilterQuality.high,
      cancelToken: cancelIt,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            var curByte = state.loadingProgress?.cumulativeBytesLoaded ?? 0;
            var sumByte = state.loadingProgress?.expectedTotalBytes ?? -1;
            if (sumByte == -1) {
              return const Text("加载中");
            }
            var text = "${(curByte * 100 / sumByte).toStringAsFixed(0)}%";
            // return Text(text);
            return CircularProgressIndicator(
              value: curByte / sumByte,
              semanticsLabel: '加载中',
              semanticsValue: text,
              backgroundColor: Colors.amberAccent,
            );
          case LoadState.completed:
            return null;
          case LoadState.failed:
            return const Icon(Icons.broken_image);
          default:
            return null;
        }
      },
      // printError: false,
    );
  }
}

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

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    htmlStr = widget.htmlStr;
    needSelect = widget.needSelect;
    ts = widget.ts;
  }

  @override
  Widget build(BuildContext context) {
    // return renderHtml(htmlStr, ts: ts, context: context, needSelect: needSelect);
    // var htmlStr = '''<p>asd<span style="background-color: #40ff40;">fs<font color="#c00000">a<u>d<b>fa</b></u><b>s</b></font><b>d</b></span>fa<br></p>''';
    var document = parse(htmlStr);
    var res = travelHtml(document.querySelector("body"), context: context);
    var tspan = TextSpan(
      children: res,
      style: ts,
    );
    if (needSelect != null && needSelect == false) {
      return Text.rich(
        tspan,
      );
    }
    return SelectionArea(
      child: Text.rich(
        tspan,
      ),
    );
  }
}

TextSpan html2TextSpan(String htmlStr, {TextStyle? ts}) {
  var document = parse(htmlStr);
  var res = travelHtml(document.querySelector("body"), context: null);
  var tspan = TextSpan(
    children: res,
    style: ts,
  );
  return tspan;
}

List<InlineSpan>? travelHtml(hdom.Element? document, {BuildContext? context}) {
  if (document == null) {
    return null;
  }
  var res = <InlineSpan>[];
  document.querySelectorAll("br").forEach((element) {
    element.remove();
  });
  for (var cdom in document.nodes) {
    if (cdom.nodeType == hdom.Node.TEXT_NODE) {
      res.add(TextSpan(text: cdom.text));
    } else if (cdom.nodeType == hdom.Node.ELEMENT_NODE) {
      var ele = cdom as hdom.Element;
      if (ele.localName == "font") {
        // for color
        var color = ele.attributes['color'];
        // var bColor = ele.attributes['background-color'];
        res.add(TextSpan(children: travelHtml(ele, context: context),
          style: TextStyle(
            color: color!=null?Color(int.parse("0xff${color.substring(1)}")):null,
            // backgroundColor: bColor!=null?Color(int.parse("0xff${bColor.substring(1)}")) : null,
          ),),
        );
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
          // var cp1 = spanStyle.indexOf("color");
          // if (cp1 != -1) {
          //   var cp2 = spanStyle.indexOf("#", cp1);
          //   // color = spanStyle.substring(cp2, cp2+7);
          // }
        }
        res.add(TextSpan(children: travelHtml(ele, context: context),
          style: TextStyle(
            // color: color!=null?Color(int.parse("0xff${color.substring(1)}")):null,
            backgroundColor: bColor!=null?Color(int.parse("0xff${bColor.substring(1)}")) : null,
          ),),
        );
      } else if (ele.localName == "p") {
        if (ele.classes.contains('quotehead') || ele.classes.contains('blockquote')) {
          res.add(const WidgetSpan(child: Icon(Icons.format_quote, size: 14, color: Color(0xffA6DDE3))));
          res.add(TextSpan(text: ele.text, style: const TextStyle(color: Colors.grey, fontSize: 12)));
        } else {
          res.add(TextSpan(
            children: travelHtml(ele, context: context),
            style: const TextStyle(color: Colors.black, backgroundColor: null),
          ));
        }
        if (cdom != document.nodes.last) {
          res.add(const TextSpan(text: "\n"));
        }
      } else if (ele.localName == "h5") {
        res.add(TextSpan(text: ele.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
        if (cdom != document.nodes.last) {
          res.add(const TextSpan(text: "\n"));
        }
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
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                  // alignment: Alignment.centerLeft,
                  child: Image.memory(data,)
                ),
                onTap: () {
                  if (context != null) {
                    gotoDetailImage(context: context, link: "", imgData: data, name: "image.jpg");
                  }
                },
              )));
          } else {
            res.add(WidgetSpan(
              child: GestureDetector(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                  // alignment: Alignment.centerLeft,
                  child: WrapImageNetwork(imgLink: src,),
                  // child: Image.network(
                  //   src,
                  //   errorBuilder: (context, error, stackTrace) {
                  //     return const Center(child: Icon(Icons.broken_image));
                  //   },
                  // ),
                ),
                onTap: () {
                  if (context != null) {
                    gotoDetailImage(context: context, link: src, imgData: null, name: "image.jpg");
                  }
                }),
            ));
          }
        }
        if (cdom != document.nodes.last) {
          res.add(const TextSpan(text: "\n"));
        }
      } else if (ele.localName == "b") {
        res.add(TextSpan(children: travelHtml(ele, context: context), style: const TextStyle(fontWeight: FontWeight.bold,)));
      } else if (ele.localName == "u") {
        res.add(TextSpan(children: travelHtml(ele, context: context), style: const TextStyle(decoration: TextDecoration.underline)));
      } else if (ele.localName == "a") {
        var href = ele.attributes['href'];
        var link = absThreadLink(href ?? "");
        var ts = WidgetSpan(
          child: GestureDetector(
            child: Text.rich(
              TextSpan(
                children: travelHtml(ele, context: context),
                style: textLinkStyle,
              ),
            ),
            onTap: () {
              if (context == null) {
                return;
              }
              if (href == null) { return; }
              if (link.startsWith("https://bbs.pku.edu.cn/v2/post-read.php")) {
                naviGotoThreadByLink(context, link, "跳转");
              } else if (link.startsWith("https://bbs.pku.edu.cn/v2/thread.php")) {
                var bidP1 = link.indexOf("bid=");
                var bidP2 = link.indexOf("&", bidP1);
                var bid = "";
                if (bidP2 == -1) {
                  bid = link.substring(bidP1+4);
                } else {
                  bid = link.substring(bidP1+4, bidP2);
                }
                if (bid.isNotEmpty) {
                  Navigator.of(context).pushNamed('/thread', arguments: {
                    'bid': bid,
                    'boardName': "跳转",
                  });
                }
              }
            },
          ),
        );
        res.add(ts);
      } else {
        res.add(TextSpan(text: cdom.text));
      }
    }
  }
  return res;
}