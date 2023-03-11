import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:async/async.dart';
import 'package:url_launcher/url_launcher.dart';

import "../html_parser/user_parser.dart";
import "../bdwm/req.dart";
import "../bdwm/search.dart";
// import "../bdwm/settings.dart";
import "../globalvars.dart";
import '../bdwm/users.dart';
import "../bdwm/logout.dart";
import "./utils.dart";
import "./constants.dart";
import "../pages/detail_image.dart";
import './html_widget.dart';
import '../html_parser/modify_profile_parser.dart';
import '../router.dart' show nv2Push, nv2PushAndRemoveAll;

class UserOperationCombinedComponent extends StatefulWidget {
  final UserProfile user;
  final String uid;
  const UserOperationCombinedComponent({required this.user, required this.uid, super.key});

  @override
  State<UserOperationCombinedComponent> createState() => _UserOperationCombinedComponentState();
}

class _UserOperationCombinedComponentState extends State<UserOperationCombinedComponent> {
  bool useradd = false;
  bool userreject = false;

  @override
  void initState() {
    super.initState();
    useradd = widget.user.useradd;
    userreject = widget.user.userreject;
  }

  @override
  void didUpdateWidget(covariant UserOperationCombinedComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    useradd = widget.user.useradd;
    userreject = widget.user.userreject;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          UserOperationComponent(exist: useradd, uid: widget.uid, userName: widget.user.bbsID, mode: "add",
            callBack: () {
              setState(() {
                useradd = !useradd;
              });
            },
          ),
          UserOperationComponent(exist: userreject, uid: widget.uid, userName: widget.user.bbsID, mode: "reject",
            callBack: () {
              if (userreject == false) {
                setState(() {
                  userreject = true;
                  useradd = false;
                });
              } else {
                setState(() {
                  userreject = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class UserOperationComponent extends StatefulWidget {
  final String uid;
  final bool exist;
  final String userName;
  final String mode;
  final Function? callBack;
  const UserOperationComponent({super.key, required this.exist, required this.uid, required this.userName, required this.mode, this.callBack});

  @override
  State<UserOperationComponent> createState() => _UserOperationComponentState();
}

class _UserOperationComponentState extends State<UserOperationComponent> {
  bool userexist = false;

  @override
  void initState() {
    super.initState();
    userexist = widget.exist;
  }

  @override
  void didUpdateWidget(covariant UserOperationComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    userexist = widget.exist;
  }

  @override
  Widget build(BuildContext context) {
    String actionText = widget.mode == "reject" ? "拉黑" : "关注";
    String shortText = widget.mode == "reject"
      ? userexist ? "变白" : "拉黑"
      : userexist ? "取关" : "关注";
    return GestureDetector(
      child: Text(shortText, style: TextStyle(color: bdwmPrimaryColor),),
      onTap: () {
        var uid = widget.uid;
        var username = widget.userName;
        if (username.isEmpty) { return; }
        var action = "add";
        if (userexist) {
          action = "delete";
        }
        String? mode = widget.mode == "reject" ? "reject" : null;
        var desc = "";
        bdwmUsers(uid, action, desc, mode: mode).then((value) {
          var title = "";
          var content = "成功$actionText";
          if (userexist) {
            content = "成功取消$actionText";
          }
          if (!value.success) {
            if (value.error == -1) {
              content = networkErrorText;
            } else {
              content = "失败啦，请稍候再试";
            }
          }
          showInformDialog(context, title, content).then((dialogValue) {
            if (!value.success) { return; }
            if (widget.callBack != null) {
              widget.callBack!();
            } else {
              setState(() {
                userexist = !userexist;
              });
            }
          });
        });
      },
    );
  }
}

class ShowIpComponent extends StatefulWidget {
  final String userName;
  const ShowIpComponent({required this.userName, super.key});

  @override
  State<ShowIpComponent> createState() => _ShowIpComponentState();
}

class _ShowIpComponentState extends State<ShowIpComponent> {
  bool showIp = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: [
          const Text("IP："),
          if (showIp) ...[
            widget.userName.toLowerCase() == "onepiece"
            ? const Text("当然不能查我啦")
            : FutureBuilder(
              future: bdwmUserInfoSearch([widget.userName]),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  // return const Center(child: CircularProgressIndicator());
                  return const Text("查询中");
                }
                if (snapshot.hasError) {
                  return Text("错误：${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("错误：未获取数据");
                }
                var userRes = snapshot.data as UserInfoRes;
                if (userRes.success == false) {
                  return const Text("查询失败");
                }
                if (userRes.users.isEmpty) {
                  return const Text("查询失败");
                }
                if (userRes.users[0] is bool) {
                  return const Text("查询失败");
                }
                String ipStr = "";
                try {
                  Map jsonObject = jsonDecode(userRes.jsonStr);
                  Map result = jsonObject['result'][0];
                  int ipInt = result['ip'];
                  String ipHexStr = ipInt.toRadixString(16).padLeft(8, '0');
                  int ip1 = int.parse("0x${ipHexStr.substring(0, 2)}");
                  int ip2 = int.parse("0x${ipHexStr.substring(2, 4)}");
                  int ip3 = int.parse("0x${ipHexStr.substring(4, 6)}");
                  int ip4 = int.parse("0x${ipHexStr.substring(6, 8)}");
                  if (globalUInfo.uid == "22776" && globalUInfo.login == true && globalUInfo.username.toLowerCase() == "onepiece") {
                    ipStr = "$ip4.$ip3.$ip2.$ip1";
                  } else {
                    ipStr = "$ip4.$ip3.$ip2.*";
                  }
                } catch (_) {
                  ipStr = "查询失败";
                }
                return SelectionArea(child: Text(ipStr));
              },
            ),
          ],
          TextButton(
            onPressed: () {
              setState(() {
                showIp = !showIp;
              });
            },
            child: Text(showIp ? "隐藏" : "点击查看"),
          ),
        ],
      ),
    );
  }
}

class RankSelectComponent extends StatefulWidget {
  final String selected;
  final SelfProfileRankSysInfo selfProfileRankSysInfo;
  final Function(String newSelected)? updateFunc;
  const RankSelectComponent({super.key, required this.selected, required this.selfProfileRankSysInfo, this.updateFunc});

  @override
  State<RankSelectComponent> createState() => _RankSelectComponentState();
}

class _RankSelectComponentState extends State<RankSelectComponent> {
  List<DropdownMenuItem<String>> rankOptions = [];
  String selected = "";

  void update() {
    selected = widget.selected;
    rankOptions.clear();
    for (int i=0; i<widget.selfProfileRankSysInfo.values.length; i+=1) {
      rankOptions.add(DropdownMenuItem<String>(
        value: widget.selfProfileRankSysInfo.values[i],
        child: Text(widget.selfProfileRankSysInfo.names[i]),
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    update();
  }

  @override
  void didUpdateWidget(covariant RankSelectComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // update();
    selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      isDense: true,
      hint: const Text("等级系统"),
      icon: const Icon(Icons.arrow_drop_down),
      value: selected,
      items: rankOptions,
      style: Theme.of(context).textTheme.titleMedium,
      onChanged: (String? value) {
        if (value == null) { return; }
        if (widget.updateFunc != null) {
          widget.updateFunc!(value);
        } else {
          setState(() {
            selected = value;
          });
        }
      },
    );
  }
}

class RankSysComponent extends StatefulWidget {
  final String rankName;
  final String userName;
  const RankSysComponent({super.key, required this.rankName, required this.userName});

  @override
  State<RankSysComponent> createState() => _RankSysComponentState();
}

class _RankSysComponentState extends State<RankSysComponent> {
  CancelableOperation? getDataCancelable;
  SelfProfileInfo? selfProfileInfo;
  bool underEdit = false;
  final iconButtonStyle = IconButton.styleFrom(
    minimumSize: const Size(20, 20),
    padding: const EdgeInsets.all(4.0),
  );

  @override
  void initState() {
    super.initState();
    debugPrint("********** rankSys re init");
  }

  @override
  void didUpdateWidget(covariant RankSysComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!kDebugMode) {
      clearData();
    }
  }

  @override
  void dispose() {
    getDataCancelable?.cancel();
    super.dispose();
  }

  void clearData() {
    getDataCancelable = null;
    selfProfileInfo = null;
  }

  Widget genSizedIconButton({required void Function()? onPressed, required Icon icon}) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        splashRadius: 18,
        color: bdwmPrimaryColor,
        style: iconButtonStyle,
        // constraints: const BoxConstraints(),
        iconSize: 16,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }

  Future<SelfProfileInfo> getData() async {
    var resp = await bdwmClient.get("$v2Host/modify-profile.php", headers: genHeaders());
    if (resp == null) {
      return SelfProfileInfo.error(errorMessage: networkErrorText);
    }
    return parseSelfProfile(resp.body);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 40.0
        ),
        padding: const EdgeInsets.only(left: 10),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runAlignment: WrapAlignment.center,
          children: [
            const Text("等级："),
            SelectionArea(child: Text(widget.rankName)),
            if (!underEdit) ...[
              if ((globalUInfo.login == true) && (globalUInfo.username == widget.userName)) ...[
                genSizedIconButton(
                  onPressed: () {
                    setState(() {
                      underEdit = true;
                      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
                    });
                  },
                  icon: const Icon(Icons.edit),
                ),
              ],
              genSizedIconButton(
                onPressed: () {
                  var userFuturePageState = context.findAncestorStateOfType<_UserFuturePageState>();
                  if (userFuturePageState == null) { return; }
                  userFuturePageState.refresh();
                },
                icon: const Icon(Icons.refresh),
              ),
            ] else ...[
              FutureBuilder(
                future: getDataCancelable!.value,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(width: 60, child: LinearProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text("错误");
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Text("错误：未获取数据");
                  }
                  selfProfileInfo = snapshot.data as SelfProfileInfo;
                  if (selfProfileInfo!.errorMessage != null) {
                    clearData();
                    return const Text("获取失败");
                  }
                  var rankSysInfo = selfProfileInfo!.selfProfileRankSysInfo;
                  return RankSelectComponent(
                    selected: rankSysInfo.selected,
                    selfProfileRankSysInfo: rankSysInfo,
                    updateFunc:(newSelected) {
                      setState(() {
                        rankSysInfo.selected = newSelected;
                      });
                    },
                  );
                },
              ),
              genSizedIconButton(
                onPressed: () async {
                  if (selfProfileInfo == null) { return; }
                  nv2Push(context, '/modifyProfile', arguments: {
                    'selfProfileInfo': selfProfileInfo,
                  });
                  setState(() {
                    underEdit = false;
                    clearData();
                  });
                },
                icon: const Icon(Icons.check),
              ),
              genSizedIconButton(
                onPressed: () {
                  setState(() {
                    underEdit = false;
                    clearData();
                  });
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class UserInfoPage extends StatefulWidget {
  final String uid;
  final UserProfile user;
  const UserInfoPage({Key? key, required this.uid, required this.user}) : super(key: key);

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  late UserProfile user;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UserInfoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    user = widget.user;
  }

  Widget _oneLineItem(String label, String value, {Icon? icon, bool selectable=false}) {
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
            selectable ? SelectionArea(child: Text(value)) : Text(value),
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
                    nv2Push(context, '/board', arguments: {
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

  // Widget _multiLineItem(String label, String value, {Icon? icon}) {
  //   return Card(
  //     child: Container(
  //       padding: const EdgeInsets.only(left: 10),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               if (icon != null)
  //                 ...[icon],
  //               Text("$label："),
  //             ],
  //           ),
  //           if (value.isNotEmpty) ...[
  //             Text(value),
  //           ]
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
    var subtitle2 = user.duty ?? '本站职务：无';
    if (user.errorMessage != null) {
      return Center(child: Text(user.errorMessage!));
    }
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: GestureDetector(
              onTap: () {
                gotoDetailImage(context: context, link: user.avatarLink, imgData: null, name: "${user.bbsID}.jpg");
              },
              child: Stack(
                alignment: const Alignment(0, 0),
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: genSimpleCachedImageProvider(user.avatarLink),
                  ),
                  if (user.avatarFrameLink.isNotEmpty) ...[
                    SimpleCachedImage(
                      imgLink: user.avatarFrameLink,
                    ),
                  ],
                ],
              ),
            ),
            title: SelectionArea(
              child: Text.rich(TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: user.bbsID, style: serifFont),
                  const TextSpan(text: " ("),
                  // WidgetSpan(child: HtmlComponent(user.nickNameHtml),),
                  user.vipIdentity != -1
                  ? TextSpan(text: user.nickName, style: TextStyle(
                    color: getVipColor(user.vipIdentity, defaultColor: null),
                  ))
                  : html2TextSpan(user.nickNameHtml),
                  const TextSpan(text: ") "),
                  if (user.vipIdentity != -1) ...[
                    WidgetSpan(child: genVipLabel(user.vipIdentity)),
                  ],
                  TextSpan(
                    text: user.status,
                    style: TextStyle(color: user.status.contains("在线") ? onlineColor : Colors.grey),
                  ),
                ],
              ),
            ),),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  if (user.personalCollection.link != null
                    && user.personalCollection.link!.isNotEmpty
                    && !user.personalCollection.link!.contains("collection-application.php")) ...[
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          nv2Push(context, '/collection', arguments: {
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
                  ] else if (user.personalCollection.link != null && user.personalCollection.link!.contains("collection-application.php")) ...[
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          showConfirmDialog(context, "使用默认浏览器打开链接?", user.personalCollection.link!).then((value) {
                            if (value == null) {
                              return;
                            }
                            if (value == "yes") {
                              var parsedUrl = Uri.parse(user.personalCollection.link!);
                              // await canLaunchUrl(parsedUrl)
                              launchUrl(parsedUrl, mode: LaunchMode.externalApplication).then((result) {
                                if (result == true) { return; }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("打开链接失败"), duration: Duration(milliseconds: 600),),
                                );
                              });
                            }
                          });
                        },
                        child: Text(user.personalCollection.text, style: textLinkStyle),
                      ),
                    )
                  ] else ...[
                    TextSpan(text: user.personalCollection.text),
                  ],
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
                      nv2PushAndRemoveAll(context, '/login');
                    });
                  },
                ),
              )
              : UserOperationCombinedComponent(user: user, uid: widget.uid),
            ),
          ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            children: [
              _oneLineItem("UID", widget.uid, selectable: true),
              _oneLineItem("性别", user.gender, icon: genderIcon),
              _oneLineItem("星座", user.constellation),
              _oneLineItem("生命力", user.value),
              _oneLineItem("上站次数", user.countLogin),
              _oneLineItem("发帖数", user.countPost),
              _oneLineItem("积分", user.score),
              RankSysComponent(rankName: user.rankName, userName: user.bbsID,),
              _oneLineItem("原创分", user.rating),
              _oneLineItem("最近上站时间", user.recentLogin),
              _oneLineItem("最近离站时间", user.recentLogout),
              if (user.timeReg != null)
                _oneLineItem("注册时间", user.timeReg!),
              if (user.timeOnline != null)
                _oneLineItem("在线总时长", user.timeOnline!),
              Card(child: ShowIpComponent(userName: user.bbsID),),
              // _multiLineItem("个人说明", user.signature, icon: const Icon(Icons.description)),
              // _multiHtmlLineItem("个人说明", Html(data: user.signature), icon: const Icon(Icons.description)),
              _multiHtmlLineItem("个人说明", HtmlComponent(user.signatureHtml), icon: const Icon(Icons.description)),
              if (user.duty != null && user.dutyBoards != null) ...[
                _multiLineItemForAdmin("担任版务", user.dutyBoards, user.dutyBoardLinks,)
              ],
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
                  nv2Push(context, '/messagePerson', arguments: user.bbsID);
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
                  nv2Push(context, "/mailNew", arguments: {
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

class UserFuturePage extends StatefulWidget {
  final String uid;
  const UserFuturePage({super.key, required this.uid});

  @override
  State<UserFuturePage> createState() => _UserFuturePageState();
}

class _UserFuturePageState extends State<UserFuturePage> {
  late CancelableOperation getDataCancelable;

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
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  void refresh() {
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("错误：${snapshot.error}"),);
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("错误：未获取数据"),);
        }
        UserProfile userInfo = snapshot.data as UserProfile;
        return UserInfoPage(uid: widget.uid, user: userInfo);
      },
    );
  }
}
