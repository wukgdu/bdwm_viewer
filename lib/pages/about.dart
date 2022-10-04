import 'package:flutter/material.dart';

import '../views/drawer.dart';
import '../views/html_widget.dart';
import '../views/constants.dart' show bdwmPrimaryColor;
import '../check_update.dart' show innerLinkForBBS, curVersionForBBS;
import '../router.dart' show nv2Push;

class AboutApp extends StatelessWidget {
  const AboutApp({Key? key}) : super(key: key);
  final _titleStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.normal);
  final _contentStyle = const TextStyle(fontSize: 16);

  Widget addAuthor(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("开发", style: _titleStyle,),
            GestureDetector(
              onTap: () {
                nv2Push(context, '/user', arguments: "22776");
              },
              child: Text("onepiece@bdwm", style: _contentStyle.merge(const TextStyle(color: bdwmPrimaryColor))),
            )
          ],
        ),
      ),
    );
  }
  Widget oneItem(String header, String content, {bool? isLink=false, String? addLink}) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(header, style: _titleStyle,),
            if (isLink!=true)
              SelectableText(content, style: _contentStyle,)
            else if (isLink==true)
              HtmlComponent('<a href=$content>$content</a>', ts: _contentStyle,)
            else if (addLink!=null)
              HtmlComponent('<a href=$addLink>$content</a>', ts: _contentStyle,),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 6),
      appBar: AppBar(
        title: const Text("关于"),
      ),
      body: ListView(
        children: [
          oneItem("北大未名BBS", "https://bbs.pku.edu.cn", isLink: true),
          oneItem("关于此应用", "北大未名BBS第三方安卓客户端"),
          // oneItem("开发", "onepiece@bdwm"),
          addAuthor(context),
          oneItem("当前版本", curVersionForBBS),
          oneItem("站内更新", innerLinkForBBS, isLink: true),
          oneItem("开源", "https://github.com/wukgdu/bdwm_viewer", isLink: true),
          oneItem("下载", "https://github.com/wukgdu/bdwm_viewer/releases", isLink: true),
        ],
      ),
    );
  }
}