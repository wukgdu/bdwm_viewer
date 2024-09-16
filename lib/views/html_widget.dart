import 'dart:convert';
// import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as hdom;
import 'package:extended_image/extended_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_highlight/flutter_highlight.dart' show HighlightView;
import 'package:flutter_highlight/themes/github.dart' show githubTheme;

import "./utils.dart";
import './constants.dart';
import '../bdwm/search.dart' show bdwmUserInfoSearch, IDandName;
import '../pages/read_thread.dart';
import '../html_parser/utils.dart';
import '../globalvars.dart' show globalConfigInfo, v2Host, notoSansMonoCJKscFont, globalImmConfigInfo;
import '../pages/detail_image.dart';
import '../utils.dart' show getQueryValue, isAndroid, genSavePathByTime;
import '../router.dart' show nv2Push;
import '../pages/read_post.dart' show getSinglePostData;

const int _cacheHeight = 150;

ExtendedNetworkImageProvider genSimpleCachedImageProvider(String imgLink) {
  return ExtendedNetworkImageProvider(
    imgLink,
    cache: true,
    timeLimit: null,
  );
}

class SimpleCachedImage extends StatelessWidget {
  final String imgLink;
  final double? height;
  final double? width;
  const SimpleCachedImage({super.key, required this.imgLink, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      imgLink,
      height: height,
      width: width,
      fit: BoxFit.contain,
      cache: true,
      enableMemoryCache: true,
      clearMemoryCacheWhenDispose: true,
      clearMemoryCacheIfFailed: true,
      handleLoadingProgress: true,
      filterQuality: FilterQuality.high,
      cacheHeight: null,
      timeLimit: null,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return SizedBox(height: height, width: width,);
          case LoadState.completed:
            return null;
          case LoadState.failed:
            return null;
          default:
            return null;
        }
      },
    );
  }
}

class WrapImageNetwork extends StatefulWidget {
  final String imgLink;
  final String? imgAlt;
  final bool? useLinearProgress;
  final bool? mustClear;
  final bool? highQuality;
  const WrapImageNetwork({super.key, required this.imgLink, this.imgAlt, this.useLinearProgress, this.mustClear, this.highQuality});

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
    // if ("://".allMatches(widget.imgLink).length > 1) {
    //   return const Icon(Icons.broken_image);
    // }

    // try {

    return ExtendedImage.network(
      widget.imgLink,
      fit: BoxFit.contain,
      cache: true,
      enableMemoryCache: true,
      clearMemoryCacheWhenDispose: widget.mustClear ?? globalConfigInfo.getHighQualityPreview(),
      clearMemoryCacheIfFailed: true,
      handleLoadingProgress: true,
      filterQuality: (widget.highQuality ?? globalConfigInfo.getHighQualityPreview()) ? FilterQuality.high : FilterQuality.low,
      cancelToken: cancelIt,
      cacheHeight: (widget.highQuality ?? globalConfigInfo.getHighQualityPreview()) ? null : _cacheHeight,
      timeLimit: const Duration(seconds: 30),
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            if (state.loadingProgress == null) {
              return const Text("[图片加载中]");
            }
            var curByte = state.loadingProgress?.cumulativeBytesLoaded ?? 0;
            var sumByte = state.loadingProgress?.expectedTotalBytes ?? -1;
            if (sumByte == -1) {
              return const Text("[图片加载中]");
            }
            var text = "${(curByte * 100 / sumByte).toStringAsFixed(0)}%";
            // return Text(text);
            if (widget.useLinearProgress != null && widget.useLinearProgress == true) {
              return LinearProgressIndicator(
                value: curByte / sumByte,
                semanticsLabel: '加载中',
                semanticsValue: text,
                backgroundColor: Colors.amberAccent,
              );
            }
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

    // } catch (e) {
    //   return const Icon(Icons.broken_image);
    // }
  }
}

