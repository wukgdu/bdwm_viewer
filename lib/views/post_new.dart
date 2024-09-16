import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_quill/flutter_quill.dart' as fquill;

import '../bdwm/posts.dart';
import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/postnew_parser.dart';
import '../html_parser/utils.dart' show SignatureItem;
import './constants.dart';
import './html_widget.dart';
import './quill_utils.dart';
import './upload.dart';
import './utils.dart';
import '../router.dart' show nv2Pop, forceRefresh, nv2Replace;
import './editor.dart' show FquillEditor, FquillEditorToolbar, genController, genControllerFromJson;
import './multi_users.dart' show SwitchUsersComponent;
import '../pages/post_new.dart' show PostNewPage;

class PostNewView extends StatefulWidget {
  final String bid;
  final String? postid;
  final String? parentid;
  // final String boardName;
  final PostNewInfo postNewInfo;
  final String? quoteText;
  final String? nickName;
  final FutureOrFunction<String> updateQuote;
  final void Function(String?)? refresh;
  const PostNewView({super.key, required this.bid, this.postid, this.parentid, required this.postNewInfo, this.quoteText, required this.updateQuote, this.nickName, this.refresh});

  @override
  State<PostNewView> createState() => _PostNewViewState();
}

class _PostNewViewState extends State<PostNewView> {
  late final fquill.QuillController _controller;
  TextEditingController titleValue = TextEditingController();
  bool needNoreply = false;
  bool needRemind = true;
  bool needForward = false;
  bool needAnony = false;
  SignatureItem? signature;
  final signatureOB = SignatureItem(key: "OBViewer", value: "OBViewer");
  static const vDivider = SizedBox(width: 8,);
  final quoteModes = <SignatureItem>[SignatureItem(key: "精简引文", value: "simple"), SignatureItem(key: "完整引文", value: "full")];
  late SignatureItem quoteMode;
  int attachCount = 0;
  List<String> attachFiles = [];
  String? quoteText;

  bool useHtmlContent = true;

  @override
  void initState() {
    super.initState();
    // _future = getData();
    quoteMode = quoteModes[0];
    quoteText = widget.quoteText;
    needAnony = widget.postNewInfo.canAnony;
    var content = widget.postNewInfo.contentHtml;
    _controller = genController(content);

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
    if (signature == null) {
      for (var item in widget.postNewInfo.signatureInfo) {
        if (item.value == globalImmConfigInfo.getQmd()) {
          signature = item;
          break;
        }
      }
      if (signatureOB.value == globalImmConfigInfo.getQmd()) {
        signature = signatureOB;
      }
    }
    signature ??= signatureOB;

    attachFiles = widget.postNewInfo.attachFiles;
    attachCount = attachFiles.length;
  }

