import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_quill/flutter_quill.dart' as fquill;
import 'package:flutter_quill_extensions/embeds/builders.dart' show ImageEmbedBuilder;

import '../bdwm/mail.dart';
import '../bdwm/req.dart';
import './constants.dart';
import '../globalvars.dart';
import './quill_utils.dart';
import '../html_parser/utils.dart' show SignatureItem;
import '../html_parser/mailnew_parser.dart';
import './utils.dart';

class MailNewPage extends StatefulWidget {
  final String? parentid;
  final String? content;
  final String? quote;
  final MailNewInfo mailNewInfo;
  final String? title;
  final String? receivers;
  const MailNewPage({super.key, this.parentid, this.content, this.quote, required this.mailNewInfo, this.title, this.receivers});

  @override
  State<MailNewPage> createState() => _MailNewPageState();
}

class _MailNewPageState extends State<MailNewPage> {
  late final fquill.QuillController _controller;
  TextEditingController titleValue = TextEditingController();
  TextEditingController receiveValue = TextEditingController();
  List<String>? friends;
  SignatureItem? signature;
  int attachCount = 0;
  final signatureOB = SignatureItem(key: "OBViewer", value: "OBViewer");
  @override
  void initState() {
    if (widget.content != null || widget.quote != null) {
      var clist = [];
      var qlist = [];
      var deltaList = [];
      if (widget.content != null) {
        clist = html2Quill(widget.content!);
      }
      if (widget.quote != null) {
        qlist = html2Quill(widget.quote!);
        if (clist.isEmpty) {
          qlist.insert(0, {"insert": "\n"});
        }
      }
      deltaList = clist + qlist;
      _controller = fquill.QuillController(
        document: fquill.Document.fromJson(deltaList),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _controller = fquill.QuillController.basic();
    }
    if (widget.title != null && widget.title!.isNotEmpty) {
      titleValue.text = widget.title!;
    }
    if (widget.receivers != null && widget.receivers!.isNotEmpty) {
      receiveValue.text = widget.receivers!;
    }
    super.initState();
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
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
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
                onPressed: () {
                  var quillDelta = _controller.document.toDelta().toJson();
                  debugPrint(quillDelta.toString());
                  debugPrint(quill2BDWMtext(quillDelta));
                },
                child: const Text("发送", style: TextStyle(color: bdwmPrimaryColor)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            controller: receiveValue,
            decoration: const InputDecoration(
              labelText: "收件人",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10.0),
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
                  },);
                }
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          margin: const EdgeInsets.all(10.0),
          height: 300,
          child: fquill.QuillEditor.basic(
            controller: _controller,
            readOnly: false, // true for view only mode
            embedBuilders: [ImageEmbedBuilder()],
            // locale: const Locale('zh', 'CN'),
          ),
        ),
          Container(
            margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
            // alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                  DropdownButton<SignatureItem>(
                    hint: const Text("签名档"),
                    icon: const Icon(Icons.arrow_drop_down),
                    value: signature,
                    items: [
                      ...widget.mailNewInfo.signatureInfo.map<DropdownMenuItem<SignatureItem>>((SignatureItem item) {
                        return DropdownMenuItem<SignatureItem>(
                            value: item,
                            child: Text(item.key),
                          );
                        }).toList(),
                      DropdownMenuItem<SignatureItem>(
                        value: signatureOB,
                        child: const Text("OBViewer"),
                      )
                    ],
                    onChanged: (SignatureItem? value) {
                      setState(() {
                        signature = value!;
                      });
                    },
                  ),
                TextButton(
                  onPressed: () {
                  },
                  child: const Text("管理附件"),
                ),
              ],
            ),
          )
      ],
    );
  }
}

class MailNewFuturePage extends StatefulWidget {
  final String? parentid;
  const MailNewFuturePage({super.key, this.parentid});

  @override
  State<MailNewFuturePage> createState() => _MailNewFuturePageState();
}

class _MailNewFuturePageState extends State<MailNewFuturePage> {
  late CancelableOperation getDataCancelable;

  Future<MailNewInfo> getData() async {
    var url = "$v2Host/mail-new.php";
    if (widget.parentid != null) {
      url += "?parentid=${widget.parentid}";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return MailNewInfo.error(errorMessage: networkErrorText);
    }
    return parseMailNew(resp.body);
  }

  Future<String?> getMailQuote() async {
    var resp = await bdwmGetMailQuote(postid: widget.parentid!);
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
      getDataCancelable = CancelableOperation.fromFuture(Future.wait([getData(), getMailQuote()]), onCancel: () {
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
        return MailNewPage(
          mailNewInfo: mailNewInfo, parentid: widget.parentid,
          title: mailNewInfo.title, receivers: mailNewInfo.receivers,
          content: null, quote: quoteText,
        );
      }
    );
  }
}