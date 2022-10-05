import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as hdom;
import 'package:extended_image/extended_image.dart';
import 'package:url_launcher/url_launcher.dart';

import "./utils.dart";
import './constants.dart';
import '../bdwm/req.dart';
import '../pages/read_thread.dart';
import '../html_parser/utils.dart';
import '../globalvars.dart' show genHeaders2;
import '../html_parser/board_parser.dart' show directToThread;
import '../pages/detail_image.dart';
import '../router.dart' show nv2Push;

class WrapImageNetwork extends StatefulWidget {
  final String imgLink;
  final String? imgAlt;
  const WrapImageNetwork({Key? key, required this.imgLink, this.imgAlt}) : super(key: key);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if ("://".allMatches(widget.imgLink).length > 1) {
      return const Icon(Icons.broken_image);
    }

    try {

    return ExtendedImage.network(
      widget.imgLink,
      fit: BoxFit.contain,
      cache: true,
      enableMemoryCache: true,
      clearMemoryCacheWhenDispose: false,
      clearMemoryCacheIfFailed: true,
      handleLoadingProgress: true,
      filterQuality: FilterQuality.low,
      cancelToken: cancelIt,
      timeLimit: const Duration(seconds: 30),
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            if (state.loadingProgress == null) { return null; }
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
            return GestureDetector(
              onDoubleTap: () {
                state.reLoadImage();
              },
              child: widget.imgAlt == null
              ? const Icon(Icons.broken_image)
              : Text.rich(TextSpan(
                children: [
                  const WidgetSpan(child: Icon(Icons.broken_image)),
                  TextSpan(text: widget.imgAlt),
                ]
              )),
            );
          default:
            return null;
        }
      },
      // printError: false,
    );

    } catch (e) {
      return const Icon(Icons.broken_image);
    }
  }
}

class HtmlComponent extends StatefulWidget {
  final String htmlStr;
  final bool? needSelect;
  final TextStyle? ts;
  final String? nickName;
  const HtmlComponent(this.htmlStr, {Key? key, this.needSelect, this.ts, this.nickName}) : super(key: key);

  @override
  State<HtmlComponent> createState() => _HtmlComponentState();
}

class _HtmlComponentState extends State<HtmlComponent> {
  String htmlStr = "";
  bool? needSelect;
  TextStyle? ts;
  String? nickName;
  
  @override
  void initState() {
    super.initState();
    htmlStr = widget.htmlStr;
    needSelect = widget.needSelect;
    ts = widget.ts;
    nickName = widget.nickName;
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    htmlStr = widget.htmlStr;
    needSelect = widget.needSelect;
    ts = widget.ts;
    nickName = widget.nickName;
  }

  @override
  Widget build(BuildContext context) {
    // var htmlStr = '''<p>asd<span style="background-color: #40ff40;">fs<font color="#c00000">a<u>d<b>fa</b></u><b>s</b></font><b>d</b></span>fa<br></p>''';
    var document = parse(htmlStr);
    var res = travelHtml(document.querySelector("body"), context: context, ts: ts, nickName: nickName);
    var tspan = TextSpan(
      children: res,
      style: ts,
    );
    if (needSelect != null && needSelect == false) {
      return Text.rich(
        tspan,
      );
    }
    // return SelectableText.rich(tspan, cursorWidth: 0,);
    return SelectionArea(
      child: Text.rich(
        tspan,
      ),
    );
  }
}

TextSpan html2TextSpan(String htmlStr, {TextStyle? ts}) {
  hdom.Document? document;
  try {
    document = parse(htmlStr);
  } catch (e) {
    document = null;
  }
  if (document == null) {
    return const TextSpan(text: "解析错误");
  }
  var res = travelHtml(document.querySelector("body"), context: null, ts: ts);
  var tspan = TextSpan(
    children: res,
    style: ts,
  );
  return tspan;
}

