import 'package:flutter/material.dart';

import '../views/drawer.dart';
import '../views/html_widget.dart';
import '../views/constants.dart' show textLinkStyle;
import '../check_update.dart' show innerLinkForBBS, curVersionForBBS;
import '../router.dart' show nv2Push;

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);
  final _titleStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.normal);
  final _contentStyle = const TextStyle(fontSize: 16);

  Widget addAuthor(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("开发", style: _titleStyle,),
          GestureDetector(
            onTap: () {
              nv2Push(context, '/user', arguments: "22776");
            },
            child: Text("onepiece@bdwm", style: _contentStyle.merge(textLinkStyle)),
          )
        ],
      ),
    );
  }
  Widget oneItem(String header, String content, {bool? isLink=false, String? addLink}) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 7),
      appBar: AppBar(
        title: const Text("关于"),
      ),
      body: ListView(
        children: [
          oneItem("北大未名BBS", "https://bbs.pku.edu.cn", isLink: true),
          const Divider(),
          oneItem("关于此应用", "北大未名BBS第三方安卓客户端"),
          const Divider(),
          // oneItem("开发", "onepiece@bdwm"),
          addAuthor(context),
          const Divider(),
          oneItem("当前版本", curVersionForBBS),
          const Divider(),
          oneItem("站内更新", innerLinkForBBS, isLink: true),
          const Divider(),
          oneItem("开源", "https://github.com/wukgdu/bdwm_viewer", isLink: true),
          const Divider(),
          oneItem("下载", "https://github.com/wukgdu/bdwm_viewer/releases", isLink: true),
        ],
      ),
    );
  }
}