class HtmlComponent extends StatefulWidget {
  final String htmlStr;
  final bool? needSelect;
  final TextStyle? ts;
  final String? nickName;
  final bool? isBoardNote;
  final bool needBox;
  const HtmlComponent(this.htmlStr, {super.key, this.needSelect, this.ts, this.nickName, this.isBoardNote, this.needBox=true});

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
    var res = travelHtml(document.querySelector("body"), context: context, ts: ts, nickName: nickName, isBoardNote: widget.isBoardNote);
    var tspan = TextSpan(
      children: preprocessTextSpan(res, ts: ts, needBox: widget.needBox),
      // children: res,
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

// void initFontForCache() {
//   // https://github.com/flutter/flutter/issues/42586#issuecomment-541870382
//   // not work
//   ParagraphBuilder pb = ParagraphBuilder(ParagraphStyle());
//   pb.addText('\ud83d\ude01');  // smiley face emoji
//   pb.addText('哦');
//   pb.build().layout(const ParagraphConstraints(width: 100));
// }

class GetTextWidth {
  final Map<String, double> _widthMap = {};

  Size _getTextSize(String text, TextStyle? style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style), maxLines: 1, textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  String _genUniqueKey(String text, TextStyle? style) {
    var fontFamily = style?.fontFamily;
    var fontFamilyFallBack = style?.fontFamilyFallback;
    var fontSize = style?.fontSize;
    return "$text-$fontSize-$fontFamily-$fontFamilyFallBack-${style?.hashCode}";
  }

  double getTextWidth(String text, TextStyle? style) {
    var k = _genUniqueKey(text, style);
    if (_widthMap.containsKey(k)) {
      return _widthMap[k]!;
    }
    var s = _getTextSize(text, style);
    _widthMap[k] = s.width;
    return s.width;
  }
}

final getTextWidthObject = GetTextWidth();

List<InlineSpan>? preprocessTextSpan(List<InlineSpan>? res, {TextStyle? ts, bool needBox=false}) {
  // https://bbs.pku.edu.cn/v2/post-read.php?bid=414&threadid=18560606
  // emoji at start of line will not display correctly
  // https://github.com/flutter/flutter/issues/45947
  // https://github.com/flutter/flutter/issues/82785
  if (res == null) return res;
  if (res.isEmpty) return res;
  // var firstTextSpan = res.first;
  // var firstText = firstTextSpan.toPlainText();
  // // if (firstText.isEmpty) return res;
  // if (firstText.isNotEmpty) {
  //   var firstCharCode = firstText.runes.first;
  //   if (firstCharCode <= 0xffff) {
  //     return res;
  //   }
  // }
  // var txt = '\u{1f60a}';
  var txt = 'a';
  // var txt = '\ud83d\ude01';
  var w = getTextWidthObject.getTextWidth(txt, ts);
  // print('${ts?.fontSize} $w');
  var newTs = TextStyle(
    color: Colors.transparent, height: null, fontSize: ts?.fontSize, letterSpacing: -w,
  );
  return [
    if (needBox) ...[
      WidgetSpan(child: SizedBox(width: w/2,), alignment: PlaceholderAlignment.middle),
    ],
    // WidgetSpan(
    //   child: SelectionContainer.disabled(
    //     child: Text(txt, style: ts?.merge(newTs) ?? newTs),
    //   ),
    //   alignment: PlaceholderAlignment.middle
    // ),
    TextSpan(
      text: txt,
      style: ts?.merge(newTs) ?? newTs,
    ),
    ...res,
  ];
}

TextSpan html2TextSpan(String htmlStr, {TextStyle? ts, bool needBox=false}) {
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
    children: preprocessTextSpan(res, ts: ts, needBox: needBox),
    // children: res,
    style: ts,
  );
  return tspan;
}

bool validUserMention(int p1, int p2, String sourceStr) {
  bool leftOK = false, rightOK = false;
  if (p1 == 0) {
    leftOK = true;
  } else {
    var p1Char = sourceStr[p1-1];
    if ((p1Char == " ") | (p1Char == "\n")) {
      leftOK = true;
    }
  }
  if (p2 >= sourceStr.length) {
    rightOK = true;
  } else {
    var p2Char = sourceStr[p2];
    if ((p2Char == " ") | (p2Char == "\n")) {
      rightOK = true;
    }
  }
  return leftOK & rightOK;
}

void innerLinkJump(String dmLink, BuildContext context) {
  // dmLink: desktop or mobile link
  var link = dmLink.replaceFirst("$v2Host/mobile/", "$v2Host/");
  var httpIdx = link.indexOf("http");
  link = httpIdx == -1 ? link : link.substring(httpIdx);
  if (link.startsWith("$v2Host/post-read.php")) {
    naviGotoThreadByLink(context, link, "跳转", needToBoard: true);
  } else if (link.startsWith("$v2Host/thread.php")) {
    var bid = getQueryValue(link, 'bid') ?? "";
    if (bid.isNotEmpty) {
      nv2Push(context, '/board', arguments: {
        'bid': bid,
        'boardName': "跳转",
      });
    }
  } else if (link.startsWith("$v2Host/collection.php")) {
    nv2Push(context, '/collection', arguments: {
      'link': link,
      'title': "目录",
    });
  } else if (link.startsWith("$v2Host/collection-read.php")) {
    nv2Push(context, '/collectionArticle', arguments: {
      'link': link,
      'title': "文章",
    });
  } else if (link.startsWith("$v2Host/user.php")) {
    String uid = getQueryValue(link, 'uid') ?? "";
    if (uid.isEmpty) { return; }
    nv2Push(context, '/user', arguments: uid);
  } else if (link.startsWith("$v2Host/note.php")) {
    String bid = getQueryValue(link, 'bid') ?? "";
    if (bid.isNotEmpty) {
      nv2Push(context, '/boardNote', arguments: {
        'bid': bid,
        'boardName': "备忘录",
      });
    }
  } else if (link.startsWith("$v2Host/post-read-single.php")) {
    // bdwmClient.get(link, headers: genHeaders2()).then((value) {
    var bid = getQueryValue(link, "bid") ?? "";
    var postid = getQueryValue(link, "postid") ?? "";
    if (bid.isEmpty || postid.isEmpty) { return; }
    getSinglePostData(bid, postid).then((value) {
      if (value.errorMessage != null) {
        if (context.mounted) {
          showInformDialog(context, "跳转失败", value.errorMessage ?? "未知错误");
        }
      } else {
        var link2 = value.threadLink;
        if (link2.isEmpty) { return; }
        if (context.mounted) {
          naviGotoThreadByLink(context, link2, "", pageDefault: "a", needToBoard: true);
        }
      }
    });
  } else {
    var hereLink = link;
    if (link.startsWith("$v2Host/jump-to.php")) {
      var parsedUrl = Uri.parse(link);
      var rawLink = parsedUrl.queryParameters['url'] ?? "";
      // hereLink += "\n$rawLink";
      hereLink = rawLink;
    }
    showConfirmDialog(context, "使用默认浏览器打开链接?", hereLink).then((value) {
      if (value == null) {
        return;
      }
      if (value == "yes") {
        var parsedUrl = Uri.parse(link); // bbs会有一层跳转提醒，hereLink (rawLink) 是实际url
        // await canLaunchUrl(parsedUrl)
        launchUrl(parsedUrl, mode: LaunchMode.externalApplication).then((result) {
          if (result == true) { return; }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("打开链接失败"), duration: Duration(milliseconds: 600),),
            );
          }
        });
      }
    });
  }
}

