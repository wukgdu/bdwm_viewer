import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_quill/flutter_quill.dart' as fquill;
import 'package:flutter_quill_extensions/embeds/builders.dart' show ImageEmbedBuilder;

import '../bdwm/posts.dart';
import '../bdwm/search.dart';
import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/postnew_parser.dart';
import '../html_parser/utils.dart' show SignatureItem;
import './constants.dart';
import './html_widget.dart';
import './quill_utils.dart';
import './upload.dart';
import './utils.dart';
import '../router.dart' show nv2Pop;

class PostNewPage extends StatefulWidget {
  final String bid;
  final String? postid;
  final String? parentid;
  // final String boardName;
  final PostNewInfo postNewInfo;
  final String? quoteText;
  final String? nickName;
  final FutureOrFunction<String> updateQuote;
  const PostNewPage({Key? key, required this.bid, this.postid, this.parentid, required this.postNewInfo, this.quoteText, required this.updateQuote, this.nickName}) : super(key: key);

  @override
  State<PostNewPage> createState() => _PostNewPageState();
}

class _PostNewPageState extends State<PostNewPage> {
  late final fquill.QuillController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  TextEditingController titleValue = TextEditingController();
  bool needNoreply = false;
  bool needRemind = true;
  bool needForward = false;
  bool needAnony = false;
  SignatureItem? signature;
  final signatureOB = SignatureItem(key: "OBViewer", value: "OBViewer");
  static const vDivider = VerticalDivider();
  final quoteModes = <SignatureItem>[SignatureItem(key: "精简引文", value: "simple"), SignatureItem(key: "完整引文", value: "full")];
  late SignatureItem quoteMode;
  int attachCount = 0;
  List<String> attachFiles = [];
  String? quoteText;
  Timer? removeOverlayTimer;
  OverlayEntry? suggestionTagoverlayEntry;
  CancelableOperation? getUserSuggestionCancelable;

  bool useHtmlContent = true;

