import 'dart:math' show min;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// import '../globalvars.dart';
import '../utils.dart' show checkAndRequestPermission;
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
  const UploadDialogBody({super.key, required this.attachpath, required this.attachFiles});

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
              checkAndRequestPermission(Permission.storage)
              .then((couldDoIt) {
                if (!couldDoIt) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("没有文件权限"), duration: Duration(milliseconds: 1000),),
                  );
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
            child: const Text("选取文件"),
          ),
          Expanded(
            child: ListView(
              children: filenames.map((e) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(e.name),
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
                        ? const Icon(Icons.delete, color: bdwmPrimaryColor,)
                        : const Icon(Icons.circle_outlined, color: bdwmPrimaryColor,),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showUploadDialog(BuildContext context, String attachpath, List<String> attachFiles) {
  var key = GlobalKey<_UploadDialogBodyState>();
  return showAlertDialog(context, "管理附件", UploadDialogBody(key: key, attachpath: attachpath, attachFiles: attachFiles),
    actions1: TextButton(
      onPressed: () {
        Navigator.of(context).pop(key.currentState!.count.toString());
      },
      child: const Text("确认"),
    ),
  );
}