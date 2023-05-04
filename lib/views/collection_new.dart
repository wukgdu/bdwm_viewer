import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as fquill;

import '../bdwm/collection.dart' show bdwmCollectionNew;
import './constants.dart';
import '../globalvars.dart' show v2Host;
import './quill_utils.dart';
import './utils.dart';
import '../html_parser/collectionnew_parser.dart';
import './upload.dart';
import '../router.dart' show nv2Replace, nv2Pop;
import './editor.dart' show FquillEditor, FquillEditorToolbar, genController;

class CollectionNewView extends StatefulWidget {
  final String mode;
  final String baseOrPath;
  final CollectionNewInfo collectionNewInfo;
  final String baseName;
  const CollectionNewView({super.key, required this.mode, required this.baseOrPath, required this.collectionNewInfo, required this.baseName});

  @override
  State<CollectionNewView> createState() => _CollectionNewViewState();
}

class _CollectionNewViewState extends State<CollectionNewView> {
  late final fquill.QuillController _controller;
  TextEditingController titleValue = TextEditingController();
  bool useHtmlContent = true;
  int attachCount = 0;
  List<String> attachFiles = [];

  @override
  void initState() {
    super.initState();
    var content = widget.collectionNewInfo.contentHtml;
    _controller = genController(content);
    if (widget.collectionNewInfo.titleText != null && widget.collectionNewInfo.titleText!.isNotEmpty) {
      if (titleValue.text.isEmpty) {
        titleValue.value = TextEditingValue(text: widget.collectionNewInfo.titleText!);
      }
    }
    attachFiles = widget.collectionNewInfo.attachFiles;
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
    debugPrint("collection new rebuild");
    return ListView(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
          child: Row(
            children: [
              // const Text("标题"),
              Expanded(
                child: TextField(
                  autofocus: widget.mode=="new", // 发帖
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

                  var quillDelta = _controller.document.toDelta().toJson();
                  debugPrint(quillDelta.toString());
                  String postContent = "";
                  try {
                    postContent = quill2BDWMtext(quillDelta);
                  } catch (e) {
                    if (!mounted) { return; }
                    showInformDialog(context, "内容格式错误", "$e\n请截图找 onepiece 报bug");
                  }
                  if (postContent.isEmpty) {
                    return;
                  }
                  debugPrint(postContent);

                  var nContent = useHtmlContent ? postContent : _controller.document.toPlainText();
                  var nAttachPath = widget.mode == "new"
                    ? attachCount > 0
                      ? widget.collectionNewInfo.attachpath : ""
                    : widget.collectionNewInfo.attachpath;
                  bdwmCollectionNew(
                    title: titleValue.text, content: nContent, simple: !useHtmlContent,
                    attachpath: nAttachPath, mode: widget.mode, baseOrPath: widget.baseOrPath)
                  .then((value) {
                    if (value.success) {
                      showInformDialog(context, "操作成功", "rt")
                      .then((value2) {
                        var name = value.name!;
                        if (name.isEmpty && widget.mode=="new") { return; }
                        var path = widget.mode=="new" ? "${widget.baseOrPath}/$name" : widget.baseOrPath;
                        if (widget.mode!="new") {
                          nv2Pop(context);
                        }
                        nv2Replace(context, '/collectionArticle', arguments: {
                          "link": "$v2Host/collection-read.php?path=$path",
                          "title": widget.baseName,
                        });
                      });
                    } else {
                      var errorMessage = "创建/修改精华区文件失败";
                      if (value.error == -1) {
                        errorMessage = value.errorMessage!;
                      }
                      showInformDialog(context, "失败", errorMessage);
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
          child: FquillEditor(controller: _controller, autoFocus: false,),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
          child: FquillEditorToolbar(controller: _controller,)
        ),
        Container(
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
          // alignment: Alignment.center,
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  showUploadDialog(context, widget.collectionNewInfo.attachpath, attachFiles)
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
            ],
          ),
        ),
      ],
    );
  }
}