List<InlineSpan>? travelHtml(hdom.Element? document, {required TextStyle? ts, BuildContext? context, String? nickName}) {
  if (document == null) {
    return null;
  }
  var res = <InlineSpan>[];
  document.querySelectorAll("br").forEach((element) {
    element.remove();
  });
  for (var cdom in document.nodes) {
    if (cdom.nodeType == hdom.Node.TEXT_NODE) {
      if (cdom.text == "\n") {
        continue;
      }
      var text = tryGetNormalSpaceString(cdom.text);
      if (text != null) {
        // https://stackoverflow.com/questions/18760943/character-code-of-unknown-character-character-e-g-square-or-question-mark-romb
        // flutter bug? if unknown character appears first, others will be unknown too.
        text = text.replaceAll("\uD83E\uDD79", "\uFFFD");
        text = text.replaceAll("\uD83E\uDDCC", "\uFFFD");
      }
      res.add(TextSpan(text: text));
    } else if (cdom.nodeType == hdom.Node.ELEMENT_NODE) {
      var ele = cdom as hdom.Element;
      if (ele.localName == "font") {
        // for color
        var color = ele.attributes['color'];
        // var bColor = ele.attributes['background-color'];
        res.add(TextSpan(children: travelHtml(ele, context: context, ts: ts),
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
        res.add(TextSpan(children: travelHtml(ele, context: context, ts: ts),
          style: TextStyle(
            // color: color!=null?Color(int.parse("0xff${color.substring(1)}")):null,
            backgroundColor: bColor!=null?Color(int.parse("0xff${bColor.substring(1)}")) : null,
          ),),
        );
      } else if (ele.localName == "p") {
        if (ele.classes.contains('quotehead') || ele.classes.contains('blockquote')) {
          var contentSize = ts?.fontSize ?? 13;
          res.add(WidgetSpan(child: Icon(Icons.format_quote, size: contentSize-1, color: const Color(0xffA6DDE3))));
          var addText = ele.text;
          if (ele.classes.contains('quotehead') && (nickName != null)) {
            int p1 = addText.indexOf('(');
            if (p1!=-1) {
              int p2 = addText.indexOf(')', p1);
              if (p2!=-1 && p1+1!=p2) {
                addText = addText.replaceRange(p1+1, p2, nickName);
              }
            }
          }
          res.add(TextSpan(text: addText, style: TextStyle(color: Colors.grey, fontSize: contentSize-1)));
        } else if (ele.classes.contains("zz-info")) {
          res.add(TextSpan(
            children: travelHtml(ele, context: context, ts: ts),
            style: const TextStyle(color: bdwmPrimaryColor, backgroundColor: null),
          ));
        } else {
          res.add(TextSpan(
            children: travelHtml(ele, context: context, ts: ts),
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
        var alt = ele.attributes['alt'];
        if (src == null) {
          res.add(const WidgetSpan(child: Text("图片"),));
        } else {
          if (src.startsWith("data")) {
            var typePos1 = src.indexOf(":image/");
            var srcType = "png";
            if (typePos1 != -1) {
              var typePos2 = src.indexOf(";");
              if (typePos2 != -1) {
                srcType = src.substring(typePos1+7, typePos2);
              }
            }
            var p1 = src.indexOf("base64,");
            var str = src.substring(p1+7);
            var data = base64Decode(str);
            res.add(WidgetSpan(
              child: GestureDetector(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  // alignment: Alignment.centerLeft,
                  child: Image.memory(data,)
                ),
                onTap: () {
                  if (context != null) {
                    var curTime = DateTime.now().toIso8601String().replaceAll(":", "_");
                    curTime = curTime.split(".").first;
                    var imgName = "OBViewer-$curTime.$srcType";
                    gotoDetailImage(context: context, link: "", imgData: data, name: imgName);
                  }
                },
              )));
          } else {
            res.add(WidgetSpan(
              child: GestureDetector(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  // alignment: Alignment.centerLeft,
                  child: WrapImageNetwork(imgLink: absImgSrc(src), imgAlt: alt),
                  // child: Image.network(
                  //   src,
                  //   errorBuilder: (context, error, stackTrace) {
                  //     return const Center(child: Icon(Icons.broken_image));
                  //   },
                  // ),
                ),
                onTap: () {
                  if (context != null) {
                    gotoDetailImage(context: context, link: absImgSrc(src), imgData: null, name: "image.jpg");
                  }
                }),
            ));
          }
        }
        // if (cdom != document.nodes.last) {
        //   res.add(const TextSpan(text: "\n"));
        // }
      } else if (ele.localName == "b") {
        res.add(TextSpan(children: travelHtml(ele, context: context, ts: ts), style: const TextStyle(fontWeight: FontWeight.bold,)));
      } else if (ele.localName == "u") {
        res.add(TextSpan(children: travelHtml(ele, context: context, ts: ts), style: const TextStyle(decoration: TextDecoration.underline)));
      } else if (ele.localName == "a") {
        var href = ele.attributes['href'];
        var link = absThreadLink(href ?? "");
        var tspan = WidgetSpan(
          child: GestureDetector(
            child: Text.rich(
              TextSpan(
                children: travelHtml(ele, context: context, ts: ts),
                style: textLinkStyle,
              ),
              style: ts,
            ),
            onLongPress: () {
              if (context == null) { return; }
              showLinkMenu(context, link);
            },
            // // secondary tap conflicts with copy
            // onSecondaryTap: () {
            //   if (context == null) { return; }
            //   showLinkMenu(context, link);
            // },
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
                  nv2Push(context, '/thread', arguments: {
                    'bid': bid,
                    'boardName': "跳转",
                  });
                }
              } else if (link.startsWith("https://bbs.pku.edu.cn/v2/collection.php")) {
                nv2Push(context, '/collection', arguments: {
                  'link': link,
                  'title': "目录",
                });
              } else if (link.startsWith("https://bbs.pku.edu.cn/v2/collection-read.php")) {
                nv2Push(context, '/collectionArticle', arguments: {
                  'link': link,
                  'title': "文章",
                });
              } else if (link.startsWith("https://bbs.pku.edu.cn/v2/post-read-single.php")) {
                bdwmClient.get(link, headers: genHeaders2()).then((value) {
                  if (value == null) {
                    showNetWorkDialog(context);
                  } else {
                    var link2 = directToThread(value.body, needLink: true);
                    if (link2.isEmpty) { return; }
                    int? link2Int = int.tryParse(link2);
                    if (link2Int == null && link2.startsWith("post-read.php")==false) {
                      showInformDialog(context, "跳转失败", link2);
                    }
                    naviGotoThreadByLink(context, link2, "", pageDefault: "a");
                  }
                });
              } else {
                var hereLink = link;
                if (link.startsWith("https://bbs.pku.edu.cn/v2/jump-to.php")) {
                  var parsedUrl = Uri.parse(link);
                  var rawLink = parsedUrl.queryParameters['url'] ?? "";
                  // hereLink += "\n$rawLink";
                  hereLink = rawLink;
                }
                showConfirmDialog(context, "使用默认浏览器打开链接?", hereLink).then((value) async {
                  if (value == null) {
                    return;
                  }
                  if (value == "yes") {
                    var parsedUrl = Uri.parse(link);
                    if (true || !await canLaunchUrl(parsedUrl)) {
                      if (!await launchUrl(parsedUrl, mode: LaunchMode.externalApplication)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("打开链接失败"), duration: Duration(milliseconds: 600),),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("未能打开链接"),),
                      );
                    }
                  }
                });
              }
            },
          ),
        );
        res.add(tspan);
      } else {
        res.add(TextSpan(text: cdom.text));
      }
    }
  }
  return res;
}

