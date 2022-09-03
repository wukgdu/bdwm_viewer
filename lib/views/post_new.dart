import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/posts.dart';
import '../views/html_widget.dart';
import '../bdwm/req.dart';
import './constants.dart';
import '../globalvars.dart';
import '../html_parser/postnew_parser.dart';
import './utils.dart';

class PostNewPage extends StatefulWidget {
  final String bid;
  final String? postid;
  final String? parentid;
  // final String boardName;
  const PostNewPage({Key? key, required this.bid, this.postid, this.parentid}) : super(key: key);

  @override
  State<PostNewPage> createState() => _PostNewPageState();
}

class _PostNewPageState extends State<PostNewPage> {
  TextEditingController titleValue = TextEditingController();
  TextEditingController contentValue = BDWMTextEditingController();
  bool needNoreply = false;
  bool needRemind = true;
  bool needForward = false;
  bool needAnony = false;
  SignatureItem? signature;
  final signatureOB = SignatureItem(key: "OBViewer", value: "OBViewer");
  static const vDivider = VerticalDivider();
  FocusNode contentFocusNode = FocusNode();

  late CancelableOperation getDataCancelable;

  bool useHtmlContent = true;

  Future<PostNewInfo> getData() async {
    var url = "$v2Host/post-new.php?bid=${widget.bid}";
    if (widget.postid != null) {
      url += "&mode=modify&postid=${widget.postid}";
    } else if (widget.parentid != null) {
      url += "&parentid=${widget.parentid}";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    return parsePostNew(resp.body);
  }

  Future<String?> getPostQuote() async {
    var resp = await bdwmGetPostQuote(bid: widget.bid, postid: widget.parentid!);
    if (resp.success) {
      return resp.result!;
    }
    return resp.result!;
  }

  Future<PostNewInfo> getExampleData() async {
    debugPrint("get PostNew data");
    return getData();
  }

  @override
  void initState() {
    super.initState();
    // _future = getData();
    if (widget.parentid == null) {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
        debugPrint("cancel it");
      },);
    } else {
      getDataCancelable = CancelableOperation.fromFuture(Future.wait([getData(), getPostQuote()]), onCancel: () {
        debugPrint("cancel it");
      },);
    }
    contentFocusNode.addListener(() {
      if (contentFocusNode.hasFocus) {
        var text = contentValue.text;
        contentValue.clearComposing();
        contentValue.clear();
        (contentValue as BDWMTextEditingController).toggle();
        contentValue.value = TextEditingValue(text: text);
      } else {
        var text = contentValue.text;
        contentValue.clearComposing();
        contentValue.clear();
        (contentValue as BDWMTextEditingController).toggle();
        contentValue.value = TextEditingValue(text: text);
      }
      contentValue.selection = TextSelection.fromPosition(const TextPosition(affinity: TextAffinity.downstream, offset: 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("post rebuild");
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text("错误：${snapshot.error}");
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text("错误：未获取数据");
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
        if (postNewInfo.titleText != null && postNewInfo.titleText!.isNotEmpty) {
          if (titleValue.text.isEmpty) {
            titleValue.value = TextEditingValue(text: postNewInfo.titleText!);
          }
        }
        if (postNewInfo.contentText != null && postNewInfo.contentText!.isNotEmpty) {
          if (contentValue.text.isEmpty && !useHtmlContent) {
            contentValue.value = TextEditingValue(text: postNewInfo.contentText!);
          }
        }
        if (postNewInfo.contentHtml != null && postNewInfo.contentHtml!.isNotEmpty) {
          if (contentValue.text.isEmpty && useHtmlContent) {
            contentValue.value = TextEditingValue(text: postNewInfo.contentHtml!);
          }
        }
        if (widget.parentid != null && quoteText != null && contentValue.text.isEmpty) {
          if (useHtmlContent) {
            contentValue.value = TextEditingValue(text: "\n$quoteText");
          }
        }
        if (signature == null && widget.postid != null) {
          for (var item in postNewInfo.signatureInfo) {
            if (item.value == "keep") {
              signature = item;
              break;
            }
          }
        }
        return Column(
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
                    onPressed: () {
                      if (titleValue.text.isEmpty) {
                        showAlertDialog(context, "有问题", const Text("标题不能为空"),
                          actions1: TextButton(
                            onPressed: () { Navigator.of(context).pop(); },
                            child: const Text("知道了"),
                          )
                        );
                        return;
                      }
                      if (contentValue.text.isEmpty) {
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
                        moreCount -= 1; // skip OBViewer
                        var maxS = postNewInfo.signatureInfo.length - moreCount;
                        var randomI = math.Random().nextInt(maxS);
                        nSignature = randomI.toString();
                      } else if (nSignature == "keep") {
                        nSignature = postNewInfo.oriSignature ?? "";
                      } else if (nSignature == "OBViewer") {
                        nSignature = jsonEncode([
                            {"content":"发自 onepiece 的客户端\n","fore_color":9,"back_color":9,"bold":false,"blink":false,"underline":false,"reverse":false,"type":"ansi"},
                          ]
                        );
                      }
                      var nContent = useHtmlContent ? bdwmTextFormat(contentValue.text) : contentValue.text;
                      bdwmSimplePost(
                        bid: widget.bid, title: titleValue.text, content: nContent, useBDWM: useHtmlContent, parentid: widget.parentid,
                        signature: nSignature, config: config, modify: widget.postid!=null, postid: widget.postid)
                      .then((value) {
                        if (value.success) {
                          // TODO: handle forward
                          showAlertDialog(context, "发送成功", const Text("rt"),
                            actions1: TextButton(
                              onPressed: () { Navigator.of(context).pop(); },
                              child: const Text("知道了"),
                            )
                          ).then((value) {
                            Navigator.of(context).pop(true);
                          });
                        } else {
                          var errorMessage = "发送失败，请稍后重试";
                          if (value.error == 43) {
                            errorMessage = "对不起，您的帖子包含敏感词，请检查后发布";
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
                    child: const Text("发布", style: TextStyle(color: bdwmPrimaryColor)),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 10),
              child: TextField(
                minLines: 5,
                maxLines: 10,
                controller: contentValue,
                focusNode: contentFocusNode,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: "正文",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 0),
              child: Wrap(
                // alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Checkbox(
                    value: needNoreply,
                    activeColor: bdwmPrimaryColor,
                    onChanged: postNewInfo.canNoreply
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
                    onChanged: postNewInfo.canRemind
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
                    onChanged: postNewInfo.canAnony
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
            Container(
              margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
              alignment: Alignment.center,
              child: DropdownButton<SignatureItem>(
                hint: const Text("签名档"),
                icon: const Icon(Icons.arrow_drop_down),
                value: signature,
                items: [
                  ...postNewInfo.signatureInfo.map<DropdownMenuItem<SignatureItem>>((SignatureItem item) {
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
            ),
          ],
        );
      },
    );
  }
}