  @override
  void dispose() {
    _controller.dispose();
    titleValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("post new rebuild");
    return ListView(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
          child: Row(
            children: [
              // const Text("标题"),
              Expanded(
                child: TextField(
                  autofocus: (widget.parentid == null) && (widget.postid == null), // 发帖
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
                    var maxS = widget.postNewInfo.sigCount;
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
                  var value = await bdwmSimplePost(
                    bid: widget.bid, title: titleValue.text, content: nContent, useBDWM: useHtmlContent, parentid: widget.parentid,
                    signature: nSignature, config: config, modify: widget.postid!=null, postid: widget.postid, attachpath: nAttachPath);
                  if (value.success) {
                    // TODO: handle forward (no plan)
                    if (globalConfigInfo.getSavePostHistory()) {
                      var timestamp1000 = DateTime.now().millisecondsSinceEpoch;
                      var boardName = "未知版面";
                      var newPostLink = "$v2Host/post-read.php?bid=${widget.bid}&threadid=${value.threadid}&page=a&postid=${value.postid}#${value.postid}";
                      if (value.threadid == null || value.threadid == -1) {
                        newPostLink = "$v2Host/post-read-single.php?bid=${widget.bid}&postid=${value.postid}";
                      }
                      if (!context.mounted) { return; }
                      var postNewPageWidget = context.findAncestorWidgetOfExactType<PostNewPage>();
                      if (postNewPageWidget != null) {
                        boardName = postNewPageWidget.boardName;
                      }
                      await globalPostHistoryData.addOne(
                        link: newPostLink,
                        title: titleValue.text,
                        boardName: boardName,
                        userName: globalUInfo.username,
                        timestamp: timestamp1000,
                      );
                    }
                    if (!context.mounted) { return; }
                    showAlertDialog(context, "发送成功", const Text("rt"),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      )
                    ).then((value2) {
                      if (widget.parentid == null && widget.postid == null) {
                        // 版面发新帖
                        if (value.threadid == null || value.threadid == -1) { return; }
                        if (value.postid == null || value.postid == -1) { return; }
                        if (context.mounted) {
                          nv2Replace(context, '/thread', arguments: {
                            'bid': widget.bid,
                            'threadid': value.threadid.toString(),
                            'postid': value.postid.toString(),
                            'boardName': "发帖",
                            'page': 'a',
                            'needToBoard': false,
                          });
                        }
                        // forceRefresh(value.postid!);
                      } else {
                        forceRefresh(value.postid ?? -1);
                        if (context.mounted) {
                          nv2Pop(context);
                        }
                      }
                    });
                  } else {
                    var errorMessage = "发送失败，请稍后重试";
                    if (value.error == 43) {
                      errorMessage = "对不起，您的帖子包含敏感词，请检查后发布";
                    } else if (value.error == -1) {
                      errorMessage = value.result!;
                    }
                    if (!context.mounted) { return; }
                    showAlertDialog(context, "发送失败", Text(errorMessage),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      )
                    );
                  }
                },
                child: Text("发布", style: TextStyle(color: bdwmPrimaryColor)),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 0),
          child: Row(
            children: [
              const Text(accountChinese, style: TextStyle(fontSize: 14),),
              vDivider,
              SwitchUsersComponent(showLogin: false, refresh: widget.refresh,),
              const Spacer(),
              const Text("草稿", style: TextStyle(fontSize: 14),),
              vDivider,
              SizedIconButton(
                size: 24,
                onPressed: () async {
                  // TODO: allow more drafts
                  var draftPath = await genAppFilename("bdwmdraft-1.json");
                  var file = File(draftPath).openWrite();
                  var jsonData = _controller.document.toDelta().toJson();
                  file.write(jsonEncode(jsonData));
                  await file.flush();
                  await file.close();
                  if (!context.mounted) { return; }
                  await showInformDialog(context, "已保存草稿", "只保存正文（富文本）；只预览纯文本");
                },
                icon: Icon(Icons.save_as, size: 16, color: bdwmPrimaryColor,),
              ),
              vDivider,
              SizedIconButton(
                size: 24,
                onPressed: () async {
                  var draftPath = await genAppFilename("bdwmdraft-1.json");
                  var content = await File(draftPath).readAsString();
                  var jsonData = jsonDecode(content);
                  if (!context.mounted) { return; }
                  var tmpController = genControllerFromJson(jsonData as List<dynamic>);
                  var res = await showComplexConfirmDialog(context, "加载草稿", SingleChildScrollView(
                    child: SelectableText(tmpController.document.toPlainText()),
                  ));
                  // FquillEditor(controller: tmpController, autoFocus: false, height: 200.0, readOnly: true,),
                  tmpController.dispose();
                  if (res != "yes") { return; }
                  _controller.document = fquill.Document.fromJson(jsonData);
                },
                icon: Icon(Icons.input, size: 16, color: bdwmPrimaryColor,),
              )
            ],
          )
        ),
        // Container(
        //   decoration: BoxDecoration(
        //     border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
        //     borderRadius: const BorderRadius.all(Radius.circular(5)),
        //   ),
        //   margin: const EdgeInsets.only(left: 10, right: 10, top: 0),
        //   height: 200,
        //   child: FquillEditor(controller: _controller, autoFocus: widget.parentid != null,),
        // ),
        FquillEditor(controller: _controller, autoFocus: widget.parentid != null, height: 200.0,),
        Center(
          child: FquillEditorToolbar(controller: _controller,)
        ),
        Container(
          margin: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 0),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
              vDivider,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                ],
              ),
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
              // vDivider,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      child: item.value.isEmpty ? Text("签名档：${item.key}") : Text(item.key),
                    );
                  }),
                ],
                onChanged: (SignatureItem? value) async {
                  if (value == null) { return; }
                  if (widget.postid == null) {
                    await globalImmConfigInfo.setQmd(value.value);
                  }
                  setState(() {
                    signature = value;
                  });
                },
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  showUploadDialog(context, widget.postNewInfo.attachpath, attachFiles, showAttachLink: globalImmConfigInfo.getShowAttachLink())
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: globalImmConfigInfo.getShowAttachLink(),
                    activeColor: bdwmPrimaryColor,
                    onChanged: (value) async {
                      if (value == null) { return; }
                      await globalImmConfigInfo.setShowAttachLink(value);
                      setState(() { });
                    }
                  ),
                  const Text("上传后弹出链接"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PostNewFutureView extends StatefulWidget {
  final String bid;
  final String? postid;
  final String? parentid;
  final String? nickName;
  const PostNewFutureView({super.key, required this.bid, this.postid, this.parentid, this.nickName});

  @override
  State<PostNewFutureView> createState() => _PostNewFutureViewState();
}

class _PostNewFutureViewState extends State<PostNewFutureView> {
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

  void refresh() {
    if (widget.parentid == null) {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
        // debugPrint("cancel it");
      },);
    } else {
      getDataCancelable = CancelableOperation.fromFuture(Future.wait([getData(), getPostQuote()]), onCancel: () {
        // debugPrint("cancel it");
      },);
    }
    setState(() { });
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
        return PostNewView(
          postNewInfo: postNewInfo, parentid: widget.parentid,
          postid: widget.postid, bid: widget.bid, quoteText: quoteText,
          nickName: widget.nickName,
          updateQuote: (String mode) { return getPostQuote(mode: mode); },
          refresh: (String? uid) {
            refresh();
          },
        );
      }
    );
  }
}
