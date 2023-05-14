import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_quill/flutter_quill.dart' as fquill;

import '../bdwm/search.dart';
import '../bdwm/mail.dart';
import '../bdwm/req.dart';
import '../bdwm/posts.dart' show bdwmGetPostQuote;
import './constants.dart';
import '../globalvars.dart';
import './html_widget.dart';
import './quill_utils.dart';
import '../html_parser/utils.dart' show SignatureItem;
import '../html_parser/mailnew_parser.dart';
import './utils.dart';
import './upload.dart';
import '../router.dart' show nv2Pop;
import './editor.dart' show FquillEditor, FquillEditorToolbar, genController;

class MailNewView extends StatefulWidget {
  final String? bid;
  final String? parentid;
  final String? content;
  final String? quote;
  final MailNewInfo mailNewInfo;
  final String? title;
  final String? receivers;
  final FutureOrFunction<String> updateQuote;
  const MailNewView({super.key, this.bid, this.parentid, this.content, this.quote, required this.mailNewInfo, this.title, this.receivers, required this.updateQuote});

  @override
  State<MailNewView> createState() => _MailNewViewState();
}

class _MailNewViewState extends State<MailNewView> {
  late final fquill.QuillController _controller;
  TextEditingController titleValue = TextEditingController();
  TextEditingController receiveValue = TextEditingController();
  List<String>? friends;
  SignatureItem? signature;
  int attachCount = 0;
  List<String> attachFiles = [];
  final quoteModes = <SignatureItem>[SignatureItem(key: "精简引文", value: "simple"), SignatureItem(key: "完整引文", value: "full")];
  late SignatureItem quoteMode;
  String? quoteText;

