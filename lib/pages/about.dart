import 'package:flutter/material.dart';

import '../views/drawer.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({Key? key}) : super(key: key);
  final _titleStyle = const TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
  final _contentStyle = const TextStyle(fontSize: 18);

  Widget oneItem(String header, String content) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(header, style: _titleStyle,),
            SelectableText(content, style: _contentStyle,),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 2),
      appBar: AppBar(
        title: const Text("关于"),
      ),
      body: ListView(
        children: [
          oneItem("北大未名BBS", "https://bbs.pku.edu.cn"),
          oneItem("App 开发", "onepiece@bdwm"),
          oneItem("开源", "https://github.com/wukgdu/bdwm_viewer"),
          oneItem("下载", "https://github.com/wukgdu/bdwm_viewer/releases"),
        ],
      ),
    );
  }
}