import 'dart:convert';
import 'dart:math' show min;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// import '../globalvars.dart';
import '../utils.dart' show checkAndRequestStoragePermission;
import "./utils.dart";
import './constants.dart';
import '../bdwm/upload.dart';

class UploadFileStatus {
  String name = "";
  String status = "";

  UploadFileStatus.empty();
  UploadFileStatus({
    required this.name,
    required this.status,
  });
}

class UploadDialogBody extends StatefulWidget {
  final String attachpath;
  final List<String> attachFiles;
  final bool showAttachLink;
  const UploadDialogBody({super.key, required this.attachpath, required this.attachFiles, required this.showAttachLink});

  @override
  State<UploadDialogBody> createState() => _UploadDialogBodyState();
}

class _UploadDialogBodyState extends State<UploadDialogBody> {
  // List<UploadFileStatus> filenames = [UploadFileStatus(name: "haha.jpg", status: "ok")];
  List<UploadFileStatus> filenames = [];
  int count = 0;

  @override
  void initState() {
    super.initState();
    count = widget.attachFiles.length;
    for (var element in widget.attachFiles) {
      filenames.add(UploadFileStatus(name: element, status: 'ok'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dSize = MediaQuery.of(context).size;
    final dWidth = dSize.width;
    final dHeight = dSize.height;
    return SizedBox(
      width: min(260, dWidth*0.8),
      height: min(300, dHeight*0.8),
      child: Column(
        children: [
          TextButton(
            onPressed: () {
              checkAndRequestStoragePermission()
              .then((couldDoIt) {
                if (!couldDoIt) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("没有文件权限"), duration: Duration(milliseconds: 1000),),
                    );
                  }
                  return;
                }
                FilePicker.platform.pickFiles()
                .then((res) {
                  if (res == null) { return; }
                  if (res.count == 0) { return; }
                  for (var f in res.files) {
                    if (f.path == null) { continue; }
                    bool hasIt = false;
                    for (var fn in filenames) {
                      if (f.name == fn.name) {
                        hasIt = true;
                        break;
                      }
                    }
                    if (hasIt) { continue; }
                    setState(() {
                      filenames.add(UploadFileStatus(name: f.name, status: "..."));
                    });
                    bdwmUpload(widget.attachpath, f.path!)
                    .then((uploadRes) {
                      if (uploadRes.success == true) {
                        debugPrint(uploadRes.name);
                        debugPrint(uploadRes.url);
                        if (widget.showAttachLink) {
                          if (context.mounted) {
                            showComplexInformDialog(context, "附件链接", SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(uploadRes.url ?? "未知"),
                                ],
                              ),
                            ));
                          }
                        }
                        bool hasIt = false;
                        for (var fn in filenames) {
                          if (fn.name == f.name) {
                            fn.name = uploadRes.name!;
                            fn.status = 'ok';
                            hasIt = true;
                            break;
                          }
                        }
                        if (hasIt) {
                          setState(() {
                            count = count + 1;
                            filenames = filenames;
                          });
                        } else {
                          setState(() {
                            count = count + 1;
                            filenames.add(UploadFileStatus(name: uploadRes.name!, status: "ok"));
                          });
                        }
                      } else {
                        setState(() {
                          filenames.removeWhere((element) => element.name == f.name);
                        });
                      }
                    });
                  }
                });
              });
            },
            child: const Text("选取上传文件"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filenames.length,
              itemBuilder: (context, index) {
                var e = filenames[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(e.name),
                    ),
                    IconButton(
                      onPressed: e.status == "ok" ? () {
                        bdwmDeleteUpload(widget.attachpath, e.name)
                        .then((res) {
                          if (res.success == false) { return; }
                          setState(() {
                            count = count - 1;
                            filenames.removeWhere((element) => element.name == e.name);
                          });
                        });
                      } : null,
                      icon: e.status == 'ok'
                        ? Icon(Icons.delete, color: bdwmPrimaryColor,)
                        : Icon(Icons.circle_outlined, color: bdwmPrimaryColor,),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showUploadDialog(BuildContext context, String attachpath, List<String> attachFiles, {bool showAttachLink=false}) {
  var key = GlobalKey<_UploadDialogBodyState>();
  return showAlertDialog(context, "管理附件", UploadDialogBody(key: key, attachpath: attachpath, attachFiles: attachFiles, showAttachLink: showAttachLink,),
    barrierDismissible: false,
    actions1: TextButton(
      onPressed: () {
        if (key.currentState == null) { return; }
        var count = key.currentState!.count;
        List<String> files = key.currentState!.filenames.map((e) => e.name).toList();
        Navigator.of(context).pop(jsonEncode({
          'count': count,
          'files': files,
        }));
      },
      child: const Text("确认"),
    ),
  );
}