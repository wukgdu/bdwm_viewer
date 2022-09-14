import 'package:flutter/material.dart';

import '../views/drawer.dart';
import '../views/html_widget.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({Key? key}) : super(key: key);
  final _titleStyle = const TextStyle(fontSize: 22, fontWeight: FontWeight.normal);
  final _contentStyle = const TextStyle(fontSize: 18);
  final String innerLink = "https://bbs.pku.edu.cn/v2/collection-read.php?path=groups%2FGROUP_0%2FPersonalCorpus%2FO%2Fonepiece%2FD93F86C79%2FA862DAFBA";
  final String curVersion = "1.3.2";

  Widget oneItem(String header, String content, {bool? isLink=false}) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(header, style: _titleStyle,),
            if (isLink!=true)
              SelectableText(content, style: _contentStyle,)
            else
              HtmlComponent('<a href=$content>$content</a>'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 5),
      appBar: AppBar(
        title: const Text("关于"),
      ),
      body: ListView(
        children: [
          oneItem("北大未名BBS", "https://bbs.pku.edu.cn"),
          oneItem("关于此应用", "北大未名BBS第三方安卓客户端"),
          oneItem("开发", "onepiece@bdwm"),
          oneItem("当前版本", curVersion),
          oneItem("站内更新", innerLink, isLink: true),
          oneItem("开源", "https://github.com/wukgdu/bdwm_viewer"),
          oneItem("下载", "https://github.com/wukgdu/bdwm_viewer/releases"),
        ],
      ),
    );
  }
}