import 'package:flutter/material.dart';
// import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import "../html_parser/user_parser.dart";
import "../bdwm/req.dart";
import "../globalvars.dart";
import "../bdwm/logout.dart";

class UserInfoPage extends StatefulWidget {
  final String uid;
  UserInfoPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  UserProfile user = UserProfile();

  Future<UserProfile> getData() async {
    var resp = await bdwmClient.get("$v2Host/user.php?uid=${widget.uid}", headers: genHeaders());
    return parseUser(resp.body);
  }

  void updateTitle() {
    // if (widget.changeTitle != null) {
    //   if ((globalUInfo.uid == widget.uid) && (globalUInfo.login == true)) {
    //     widget.changeTitle!("我");
    //   } else if (widget.uid == "22776") {
    //     widget.changeTitle!("作者");
    //   } else {
    //     widget.changeTitle!("用户");
    //   }
    // }
  }

  @override
  void initState() {
    super.initState();
    // debugPrint("init user");
    getData().then((value) {
      // getExampleTop100();
      setState(() {
        user = value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant UserInfoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // debugPrint("old ${oldWidget.uid} ${oldWidget.changeTitle.hashCode} ${oldWidget.pageCallBack.hashCode}");
    // debugPrint("new ${widget.uid} ${widget.changeTitle.hashCode} ${widget.pageCallBack.hashCode}");
    // updateTitle();
    getData().then((value) {
      // getExampleTop100();
      if (!mounted) {
        return;
      }
      setState(() {
        user = value;
      });
    });
  }

  Widget _oneLineItem(String label, String value, {Icon? icon}) {
    return Card(
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          children: [
            if (icon != null)
              ...[icon],
            Text(label),
            const Text("："),
            Text(value),
          ],
        ),
      ),
    );
  }

  Widget _multiLineItem(String label, String value, {Icon? icon}) {
    return Card(
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  ...[icon],
                Text("$label："),
              ],
            ),
            if (value.isNotEmpty)
              ...[Text(value)],
          ],
        ),
      ),
    );
  }

  HtmlWidget renderHtml(String htmlStr) {
    return HtmlWidget(
      htmlStr.replaceAll("<br/>", ""),
      onErrorBuilder: (context, element, error) => Text('$element error: $error'),
      customStylesBuilder: (element) {
        if (element.localName == 'p') {
          return {'margin-top': '0px', 'margin-bottom': '0px'};
        }
        return null;
      },
    );
  }

  Widget _multiHtmlLineItem(String label, var value, {Icon? icon}) {
    return Card(
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  ...[icon],
                Text("$label："),
              ],
            ),
            value,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var genderIcon = user.gender.contains("保密") ? const Icon(Icons.lock) :
      user.gender == "男" ? const Icon(Icons.man) : const Icon(Icons.woman);
    var subtitle1 = user.personalCollection.link != null ? "个人文集 ${user.personalCollection.text}" : user.personalCollection.text;
    var subtitle2 = user.duty ?? '本站职务：无';
    return Container(
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(user.avatarLink),
              ),
              title: Text("${user.bbsID} (${user.nickName}) ${user.status}"),
              subtitle: Text(
                // TODO: personalCollectionLink
                "$subtitle1\n$subtitle2",
              ),
              isThreeLine: true,
              trailing: SizedBox(
                width: 48,
                child: (globalUInfo.login && (globalUInfo.uid == widget.uid)) ? IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    bdwmLogout().then((value) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    });
                  },
                ) : null,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _oneLineItem("性别", user.gender, icon: genderIcon),
                _oneLineItem("星座", user.constellation),
                _oneLineItem("生命力", user.value, icon: const Icon(Icons.favorite_border)),
                _oneLineItem("上站次数", user.countLogin),
                _oneLineItem("发帖数", user.countPost),
                _oneLineItem("积分", user.score),
                _oneLineItem("等级", user.rankName),
                _oneLineItem("原创分", user.rating),
                _oneLineItem("最近上站时间", user.recentLogin),
                _oneLineItem("最近离站时间", user.recentLogout),
                if (user.timeReg != null)
                  ...[_oneLineItem("注册时间", user.timeReg!)],
                if (user.timeOnline != null)
                  ...[_oneLineItem("在线总时长", user.timeOnline!)],
                // _multiLineItem("个人说明", user.signature, icon: const Icon(Icons.description)),
                // _multiHtmlLineItem("个人说明", Html(data: user.signature), icon: const Icon(Icons.description)),
                _multiHtmlLineItem("个人说明", renderHtml(user.signatureHtml), icon: const Icon(Icons.description)),
                if (user.duty != null && user.dutyBoards != null)
                  ...[_multiLineItem("担任版务", user.dutyBoards!.join("\n"))],
              ],
            )
          ),
        ],
      ),
    );
  }
}