class BDWMTextEditingController extends TextEditingController {
  bool html = true;

  BDWMTextEditingController({super.text});

  void toggle() {
    html = !html;
  }

  void useHtml() {
    html = true;
  }

  void notUseHtml() {
    html = false;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (html) {
      return html2TextSpan(text);
    }
    return TextSpan(text: text);
  }
}

String bdwmTextFormat(String htmlStr, {bool? mail=false, String? nickName}) {
  var document = parse(htmlStr);
  var res = <BDWMtext>[];
  travelHtmlBack(document.querySelector("body"), BDWMAnsiText.empty(), res);
  if (res.isEmpty) {
    return '[{"type":"ansi","bold":false,"underline":false,"fore_color":9,"back_color":9,"content":"\\n"}]';
  }
  if (mail!=null || nickName!=null) {
    int idx = res.length-1;
    while (idx >= 0) {
      var r = res[idx];
      if (r is BDWMQuoteText) {
        if (mail != null) {
          r.mail = mail;
        }
        if (nickName != null) {
          r.nickname = nickName;
        }
        break;
      }
      idx -= 1;
    }
  }
  return jsonEncode(res);
}

class BDWMtext {
  String type = "ansi";
  BDWMtext.empty();
  BDWMtext({
    required this.type,
  });
}
class BDWMAnsiText extends BDWMtext {
  bool bold = false;
  bool underline = false;
  int foreColor = 9;
  int backColor = 9;
  String content = "";

  BDWMAnsiText.empty({super.type="ansi"});

  BDWMAnsiText.raw(this.content) : super(type: "ansi") {
    bold = false;
    underline = false;
    foreColor = 9;
    backColor = 9;
  }

  BDWMAnsiText({
    required super.type,
    required this.bold,
    required this.underline,
    required this.foreColor,
    required this.backColor,
    required this.content,
  });

  BDWMAnsiText copy() {
    return BDWMAnsiText(type: type, bold: bold, underline: underline, foreColor: foreColor, backColor: backColor, content: content);
  }

  @override
  String toString() {
    return '{"type":"$type","bold":$bold,"underline":$underline,"fore_color":$foreColor,"back_color":$backColor,"content":"$content"}';
  }