List<InlineSpan>? travelHtml(hdom.Element? document, {required TextStyle? ts, BuildContext? context, String? nickName, bool? isBoardNote}) {
  if (document == null) {
    return null;
  }
  var res = <InlineSpan>[];
  // document.querySelectorAll("br").forEach((element) {
  //   element.remove();
  // });
  for (var cdom in document.nodes) {
    if (cdom.nodeType == hdom.Node.TEXT_NODE) {
      if (cdom.text == "\n") {
        continue;
      }
      var text = tryGetNormalSpaceString(cdom.text);
      // var text = cdom.text;
      if (text == null) { continue; }
      // https://stackoverflow.com/questions/18760943/character-code-of-unknown-character-character-e-g-square-or-question-mark-romb
      // flutter bug? if unknown character appears first, other normal emoji will become unknown too.
      // text = text.replaceAll("\uD83E\uDD79", "\uFFFD");
      // text = text.replaceAll("\uD83E\uDDCC", "\uFFFD");
      // 不知道和上面的是不是同一个bug，但是下面这个前面加了一个0就好了（只在Android有bug，Windows不能改）
      // https://bbs.pku.edu.cn/v2/post-read.php?bid=7&threadid=18456591 上面的忘记链接了
      if (isAndroid()) {
        text = text.replaceAll(String.fromCharCode(1763), String.fromCharCodes([0, 1763]));
      }
      // https://stackoverflow.com/questions/51999816/how-does-flutters-text-widget-let-it-display-all-spaces-that-end-with-a-space
      // text = text.replaceAll("\u0020", "\u00a0");
      if (isBoardNote ?? false) {
        if (globalImmConfigInfo.getBoardNoteFont() == notoSansMonoCJKscFont) {
          text = text.replaceAll("ο", "o ");
          text = text.replaceAll("ˋ", " `");
          text = text.replaceAll("′", "′ ");
          text = text.replaceAll("ˊ", "ˊ ");
          text = text.replaceAll("–", " -");
          text = text.replaceAll("˙", "·");
          text = text.replaceAll("—", "一");
          text = text.replaceAll("°", "৹ ");
          text = text.replaceAll("ˇ", "ˇ ");
          text = text.replaceAll("", "  ");
        }
      }
      var userExp = RegExp(r"@[a-zA-Z_]+");
      text.splitMapJoin(userExp,
        onMatch: (m) {
          var mStr = m[0].toString();
          if (validUserMention(m.start, m.end, text!)) {
            res.add(TextSpan(
              text: mStr.toString(),
              style: textLinkStyle,
              recognizer: TapGestureRecognizer()..onTap = () async {
                if (context == null) { return; }
                bdwmUserInfoSearch([mStr.substring(1)]).then((res) {
                  var success = res.success;
                  var informText = res.desc ?? "rt";
                  if (res.success) {
                    if (res.users.isEmpty) {
                      success = false;
                    } else if (res.users[0] is bool) {
                      success = false;
                      informText = "用户不存在";
                    } else {
                      success = true;
                      var ian = res.users.first as IDandName;
                      if (context.mounted) {
                        nv2Push(context, '/user', arguments: ian.id);
                      }
                    }
                  }
                  if (!success) {
                    if (context.mounted) {
                      showInformDialog(context, "查询用户失败", informText);
                    }
                  }
                },);
              },
            ));
          } else {
            var m = mStr;
            if ((isBoardNote ?? false) && isAndroid()) {
              res.add(TextSpan(text: m));
              // res.add(WidgetSpan(child: SizedBox(height: 15, width: termStringLength(m, sp: 127)*8.0, child: Text(m, style: ts),)));
            } else {
              res.add(TextSpan(text: m));
            }
          }
          return mStr;
        },
        onNonMatch: (m) {
          // if ((isBoardNote ?? false) && isAndroid()) {
          //   res.add(TextSpan(text: m));
          //   // res.add(WidgetSpan(child: SizedBox(height: 15, width: termStringLength(m, sp: 127)*8.0, child: Text(m, style: ts),)));
          // } else {
          //   res.add(TextSpan(text: m));
          // }
          res.add(TextSpan(text: m));
          return m;
        },
      );
    } else if (cdom.nodeType == hdom.Node.ELEMENT_NODE) {
      var ele = cdom as hdom.Element;
      if (ele.localName == "font") {
        // for color
        var color = ele.attributes['color'];
        // var bColor = ele.attributes['background-color'];
        var newTS = TextStyle(
          color: color!=null?Color(int.parse("0xff${color.substring(1)}")):null,
        );
        res.add(TextSpan(children: travelHtml(ele, context: context, ts: newTS.merge(ts), isBoardNote: isBoardNote),
          style: newTS,),
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
        var newTS = TextStyle(
          backgroundColor: bColor!=null?Color(int.parse("0xff${bColor.substring(1)}")) : null,
        );
        res.add(TextSpan(children: travelHtml(ele, context: context, ts: newTS.merge(ts), isBoardNote: isBoardNote),
          style: newTS,),
        );
      } else if (ele.localName == "p") {
        bool inCode =false;
        if (ele.classes.contains('quotehead') || ele.classes.contains('blockquote')) {
          var contentSize = ts?.fontSize ?? 14;
          res.add(WidgetSpan(child: Icon(Icons.format_quote, size: contentSize, color: const Color(0xffA6DDE3)), alignment: PlaceholderAlignment.top));
          var quoteText = ele.text;
          if (ele.classes.contains('quotehead') && (nickName != null)) {
            int p1 = quoteText.indexOf('(');
            if (p1!=-1) {
              int p2 = quoteText.indexOf(')', p1);
              if (p2!=-1 && p1+1!=p2) {
                quoteText = quoteText.replaceRange(p1+1, p2, nickName);
              }
            }
          }
          res.add(TextSpan(text: quoteText, style: TextStyle(color: Colors.grey, fontSize: contentSize)));
        } else if (ele.classes.contains("zz-info")) {
          res.add(TextSpan(
            children: travelHtml(ele, context: context, ts: ts, isBoardNote: isBoardNote),
            style: TextStyle(color: bdwmPrimaryColor, backgroundColor: null),
          ));
        } else if (ele.classes.contains("code")) {
          var codeString = "";
          inCode = true;
          var codeLanguage = ele.attributes["data-lang"] ?? "js";
          for (var codeDom in ele.nodes) {
            if (codeDom.nodeType == hdom.Node.TEXT_NODE) {
              codeString += (codeDom.text ?? "");
            } else if (codeDom.nodeType == hdom.Node.ELEMENT_NODE) {
              var codeEle = codeDom as hdom.Element;
              if (codeEle.localName == "span") {
                  codeString += codeEle.text;
              } else if (codeEle.localName == "br") {
                if (codeDom != ele.nodes.last) {
                  codeString += "\n";
                }
              } else {
                codeString += codeEle.text;
              }
            }
          }
          debugPrint(codeLanguage);
          res.add(WidgetSpan(
            child: HighlightView(
              codeString,
              language: codeLanguage,
              theme: githubTheme,
              tabSize: 4,
              padding: EdgeInsets.zero,
            ),
          ));
        } else {
          res.add(TextSpan(
            children: travelHtml(ele, context: context, ts: ts, isBoardNote: isBoardNote),
          ));
        }
        if (isBoardNote ?? false) {
          // https://stackoverflow.com/questions/73378051/flutter-text-with-space-breaks-background-color
          res.add(WidgetSpan(child: SelectionContainer.disabled(
            child: Text("|", style: ts?.copyWith(color: Colors.transparent) ?? const TextStyle(color: Colors.transparent))
          )));
        } else {
          if (res.isNotEmpty) {
            var lastItem = res.last;
            while (true) {
              if (lastItem is! TextSpan) { break; }
              if (lastItem.children?.isEmpty ?? true) {
                break;
              }
              lastItem = lastItem.children!.last;
            }
            if (lastItem is TextSpan) {
              var txt = lastItem.text ?? "";
              if (txt.trimRight().length != txt.length) {
                res.add(WidgetSpan(child: SelectionContainer.disabled(
                  child: Text("|", style: ts?.copyWith(color: Colors.transparent) ?? const TextStyle(color: Colors.transparent))
                )));
              }
            }
          }
        }
        if (cdom != document.nodes.last && !inCode) {
          res.add(const TextSpan(text: "\n"));
        }
      } else if (ele.localName == "h5") {
        res.add(TextSpan(text: ele.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.5)));
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
            var p1 = src.indexOf("base64,");
            if (p1!=-1) {
              var str = src.substring(p1+7);
              var metaSrc = src.substring(0, p1);
              var typePos1 = metaSrc.indexOf(":image/");
              var srcType = "png";
              if (typePos1 != -1) {
                var typePos2 = metaSrc.indexOf(";");
                if (typePos2 != -1) {
                  srcType = metaSrc.substring(typePos1+7, typePos2);
                }
              }
              var data = base64Decode(str);
              res.add(WidgetSpan(
                child: GestureDetector(
                  // child: Text("[查看图片]", style: TextStyle(color: bdwmPrimaryColor).merge(ts),),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: _cacheHeight.toDouble()),
                    // alignment: Alignment.centerLeft,
                    child: Image.memory(data, cacheHeight: globalConfigInfo.getHighQualityPreview() ? null : _cacheHeight,)
                  ),
                  onTap: () {
                    if (context != null) {
                      var imgName = genSavePathByTime(srcType: ".$srcType");
                      gotoDetailImage(context: context, link: "", imgData: data, name: imgName);
                      // gotoDetailImage(context: context, link: "", imgDataStr: str, name: imgName);
                    }
                  },
                ),
              ));
            }
          } else {
            res.add(WidgetSpan(
              child: GestureDetector(
                child: Container(
                  constraints: BoxConstraints(maxHeight: _cacheHeight.toDouble()),
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
                    gotoDetailImage(context: context, link: absImgSrc(src), imgData: null, name: null);
                  }
                }),
            ));
          }
        }
        // if (cdom != document.nodes.last) {
        //   res.add(const TextSpan(text: "\n"));
        // }
      } else if (ele.localName == "b") {
        res.add(TextSpan(children: travelHtml(ele, context: context, ts: ts, isBoardNote: isBoardNote), style: TextStyle(fontWeight: (isBoardNote ?? false) ? FontWeight.w400 : FontWeight.bold,)));
      } else if (ele.localName == "u") {
        res.add(TextSpan(children: travelHtml(ele, context: context, ts: ts, isBoardNote: isBoardNote), style: const TextStyle(decoration: TextDecoration.underline)));
      } else if (ele.localName == "a") {
        var href = ele.attributes['href'];
        var link = absThreadLink(href ?? "");
        var tspan = TextSpan(
          text: getTrimmedString(ele),
          style: TextStyle(color: bdwmPrimaryColor),
          recognizer: TapGestureRecognizer()..onTap = () {
            if (context == null) {
              return;
            }
            if (href == null) { return; }
            innerLinkJump(link, context);
          },
        );
        res.add(tspan);
      } else if (ele.localName == "br") {
        if (cdom != document.nodes.last) {
          res.add(const TextSpan(text: "\n"));
        }
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
  // document.querySelectorAll("br").forEach((element) {
  //   element.remove();
  // });
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
      } else if (ele.localName == "br") {
        if (cdom != document.nodes.last) {
          res.add(BDWMAnsiText.raw("\n"));
        }
      } else {
        res.add(BDWMAnsiText.raw(cdom.text));
      }
    }
  }
}