  @override
  void initState() {
    super.initState();
    // _future = getData();
    quoteMode = quoteModes[0];
    quoteText = widget.quoteText;
    needAnony = widget.postNewInfo.canAnony;
    var content = widget.postNewInfo.contentHtml;
    if (content!=null && content.isNotEmpty) {
      var clist = html2Quill(content);
      _controller = fquill.QuillController(
        document: fquill.Document.fromJson(clist),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _controller = fquill.QuillController.basic();
    }

    if (widget.postNewInfo.titleText != null && widget.postNewInfo.titleText!.isNotEmpty) {
      if (titleValue.text.isEmpty) {
        titleValue.value = TextEditingValue(text: widget.postNewInfo.titleText!);
      }
    }

    if (signature == null && widget.postid != null) {
      for (var item in widget.postNewInfo.signatureInfo) {
        if (item.value == "keep") {
          signature = item;
          break;
        }
      }
    }

    attachFiles = widget.postNewInfo.attachFiles;

    _controller.onSelectionChanged = (textSelection) async {
      var textEditingValue = _controller.plainTextEditingValue;
      var rawText = textEditingValue.text;
      var baseOffset = textSelection.baseOffset;
      bool waitUserList = false;
      String partUserName = "";
      int selection1 = -1;
      if (baseOffset > 1) {
        if (baseOffset >= rawText.length || rawText[baseOffset]==" " || rawText[baseOffset]=="\n") {
          int newOffset = baseOffset - 1;
          while (newOffset >= 0) {
            if (rawText[newOffset] == '@') {
              if (newOffset == 0 || rawText[newOffset-1]==" " || rawText[newOffset-1]=="\n") {
                partUserName = rawText.substring(newOffset+1, baseOffset);
                if (isValidUserName(partUserName)) {
                  waitUserList = true;
                  selection1 = newOffset+1;
                }
                break;
              }
            }
            newOffset -= 1;
            if (baseOffset - newOffset > 12) {
              break;
            }
          }
        }
      }
      if (waitUserList == false) { return; }
      debugPrint(partUserName);
      showOverlaidTag(context, partUserName, selection1);
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    titleValue.dispose();
    if (removeOverlayTimer != null) {
      if (suggestionTagoverlayEntry != null && removeOverlayTimer!.isActive) {
        removeOverlayTimer!.cancel();
        suggestionTagoverlayEntry!.remove();
      }
    }
    if (suggestionTagoverlayEntry != null) {
      suggestionTagoverlayEntry!.dispose();
    }
    if (getUserSuggestionCancelable != null) {
      getUserSuggestionCancelable!.cancel();
    }
    super.dispose();
  }

  bool isValidUserName(String userName) {
    var matchRes = RegExp(r"[a-zA-Z_]+").stringMatch(userName);
    if (matchRes == null) { return false; }
    return matchRes.length == userName.length;
  }

  showOverlaidTag(BuildContext context, String partUserName, int selection1) async {
    if (removeOverlayTimer != null && removeOverlayTimer!.isActive) {
      removeOverlayTimer!.cancel();
      if (suggestionTagoverlayEntry != null) {
        suggestionTagoverlayEntry!.remove();
      }
    }
    if (getUserSuggestionCancelable != null) {
      getUserSuggestionCancelable!.cancel();
    }
    if (!mounted) { return; }
    OverlayState? overlayState = Overlay.of(context);
    if (overlayState == null) { return; }
    getUserSuggestionCancelable = CancelableOperation.fromFuture(
      bdwmTopSearch(partUserName),
    );
    var duration = const Duration(milliseconds: 4000);
    suggestionTagoverlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
        top: _focusNode.offset.dy + 3,
        left: _focusNode.offset.dx + 10,

        child: Material(
          elevation: 4,
          color: Colors.white.withOpacity(1.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: bdwmPrimaryColor, width: 1.0),
              // color: Colors.white.withOpacity(0.5),
            ),
            constraints: const BoxConstraints(
              minHeight: 25,
              maxHeight: 125,
            ),
            width: 100,
            child: FutureBuilder(
              future: getUserSuggestionCancelable!.value,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Text("查询中");
                }
                if (snapshot.hasError) {
                  duration = const Duration(milliseconds: 1000);
                  return const Text("查询失败");
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  duration = const Duration(milliseconds: 1000);
                  return const Text("查询失败");
                }
                var searchResp = snapshot.data as TopSearchRes;
                if (!searchResp.success) {
                  duration = const Duration(milliseconds: 1000);
                  return partUserName.length == 1 ? const Text("太短") : const Text("查询失败");
                } else if (searchResp.users.isEmpty) {
                  duration = const Duration(milliseconds: 1000);
                  return const Text("查询失败");
                }
                return ListView(
                  padding: const EdgeInsets.all(0.0),
                  itemExtent: 25,
                  shrinkWrap: true,
                  children: searchResp.users.map((e) {
                    return GestureDetector(
                      onTap: () {
                        String fullName = "${e.name} ";
                        _controller.replaceText(selection1, partUserName.length, fullName, _controller.selection);
                        _controller.updateSelection(_controller.selection.copyWith(
                          baseOffset: selection1+fullName.length,
                          extentOffset: selection1+fullName.length,
                        ), fquill.ChangeSource.LOCAL);
                        if (removeOverlayTimer != null && removeOverlayTimer!.isActive) {
                          removeOverlayTimer!.cancel();
                          if (suggestionTagoverlayEntry != null) {
                            suggestionTagoverlayEntry!.remove();
                          }
                        }
                      },
                      child: Text(e.name, style: const TextStyle(fontSize: 18)),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      );
    });
    overlayState.insert(suggestionTagoverlayEntry!);

    removeOverlayTimer = Timer(duration, () {
      if (suggestionTagoverlayEntry != null) {
        suggestionTagoverlayEntry!.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("post new rebuild");
    return ListView(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
          child: Row(
            children: [
              // const Text("标题"),
              Expanded(
                child: TextField(
                  controller: titleValue,
                  decoration: const InputDecoration(
                    labelText: "标题",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (titleValue.text.isEmpty) {
                    showAlertDialog(context, "有问题", const Text("标题不能为空"),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      )
                    );
                    return;
                  }
                  if (_controller.document.length==0) {
                    showAlertDialog(context, "有问题", const Text("内容不能为空"),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      )
                    );
                    return;
                  }
                  var config = <String, bool>{};
                  if (needNoreply) { config['no_reply'] = true; }
                  if (needRemind) { config['mail_re'] = true; }
                  if (needAnony) { config['anony'] = true; }
                  var nSignature = signature?.value ?? "";
                  if (nSignature == "random") {
                    var moreCount = widget.postid == null ? 2 : 3;
                    // moreCount -= 1; // skip OBViewer // dont need skip since it is not here
                    var maxS = widget.postNewInfo.signatureInfo.length - moreCount;
                    var randomI = math.Random().nextInt(maxS);
                    nSignature = randomI.toString();
                  } else if (nSignature == "keep") {
                    nSignature = widget.postNewInfo.oriSignature ?? "";
                  } else if (nSignature == "OBViewer") {
                    nSignature = jsonEncode(signatureOBViewer);
                  }

                  var quillDelta = _controller.document.toDelta().toJson();
                  debugPrint(quillDelta.toString());
                  String postContent = "";
                  try {
                    postContent = quill2BDWMtext(quillDelta);
                  } catch (e) {
                    if (!mounted) { return; }
                    showAlertDialog(context, "内容格式错误", Text("$e\n请返回后截图找 onepiece 报bug"),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      ),
                    );
                  }
                  if (postContent.isEmpty) {
                    return;
                  }
                  if (quoteText != null) {
                    var postQuote = bdwmTextFormat(quoteText!, mail: false, nickName: widget.nickName);
                    // ...{}] [{}...
                    postContent = "${postContent.substring(0, postContent.length-1)},${postQuote.substring(1)}";
                  }
                  debugPrint(postContent);

                  var nContent = useHtmlContent ? postContent : _controller.document.toPlainText();
                  var nAttachPath = widget.postid == null
                    ? attachCount > 0
                      ? widget.postNewInfo.attachpath : ""
                    : widget.postNewInfo.attachpath;
                  bdwmSimplePost(
                    bid: widget.bid, title: titleValue.text, content: nContent, useBDWM: useHtmlContent, parentid: widget.parentid,
                    signature: nSignature, config: config, modify: widget.postid!=null, postid: widget.postid, attachpath: nAttachPath)
                  .then((value) {
                    if (value.success) {
                      // TODO: handle forward (no plan)
                      showAlertDialog(context, "发送成功", const Text("rt"),
                        actions1: TextButton(
                          onPressed: () { Navigator.of(context).pop(); },
                          child: const Text("知道了"),
                        )
                      ).then((value) {
                        nv2Pop(context);
                      });
                    } else {
                      var errorMessage = "发送失败，请稍后重试";
                      if (value.error == 43) {
                        errorMessage = "对不起，您的帖子包含敏感词，请检查后发布";
                      } else if (value.error == -1) {
                        errorMessage = value.result!;
                      }
                      showAlertDialog(context, "发送失败", Text(errorMessage),
                        actions1: TextButton(
                          onPressed: () { Navigator.of(context).pop(); },
                          child: const Text("知道了"),
                        )
                      );
                    }
                  });
                },
                child: Text("发布", style: TextStyle(color: bdwmPrimaryColor)),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
          height: 200,
          child: fquill.QuillEditor(
            controller: _controller,
            scrollController: _scrollController,
            scrollable: true,
            focusNode: _focusNode,
            autoFocus: true,
            readOnly: false,
            expands: false,
            padding: const EdgeInsets.all(5.0),
            keyboardAppearance: Theme.of(context).brightness,
            // locale: const Locale('zh', 'CN'),
            embedBuilders: [ImageEmbedBuilder()],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
          child: fquill.QuillToolbar.basic(
            controller: _controller,
            toolbarSectionSpacing: 1,
            showAlignmentButtons: false,
            showBoldButton: true,
            showUnderLineButton: true,
            showStrikeThrough: false,
            showDirection: false,
            showFontFamily: false,
            showFontSize: false,
            showHeaderStyle: false,
            showIndent: false,
            showLink: false,
            showSearchButton: false,
            showListBullets: false,
            showListNumbers: false,
            showListCheck: false,
            showDividers: false,
            showRightAlignment: false,
            showItalicButton: false,
            showCenterAlignment: false,
            showLeftAlignment: false,
            showJustifyAlignment: false,
            showSmallButton: false,
            showInlineCode: false,
            showCodeBlock: false,
            showColorButton: false,
            showRedo: false,
            showUndo: false,
            showBackgroundColorButton: false,
            customButtons: [
              fquill.QuillCustomButton(
                icon: Icons.color_lens,
                onTap: () {
                  showColorDialog(context, (bdwmRichText['fc'] as Map<String, int>).keys.toList())
                  .then((value) {
                    if (value == null) { return; }
                    _controller.formatSelection(fquill.ColorAttribute(value));
                  });
                }
              ),
              fquill.QuillCustomButton(
                icon: Icons.format_color_fill,
                onTap: () {
                  showColorDialog(context, (bdwmRichText['bc'] as Map<String, int>).keys.toList())
                  .then((value) {
                    if (value == null) { return; }
                    _controller.formatSelection(fquill.BackgroundAttribute(value));
                  });
                }
              ),
              fquill.QuillCustomButton(
                icon: Icons.image,
                onTap: () {
                  showTextDialog(context, "图片链接")
                  .then((value) {
                    if (value==null) { return; }
                    if (value.isEmpty) { return; }
                    var index = _controller.selection.baseOffset;
                    var length = _controller.selection.extentOffset - index;
                    _controller.replaceText(index, length, fquill.BlockEmbed.image(value), null);
                    _controller.formatText(index, 1, const fquill.StyleAttribute("mobileAlignment:topLeft;mobileWidth:150;mobileHeight:150"));
                  },);
                }
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 0),
          child: Wrap(
            // alignment: WrapAlignment.center,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Checkbox(
                value: needNoreply,
                activeColor: bdwmPrimaryColor,
                onChanged: widget.postNewInfo.canNoreply
                  ? (value) {
                    setState(() {
                      needNoreply = value!;
                    });
                  }
                  : null,
              ),
              const Text("不可回复"),
              vDivider,
              Checkbox(
                value: needRemind,
                activeColor: bdwmPrimaryColor,
                onChanged: widget.postNewInfo.canRemind
                  ? (value) {
                    setState(() {
                      needRemind = value!;
                    });
                  }
                  : null,
              ),
              const Text("回复提醒"),
              vDivider,
              // Checkbox(
              //   value: needForward,
              //   activeColor: bdwmPrimaryColor,
              //   onChanged: postNewInfo.canForward
              //     ? (value) {
              //       setState(() {
              //         needForward = value!;
              //       });
              //     }
              //     : null,
              // ),
              // const Text("抄送给原作者"),
              vDivider,
              Checkbox(
                value: needAnony,
                activeColor: bdwmPrimaryColor,
                onChanged: widget.postNewInfo.canAnony
                  ? (value) {
                    setState(() {
                      needAnony = value!;
                    });
                  }
                  : null,
              ),
              const Text("匿名"),
            ],
          ),
        ),
        if (quoteText!=null)
          Container(
            margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
            constraints: const BoxConstraints(
              maxHeight: 100,
            ),
            child: SingleChildScrollView(
              child: HtmlComponent(quoteText!, nickName: widget.nickName,),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
          // alignment: Alignment.center,
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.postNewInfo.quoteInfo.isNotEmpty)
                DropdownButton<SignatureItem>(
                  hint: const Text("引文模式"),
                  icon: const Icon(Icons.arrow_drop_down),
                  value: quoteMode,
                  items: quoteModes.map<DropdownMenuItem<SignatureItem>>((SignatureItem item) {
                    return DropdownMenuItem<SignatureItem>(
                      value: item,
                      child: Text(item.key),
                    );
                  }).toList(),
                  onChanged: (SignatureItem? value) {
                    if (value == null) { return; }
                    widget.updateQuote(value.value).then((quoteValue) {
                      if (!mounted) { return; }
                      setState(() {
                        quoteText = quoteValue;
                        quoteMode = value;
                      });
                    });
                  },
                ),
              TextButton(
                onPressed: () {
                  showUploadDialog(context, widget.postNewInfo.attachpath, attachFiles)
                  .then((value) {
                    if (value == null) { return; }
                    var content = jsonDecode(value);
                    attachCount = content['count'];
                    attachFiles = [];
                    for (var f in content['files']) {
                      attachFiles.add(f);
                    }
                  },);
                },
                child: const Text("管理附件"),
              ),
              DropdownButton<SignatureItem>(
                hint: const Text("签名档"),
                icon: const Icon(Icons.arrow_drop_down),
                value: signature,
                items: [
                  DropdownMenuItem<SignatureItem>(
                    value: signatureOB,
                    child: const Text("OBViewer"),
                  ),
                  ...widget.postNewInfo.signatureInfo.map<DropdownMenuItem<SignatureItem>>((SignatureItem item) {
                    return DropdownMenuItem<SignatureItem>(
                      value: item,
                      child: Text(item.key),
                    );
                  }).toList(),
                ],
                onChanged: (SignatureItem? value) {
                  setState(() {
                    signature = value!;
                  });
                },
              ),
            ],
          ),
        )
      ],
    );
  }
}

class PostNewFuturePage extends StatefulWidget {
  final String bid;
  final String? postid;
  final String? parentid;
  final String? nickName;
  const PostNewFuturePage({super.key, required this.bid, this.postid, this.parentid, this.nickName});

  @override
  State<PostNewFuturePage> createState() => _PostNewFuturePageState();
}

class _PostNewFuturePageState extends State<PostNewFuturePage> {
  late CancelableOperation getDataCancelable;

  Future<PostNewInfo> getData() async {
    var url = "$v2Host/post-new.php?bid=${widget.bid}";
    if (widget.postid != null) {
      url += "&mode=modify&postid=${widget.postid}";
    } else if (widget.parentid != null) {
      url += "&parentid=${widget.parentid}";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return PostNewInfo.error(errorMessage: networkErrorText);
    }
    return parsePostNew(resp.body);
  }

  Future<String?> getPostQuote({String mode="simple"}) async {
    var resp = await bdwmGetPostQuote(bid: widget.bid, postid: widget.parentid!, mode: mode);
    if (!resp.success) {
      return networkErrorText;
    }
    return resp.result!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.parentid == null) {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
        // debugPrint("cancel it");
      },);
    } else {
      getDataCancelable = CancelableOperation.fromFuture(Future.wait([getData(), getPostQuote()]), onCancel: () {
        // debugPrint("cancel it");
      },);
    }
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("错误：${snapshot.error}"),);
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("错误：未获取数据"),);
        }
        PostNewInfo postNewInfo;
        String? quoteText;
        if (widget.parentid == null) {
          postNewInfo = snapshot.data as PostNewInfo;
        } else {
          postNewInfo = (snapshot.data as List)[0];
          quoteText = (snapshot.data as List)[1];
        }
        if (postNewInfo.errorMessage != null) {
          return Center(
            child: Text(postNewInfo.errorMessage!),
          );
        }
        return PostNewPage(
          postNewInfo: postNewInfo, parentid: widget.parentid,
          postid: widget.postid, bid: widget.bid, quoteText: quoteText,
          nickName: widget.nickName,
          updateQuote: (String mode) { return getPostQuote(mode: mode); },
        );
      }
    );
  }
}