  Map toJson() {
    return {
      'type': type,
      'bold': bold,
      'underline': underline,
      'fore_color': foreColor,
      'back_color': backColor,
      'content': content,
    };
  }
}

class BDWMImgText extends BDWMtext {
  String src = "";
  BDWMImgText({
    required super.type,
    required this.src,
  });
  @override
  String toString() {
    return '{"type":"img","src":"$src"}';
  }
  Map toJson() {
    return {
      'type': type,
      'src': src,
    };
  }
}

class BDWMQuoteText extends BDWMtext {
  bool mail = false;
  String username = "";
  String nickname = "";
  BDWMQuoteText({
    required super.type,
    required this.username,
    required this.nickname,
    required this.mail,
  });
  @override
  String toString() {
    return '{"type":"quotehead","mail":$mail,"username":"$username","nickname":"$nickname"}';
  }
  Map toJson() {
    return {
      'type': type,
      'username': username,
      'nickname': nickname,
      'mail': mail,
    };
  }
}

void travelHtmlBack(hdom.Element? document, BDWMtext config, List<BDWMtext> res) {
  if (document == null) {
    return;
  }
  document.querySelectorAll("br").forEach((element) {
    element.remove();
  });
  for (var cdom in document.nodes) {
    if (cdom.nodeType == hdom.Node.TEXT_NODE) {
      BDWMAnsiText bdwmText = (config as BDWMAnsiText).copy();
      bdwmText.content = cdom.text ?? "";
      if (cdom.text == "\n") {
        continue;
      }
      res.add(bdwmText);
    } else if (cdom.nodeType == hdom.Node.ELEMENT_NODE) {
      var ele = cdom as hdom.Element;
      if (ele.localName == "font") {
        // for color
        var color = ele.attributes['color'];
        // var bColor = ele.attributes['background-color'];
        if (color == null) {
          continue;
        }
        var colorIdx = (bdwmRichText['bc'] as Map<String, int>)[color];
        BDWMAnsiText bdwmText = (config as BDWMAnsiText).copy();
        bdwmText.foreColor = colorIdx ?? 9;
        travelHtmlBack(ele, bdwmText, res);
      } else if (ele.localName == "span") {
        var spanStyle = ele.attributes['style'];
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
        if (bColor == null) {
          continue;
        }
        var colorIdx = (bdwmRichText['bc'] as Map<String, int>)[bColor];
        BDWMAnsiText bdwmText = (config as BDWMAnsiText).copy();
        bdwmText.backColor = colorIdx ?? 9;
        travelHtmlBack(ele, bdwmText, res);
      } else if (ele.localName == "p") {
        if (ele.classes.contains('quotehead')) {
          var username = ele.attributes['data-username'] ?? "";
          var nickname = ele.attributes['data-nickname'] ?? "";
          var txt = BDWMQuoteText(mail: false, type: "quotehead", nickname: nickname, username: username);
          res.add(txt);
        } else if (ele.classes.contains('blockquote')) {
          var txt = BDWMAnsiText.raw(ele.text);
          bool needNeline = true;
          if (ele.text.isEmpty) {
            // quote an empty line
            txt.content = "\n";
            needNeline = false;
          }
          txt.type = "quote";
          res.add(txt);
          if (needNeline && cdom != document.nodes.last) {
            res.add(BDWMAnsiText.raw("\n"));
          }
        } else {
          BDWMAnsiText bdwmText = (config as BDWMAnsiText).copy();
          travelHtmlBack(ele, bdwmText, res);
          if (cdom != document.nodes.last) {
            res.add(BDWMAnsiText.raw("\n"));
          }
        }
      } else if (ele.localName == "h5") {
      } else if (ele.localName == "img") {
        var src = ele.attributes['src'];
        if (src != null && src.isNotEmpty) {
          res.add(BDWMImgText(type: "img", src: src));
        }
        // if (cdom != document.nodes.last) {
        //   res.add(BDWMAnsiText.raw("\n"));
        // }
      } else if (ele.localName == "b") {
        BDWMAnsiText bdwmText = (config as BDWMAnsiText).copy();
        bdwmText.bold = true;
        travelHtmlBack(ele, bdwmText, res);
      } else if (ele.localName == "u") {
        BDWMAnsiText bdwmText = (config as BDWMAnsiText).copy();
        bdwmText.underline = true;
        travelHtmlBack(ele, bdwmText, res);
      } else if (ele.localName == "a") {
        // var href = ele.attributes['href'];
        // var link = absThreadLink(href ?? "");
        res.add(BDWMAnsiText.raw(ele.text));
      } else {
        res.add(BDWMAnsiText.raw(cdom.text));
      }
    }
  }
}