  final signatureOB = SignatureItem(key: "OBViewer", value: "OBViewer");
  @override
  void initState() {
    super.initState();
    quoteText = widget.quote;
    quoteMode = quoteModes[1];
    _controller = genController(widget.content);
    if (widget.title != null && widget.title!.isNotEmpty) {
      titleValue.text = widget.title!;
    }
    if (widget.receivers != null && widget.receivers!.isNotEmpty) {
      receiveValue.text = widget.receivers!;
    }

    if (signature == null) {
      for (var item in widget.mailNewInfo.signatureInfo) {
        if (item.value == globalImmConfigInfo.getQmd()) {
          signature = item;
          break;
        }
      }
      if (signatureOB.value == globalImmConfigInfo.getQmd()) {
        signature = signatureOB;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    titleValue.dispose();
    receiveValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
          child: TextField(
            controller: receiveValue,
            decoration: const InputDecoration(
              labelText: "收件人",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
          child: Row(
            children: [
              // const Text("标题"),
              Expanded(
                child: TextField(
                  // autofocus: widget.parentid == null, // 发帖
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

                  if (receiveValue.text.isEmpty) {
                    showAlertDialog(context, "有问题", const Text("收件人不能为空"),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      )
                    );
                    return;
                  }
                  List<String> rcvuidsStr = receiveValue.text.split(RegExp(r";|\s+|,|，|；"));
                  rcvuidsStr.removeWhere((element) => element.isEmpty);
                  var userRes = await bdwmUserInfoSearch(rcvuidsStr);
                  var rcvuids = <int>[];
                  if (userRes.success == false) {
                    if (!mounted) { return; }
                    await showAlertDialog(context, "发送中", const Text("查找用户失败"),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      ),
                    );
                    return;
                  } else {
                    var uidx = 0;
                    for (var r in userRes.users) {
                      if (r == false) {
                        if (!mounted) { return; }
                        await showAlertDialog(context, "发送中", Text("用户${rcvuidsStr[uidx]}不存在"),
                          actions1: TextButton(
                            onPressed: () { Navigator.of(context).pop(); },
                            child: const Text("知道了"),
                          ),
                        );
                        return;
                      } else {
                        rcvuids.add(int.parse((r as IDandName).id));
                      }
                      uidx += 1;
                    }
                  }

                  var nSignature = signature?.value ?? "";
                  if (nSignature == "random") {
                    var maxS = widget.mailNewInfo.sigCount;
                    var randomI = math.Random().nextInt(maxS);
                    nSignature = randomI.toString();
                  } else if (nSignature == "OBViewer") {
                    nSignature = jsonEncode(signatureOBViewer);
                  }

                  var quillDelta = _controller.document.toDelta().toJson();
                  debugPrint(quillDelta.toString());
                  String mailContent = "";
                  try {
                    mailContent = quill2BDWMtext(quillDelta);
                  } catch (e) {
                    if (!mounted) { return; }
                    showAlertDialog(context, "内容格式错误", Text("$e\n请返回后截图找 onepiece 报bug"),
                      actions1: TextButton(
                        onPressed: () { Navigator.of(context).pop(); },
                        child: const Text("知道了"),
                      ),
                    );
                  }
                  if (mailContent.isEmpty) {
                    return;
                  }
                  if (quoteText != null) {
                    var mailQuote = bdwmTextFormat(quoteText!, mail: true);
                    // ...{}] [{}...
                    mailContent = "${mailContent.substring(0, mailContent.length-1)},${mailQuote.substring(1)}";
                  }
                  debugPrint(mailContent);

                  var nAttachPath = attachCount > 0 ? widget.mailNewInfo.attachpath : "";
                  bdwmCreateMail(
                    rcvuids: rcvuids, title: titleValue.text, content: mailContent, parentid: widget.parentid,
                    signature: nSignature, attachpath: nAttachPath, bid: widget.bid)
                  .then((value) {
                    if (value.success == false) {
                      var errReason = "发送失败，请稍后重试";
                      if (value.error == -1) {
                        errReason = value.result ?? networkErrorText;
                      } else if (value.error == 9) {
                        errReason = "您的发信权已被封禁";
                      }
                      showAlertDialog(context, "发送失败", Text(errReason),
                        actions1: TextButton(
                          onPressed: () { Navigator.of(context).pop(); },
                          child: const Text("知道了"),
                        ),
                      );
                    } else {
                      var n = "";
                      var uidx = 0;
                      for (var u in rcvuids) {
                        if (value.sent.contains(u) == false) {
                          n += " ${rcvuidsStr[uidx]}";
                        }
                        uidx += 1;
                      }
                      var txt = "发送成功";
                      if (n.isNotEmpty) {
                        txt = "部分成功，发送给用户$n 的信件未发送成功";
                      }
                      showAlertDialog(context, "站内信", Text(txt),
                        actions1: TextButton(
                          onPressed: () { Navigator.of(context).pop(); },
                          child: const Text("知道了"),
                        ),
                      ).then((value) {
                        nv2Pop(context);
                      },);
                    }
                  });
                },
                child: Text("发送", style: TextStyle(color: bdwmPrimaryColor)),
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
          child: FquillEditor(controller: _controller, autoFocus: false),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
          child: FquillEditorToolbar(controller: _controller),
        ),
        if (quoteText!=null)
          Container(
            margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
            height: 100,
            child: SingleChildScrollView(
              child: HtmlComponent(quoteText!),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
          // alignment: Alignment.center,
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.mailNewInfo.quoteInfo.isNotEmpty)
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
                  showUploadDialog(context, widget.mailNewInfo.attachpath, attachFiles)
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
                  ...widget.mailNewInfo.signatureInfo.map<DropdownMenuItem<SignatureItem>>((SignatureItem item) {
                    return DropdownMenuItem<SignatureItem>(
                      value: item,
                      child: Text(item.key),
                    );
                  }).toList(),
                ],
                onChanged: (SignatureItem? value) async {
                  if (value == null) { return; }
                  await globalImmConfigInfo.setQmd(value.value);
                  setState(() {
                    signature = value;
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

class MailNewFutureView extends StatefulWidget {
  final String? bid;
  final String? parentid;
  final String? receiver;
  const MailNewFutureView({super.key, this.bid, this.parentid, this.receiver});

  @override
  State<MailNewFutureView> createState() => _MailNewFutureViewState();
}

class _MailNewFutureViewState extends State<MailNewFutureView> {
  late CancelableOperation getDataCancelable;

  Future<MailNewInfo> getData() async {
    var url = "$v2Host/mail-new.php";
    if (widget.bid != null) {
      url += "?frombid=${widget.bid}&frompostid=${widget.parentid}";
    } else if (widget.parentid != null) {
      url += "?parentid=${widget.parentid}";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return MailNewInfo.error(errorMessage: networkErrorText);
    }
    return parseMailNew(resp.body);
  }

  Future<String?> getQuote({String mode="full"}) async {
    if (widget.bid == null) {
      return await getMailQuote(mode: mode);
    }
    var resp = await bdwmGetPostQuote(bid: widget.bid!, postid: widget.parentid!, mode: mode);
    if (!resp.success) {
      return networkErrorText;
    }
    return resp.result!;
  }

  Future<String?> getMailQuote({String mode="full"}) async {
    var resp = await bdwmGetMailQuote(postid: widget.parentid!, mode: mode);
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
      },);
    } else {
      getDataCancelable = CancelableOperation.fromFuture(Future.wait([getData(), getQuote()]), onCancel: () {
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
        MailNewInfo mailNewInfo;
        String? quoteText;
        if (widget.parentid == null) {
          mailNewInfo = snapshot.data as MailNewInfo;
        } else {
          mailNewInfo = (snapshot.data as List)[0];
          quoteText = (snapshot.data as List)[1];
        }
        if (mailNewInfo.errorMessage != null) {
          return Center(
            child: Text(mailNewInfo.errorMessage!),
          );
        }
        return MailNewView(
          mailNewInfo: mailNewInfo, parentid: widget.parentid,
          title: mailNewInfo.title, receivers: widget.receiver ?? mailNewInfo.receivers,
          content: null, quote: quoteText, bid: widget.bid,
          updateQuote: (String mode) { return getQuote(mode: mode); },
        );
      }
    );
  }
}
