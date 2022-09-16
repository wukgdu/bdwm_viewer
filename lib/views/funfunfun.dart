import 'package:flutter/material.dart';

import '../globalvars.dart';
import "./utils.dart";

class FunFunFunPage extends StatefulWidget {
  const FunFunFunPage({super.key});

  @override
  State<FunFunFunPage> createState() => _FunFunFunPageState();
}

class _FunFunFunPageState extends State<FunFunFunPage> {
  bool showBigTen = false;
  Widget? bigTenWidget;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: ListTile(
            onTap: () {
              showAlertDialog(context, "十大拍照", const Text("将要读取当前十大每个帖子首页"),
                actions1: TextButton(
                  onPressed: () { Navigator.of(context).pop(); },
                  child: const Text("不了"),
                ),
                actions2: TextButton(
                  onPressed: () { Navigator.of(context).pop("ok"); },
                  child: const Text("确认"),
                ),
              ).then((value) {
                if (value == null) { return; }
                if (value == "ok") {
                  setState(() {
                    showBigTen = true;
                  });
                }
              });
            },
            title: const Text("十大拍照（term）"),
            trailing: const Icon(Icons.arrow_right),
          ),
        ),
        if (showBigTen)
          Card(child: bigTenWidget ?? const Center(child: Text("生成十大拍照失败"))),
      ],
    );
  }
}