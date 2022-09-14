import 'package:flutter/material.dart';
// import 'package:flutter_html/flutter_html.dart';

import "../html_parser/user_parser.dart";
import "../bdwm/req.dart";
import "../globalvars.dart";
import '../bdwm/users.dart';
import "../bdwm/logout.dart";
import "./utils.dart";
import "./constants.dart";
import "../pages/detail_image.dart";
import './html_widget.dart';

class UserOperationComponent extends StatefulWidget {
  final String uid;
  final bool exist;
  final String userName;
  final String mode;
  const UserOperationComponent({super.key, required this.exist, required this.uid, required this.userName, required this.mode});

  @override
  State<UserOperationComponent> createState() => _UserOperationComponentState();
}

class _UserOperationComponentState extends State<UserOperationComponent> {
  bool useradd = false;

  @override
  void initState() {
    super.initState();
    useradd = widget.exist;
  }

  @override
  void didUpdateWidget(covariant UserOperationComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    useradd = widget.exist;
  }
  
  @override
  Widget build(BuildContext context) {
    String actionText = widget.mode == "reject" ? "拉黑" : "关注";
    return GestureDetector(
      child: Text(useradd ? "取消$actionText" : actionText, style: const TextStyle(color: bdwmPrimaryColor),),
      onTap: () {
        var uid = widget.uid;
        var username = widget.userName;
        if (username.isEmpty) { return; }
        var action = "add";
        if (useradd) {
          action = "delete";
        }
        String? mode = widget.mode == "reject" ? "reject" : null;
        var desc = "";
        bdwmUsers(uid, action, desc, mode: mode).then((value) {
          var title = "";
          var content = "成功$actionText";
          if (useradd) {
            content = "成功取消$actionText";
          }
          if (!value.success) {
            if (value.error == -1) {
              content = networkErrorText;
            } else {
              content = "失败啦，请稍候再试";
            }
          }
          showAlertDialog(context, title, Text(content),
            actions1: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("知道了"),
            ),
          ).then((dialogValue) {
            setState(() {
              useradd = !useradd;
            });
          });
        });
      },
    );
  }
}

class UserInfoPage extends StatefulWidget {
  final String uid;
  const UserInfoPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  UserProfile user = UserProfile();

  Future<UserProfile> getData() async {
    var resp = await bdwmClient.get("$v2Host/user.php?uid=${widget.uid}", headers: genHeaders());
    if (resp == null) {
      return UserProfile.error(errorMessage: networkErrorText);
    }
    return parseUser(resp.body);
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

  Widget _multiLineItemForAdmin(String label, List<String>? values, List<String>? bids, {Icon? icon}) {
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
            if (values!=null && bids != null)
              ...values.asMap().entries.map((pair) {
                int idx = pair.key;
                String boardName = pair.value;
                String bidLink = bids[idx];
                String bid = bidLink.split("=").last;
                return TextButton(
                  child: Text(boardName, style: textLinkStyle,),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/board', arguments: {
                      'boardName': boardName.split('(').first,
                      'bid': bid,
                    });
                  },
                );
              })
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
    debugPrint("** user rebuild");
    var genderIcon = user.gender.contains("保密") ? const Icon(Icons.lock) :
      user.gender == "男" ? const Icon(Icons.man) : const Icon(Icons.woman);
    var subtitle1 = user.personalCollection.link != null ? "个人文集 ${user.personalCollection.text}" : user.personalCollection.text;
    var subtitle2 = user.duty ?? '本站职务：无';
    if (user.errorMessage != null) {
      return Center(child: Text(user.errorMessage!));
    }
    return Column(
      children: [
        Card(
          child: ListTile(
            // leading: CircleAvatar(
            //   backgroundColor: Colors.white,
            //   backgroundImage: NetworkImage(user.avatarLink),
            // ),
            leading: GestureDetector(
              onTap: () {
                gotoDetailImage(context: context, link: user.avatarLink, imgData: null, name: "${user.bbsID}.jpg");
              },
              child: Stack(
                alignment: const Alignment(0, 0),
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(user.avatarLink),
                  ),
                  if (user.avatarFrameLink.isNotEmpty)
                    Image.network(
                      user.avatarFrameLink,
                    ),
                ],
              ),
            ),
            title: SelectableText.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: user.bbsID, style: serifFont),
                  const TextSpan(text: " ("),
                  // WidgetSpan(child: HtmlComponent(user.nickNameHtml),),
                  html2TextSpan(user.nickNameHtml),
                  const TextSpan(text: ") "),
                  TextSpan(text: user.status),
                ],
              ),
            ),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  if (user.personalCollection.link != null && user.personalCollection.link!.isNotEmpty)
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/collection', arguments: {
                            'link': user.personalCollection.link,
                            'title': user.bbsID,
                          });
                        },
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: "个人文集 "),
                              TextSpan(text: user.personalCollection.text, style: textLinkStyle),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    TextSpan(text: subtitle1),
                  const TextSpan(text: "\n"),
                  TextSpan(text: subtitle2),
                ]
              ),
            ),
            isThreeLine: true,
            trailing: (globalUInfo.login && (globalUInfo.uid == widget.uid))
              ? SizedBox(
                width: 48,
                child:  IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    bdwmLogout().then((value) {
                      if (value == false) {
                        showNetWorkDialog(context);
                      }
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    });
                  },
                ),
              )
              : Container(
                alignment: Alignment.center,
                width: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    UserOperationComponent(exist: user.useradd, uid: widget.uid, userName: user.bbsID, mode: "add",),
                    UserOperationComponent(exist: false, uid: widget.uid, userName: user.bbsID, mode: "reject",),
                  ],
                ),
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
                // ...[_multiLineItem("担任版务", user.dutyBoards!.join("\n"))],
                ...[_multiLineItemForAdmin("担任版务", user.dutyBoards, user.dutyBoardLinks,)],
            ],
          )
        ),
        Container(
          padding: const EdgeInsets.only(top: 5, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/messagePerson', arguments: user.bbsID);
                },
                child: Row(
                  children: const [
                    Icon(Icons.message_outlined, size: 14,),
                    Text("发消息"),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed("/mailNew", arguments: {
                    'receiver': user.bbsID,
                  });
                },
                child: Row(
                  children: const [
                    Icon(Icons.mail_outline, size: 14),
                    Text("发站内信"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
