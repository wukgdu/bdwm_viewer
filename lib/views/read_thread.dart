import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:extended_image/extended_image.dart';

import '../bdwm/vote.dart';
import '../bdwm/posts.dart';
import '../bdwm/collection.dart';
import '../bdwm/forward.dart';
import './collection.dart';
import './utils.dart';
import '../utils.dart' show clearAllExtendedImageCache;
import './constants.dart';
import '../html_parser/read_thread_parser.dart';
// import '../globalvars.dart';
import '../pages/detail_image.dart';
import './html_widget.dart';

class OperateComponent extends StatefulWidget {
  final String bid;
  final String boardName;
  final String threadid;
  final String postid;
  final String uid;
  final Function refreshCallBack;
  final OnePostInfo onePostInfo;
  const OperateComponent({
    super.key,
    required this.bid, required this.threadid, required this.postid, required this.uid,
    required this.refreshCallBack, required this.boardName, required this.onePostInfo,
  });

  @override
  State<OperateComponent> createState() => _OperateComponentState();
}

class _OperateComponentState extends State<OperateComponent> {
  var canReplyNotifier = ValueNotifier<bool>(false);
  static const textButtonStyle = ButtonStyle(
    minimumSize: MaterialStatePropertyAll(Size(50, 20)),
    // textStyle: MaterialStatePropertyAll(TextStyle(fontSize: 12)),
  );
  @override
  void initState() {
    super.initState();
    canReplyNotifier.value = widget.onePostInfo.canReply;
  }
  @override
  void dispose() {
    canReplyNotifier.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Wrap(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      // alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ValueListenableBuilder(
          valueListenable: canReplyNotifier,
          builder: (context, value, child) {
            var canReply = value as bool;
            return TextButton(
              style: textButtonStyle,
              onPressed: !canReply ? null
                : () {
                  Navigator.of(context).pushNamed('/post', arguments: {
                    'bid': widget.bid,
                    'boardName': "",
                    'parentid': widget.postid,
                  }).then((value) {
                    if (value == true) {
                      widget.refreshCallBack();
                    }
                  });
                },
              child: Text("回帖", style: TextStyle(color: !canReply ? Colors.grey : null),),
            );
          },
        ),
        TextButton(
          style: textButtonStyle,
          onPressed: () {
            showTextDialog(context, "转载到的版面")
            .then((value) {
              if (value == null || value.isEmpty) {
                return;
              }
              bdwmForwrad("post", "post", widget.bid, widget.postid, value)
              .then((res) {
                var title = "转载";
                var content = "成功";
                if (!res.success) {
                  if (res.error == -1) {
                    content = res.desc!;
                  } else {
                    content = "该版面不存在，或需要特殊权限";
                  }
                }
                showAlertDialog(context, title, Text(content),
                  actions1: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("知道了"),
                  ),
                );
              });
            },);
          },
          child: const Text("转载"),
        ),
        // if (globalUInfo.uid == widget.uid && globalUInfo.login == true)
        if (widget.onePostInfo.canModify)
          TextButton(
            style: textButtonStyle,
            onPressed: () {
              Navigator.of(context).pushNamed('/post', arguments: {
                'bid': widget.bid,
                'boardName': "",
                'postid': widget.postid,
              }).then((value) {
                if (value == true) {
                  widget.refreshCallBack();
                }
              });
            },
            child: const Text("修改"),
          ),
        // if (globalUInfo.uid == widget.uid && globalUInfo.login == true)
        if (widget.onePostInfo.canDelete)
          TextButton(
            style: textButtonStyle,
            onPressed: () {
              bdwmDeletePost(bid: widget.bid, postid: widget.postid).then((value) {
                var title = "";
                var content = "删除成功";
                if (!value.success) {
                  content = "删除失败";
                  if (value.error == -1) {
                    content = value.result!;
                  }
                }
                showAlertDialog(context, title, Text(content),
                  actions1: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("知道了"),
                  ),
                ).then((value2) {
                  if (value.success) {
                    widget.refreshCallBack();
                  }
                });
              });
            },
            child: const Text("删除"),
          ),
        // const Spacer(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: bdwmPrimaryColor,),
          onSelected: (value) {
            if (value == "转寄") {
              showTextDialog(context, "转寄给")
              .then((value) {
                if (value == null || value.isEmpty) {
                  return;
                }
                bdwmForwrad("post", "mail", widget.bid, widget.postid, value)
                .then((res) {
                  var title = "转寄";
                  var content = "成功";
                  if (!res.success) {
                    if (res.error == -1) {
                      content = res.desc!;
                    } else {
                      content = "用户不存在";
                    }
                  }
                  showAlertDialog(context, title, Text(content),
                    actions1: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("知道了"),
                    ),
                  );
                });
              },);
            } else if (value.contains("回复")) {
              var action = "unnoreply";
              if (canReplyNotifier.value) {
                action = "noreply";
              }
              bdwmOperatePost(bid: widget.bid, postid: widget.postid, action: action)
              .then((res) {
                var txt = "操作成功";
                if (!res.success) {
                  txt = "操作失败";
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(txt),
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
                if (!res.success) { return; }
                // setState(() {
                canReplyNotifier.value = !canReplyNotifier.value;
                // });
              });
            } else if (value == "收入文集") {
              showCollectionDialog(context)
              .then((value) {
                if (value == null || value.isEmpty) {
                  return;
                }
                var values = value.split(" ");
                var mode = values[0];
                var base = values[1];
                if (base.isEmpty || base=="none") {
                  return;
                }
                bdwmCollectionImport(from: "post", bid: widget.bid, postid: widget.postid, threadid: widget.threadid, base: base, mode: mode)
                .then((importRes) {
                  var txt = "收藏成功";
                  if (importRes.success == false) {
                    var txt = "发生错误啦><";
                    if (importRes.error == -1) {
                      txt = importRes.desc ?? txt;
                    } else if (importRes.error == 9) {
                      txt = "您没有足够权限执行此操作";
                    }
                  }
                  showAlertDialog(context, "收入文集", Text(txt),
                    actions1: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("知道了"),
                    ),
                  );
                });
              });
            }
          },
          itemBuilder: (context) {
            return <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: "转寄",
                child: Text("转寄"),
              ),
              if (widget.onePostInfo.canSetReply)
                PopupMenuItem(
                  value: canReplyNotifier.value ? "设为不可回复" : "取消不可回复",
                  child: Text(canReplyNotifier.value ? "设为不可回复" : "取消不可回复"),
                ),
              const PopupMenuItem(
                value: "收入文集",
                child: Text("收入文集"),
              ),
            ];
          },
        )
      ],
    );
  }
}

class VoteComponent extends StatefulWidget {
  final String bid;
  final String postID;
  final bool iVoteUp;
  final bool iVoteDown;
  final int voteUpCount;
  final int voteDownCount;
  const VoteComponent({
    Key? key,
    required this.iVoteUp,
    required this.iVoteDown,
    required this.voteUpCount,
    required this.voteDownCount,
    required this.bid,
    required this.postID,
  }) : super(key: key);

  @override
  State<VoteComponent> createState() => _VoteComponentState();
}

class _VoteComponentState extends State<VoteComponent> {
  bool iVoteUp = false;
  bool iVoteDown = false;
  int voteUpCount = 0;
  int voteDownCount = 0;

  static const voteSize = 16.0;
  static const borderColor = Colors.grey;
  static const widthSpacer = SizedBox(width: 5,);

  @override
  void initState() {
    super.initState();
    iVoteUp = widget.iVoteUp;
    iVoteDown = widget.iVoteDown;
    voteUpCount = widget.voteUpCount;
    voteDownCount = widget.voteDownCount;
  }

  void vote(String action) async {
    if (action == "up" && iVoteUp == true) {
      action = "clear";
    }
    if (action == "down" && iVoteDown == true) {
      action = "clear";
    }
    bdwmVote(widget.bid, widget.postID, action).then((value) {
      if (value.success) {
        setState(() {
          if (action == "clear") {
            iVoteUp = false;
            iVoteDown = false;
          } else if (action == "up") {
            iVoteUp = true;
            iVoteDown = false;
          } else if (action == "down") {
            iVoteUp = false;
            iVoteDown = true;
          }
          voteUpCount = value.upCount;
          voteDownCount = value.downCount;
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text("ok"),
        //   ),
        // );
      } else {
        var text = "";
        switch (value.error) {
          case -1:
            text = value.desc ?? "";
            break;
          case 9:
            text = "抱歉，您没有本版回复(点赞)权限";
            break;
          case 11:
          default:
            text = "暂时无法这么操作";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            duration: const Duration(microseconds: 600),
          ),
        );
      }
    },);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          // padding: const EdgeInsets.only(top: 10),
          height: 26,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(voteSize/2)),
            // border: Border.all(width: 1, color: Colors.red),
            border: Border.all(color: borderColor, width: 1.0, style: BorderStyle.solid),
          ),
          child: Row(
            // mainAxisAlignment: MainAxisAlignment.end,
            // mainAxisSize: MainAxisSize.max,
            children: [
              widthSpacer,
              GestureDetector(
                child: Icon(
                  iVoteUp ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: voteSize, color: const Color(0xff5cae97),
                ),
                onTap: () {
                  vote("up");
                },
              ),
              widthSpacer,
              const Text("赞 ", style: TextStyle(fontSize: voteSize)),
              Text(voteUpCount.toString()),
              const VerticalDivider(
                color: borderColor,
                width: 10.0,
                thickness: 1.0,
              ),
              GestureDetector(
                child: Icon(
                  iVoteDown ? Icons.thumb_down : Icons.thumb_down_outlined,
                  size: voteSize, color: const Color(0xffe97c62),
                ),
                onTap: () {
                  vote("down");
                },
              ),
              widthSpacer,
              const Text("踩 ", style: TextStyle(fontSize: voteSize)),
              Text(voteDownCount.toString()),
              widthSpacer,
            ],
          ),
        )
      ],
    );
  }
}

class AttachmentComponent extends StatelessWidget {
  final List<AttachmentInfo> attachments;
  const AttachmentComponent({Key? key, required this.attachments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const spaceSpacer = Text(" ");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attachments.map((e) {
        if (e.type == AttachmentType.showText) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.attachment),
              spaceSpacer,
              Flexible(
                child: GestureDetector(
                  child: Text.rich(
                    TextSpan(
                      text: e.text,
                      style: textLinkStyle,
                      children: [
                        TextSpan(
                          text: e.size,
                          style: textLinkSiblingStyle,
                        ),
                      ]
                    ),
                  ),
                  onTap: () async {
                    var parsedUrl = Uri.parse(e.link);
                    if (true || !await canLaunchUrl(parsedUrl)) {
                      if (!await launchUrl(parsedUrl)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("打开链接失败"), duration: Duration(milliseconds: 600),),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("未能打开链接"),),
                      );
                    }
                    // gotoDetailImage(context: context, link: e.link, name: e.text);
                  },
                ),
              ),
            ],
          );
        } else if (e.type == AttachmentType.showThumbnail) {
          return GestureDetector(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
              child: Image.network(
                e.thumbnailLink,
                errorBuilder: (context, error, stackTrace) {
                  return Text("${e.text} 加载失败");
                },
              ),
            ),
            onTap: () {
              gotoDetailImage(context: context, link: e.link, name: e.text);
            },
          );
        }
        return const Text("42");
      },).toList(),
    );
  }
}

class OnePostComponent extends StatelessWidget {
  final OnePostInfo onePostInfo;
  final String bid;
  final String threadid;
  final String boardName;
  final Function refreshCallBack;

  const OnePostComponent({Key? key, required this.onePostInfo, required this.bid, required this.refreshCallBack, required this.boardName, required this.threadid}) : super(key: key);

  bool get simpleAttachment => false;
  final _contentFont = const TextStyle(fontSize: 16, fontWeight: FontWeight.normal);

  @override
  Widget build(BuildContext context) {
    var item = onePostInfo;
    // double deviceWidth = MediaQuery.of(context).size.width;
    return Card(
      // color: item.postNumber.contains("高亮") ? hightlightColor : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52.0,
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                GestureDetector(
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(item.authorInfo.avatarLink),
                  ),
                  onTap: () {
                    if (item.authorInfo.uid.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pushNamed('/user', arguments: item.authorInfo.uid);
                  },
                ),
                if (item.postOwner)
                  const Text("楼主", style: TextStyle(fontSize: 12, color: bdwmPrimaryColor)),
                Text(item.postNumber, style: TextStyle(fontSize: 12, color: item.postNumber.contains("高亮") ? highlightReplyColor : Colors.grey)),
                if (item.isBaoLiu) genThreadLabel("保留"),
                if (item.isWenZhai) genThreadLabel("文摘"),
                if (item.isYuanChuang) genThreadLabel("原创"),
                if (item.isJingHua) genThreadLabel("精华"),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 5.0, right: 5.0, bottom: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: item.authorInfo.userName),
                        const TextSpan(text: ' ('),
                        // WidgetSpan(child: HtmlComponent(item.authorInfo.nickName, needSelect: true),),
                        html2TextSpan(item.authorInfo.nickName),
                        const TextSpan(text: ') '),
                        TextSpan(text: item.authorInfo.status),
                      ],
                    ),
                  ),
                  if (item.modifyTime.isNotEmpty)
                    Text(
                      item.modifyTime,
                    ),
                  Text(
                    item.postTime,
                  ),
                  const Divider(),
                  // renderHtml(item.content, ts: _contentFont, context: context),
                  HtmlComponent(item.content, ts: _contentFont),
                  VoteComponent(
                    iVoteUp: onePostInfo.iVoteUp,
                    iVoteDown: onePostInfo.iVoteDown,
                    voteUpCount: onePostInfo.upCount,
                    voteDownCount: onePostInfo.downCount,
                    bid: bid,
                    postID: onePostInfo.postID,
                  ),
                  const Divider(),
                  OperateComponent(bid: bid, threadid: threadid, postid: onePostInfo.postID, uid: onePostInfo.authorInfo.uid, refreshCallBack: refreshCallBack, boardName: boardName, onePostInfo: onePostInfo,),
                  if (item.attachmentInfo.isNotEmpty)
                    ...[
                      const Divider(),
                      const Text("附件", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                    if (simpleAttachment)
                      ...[
                        // renderHtml(item.attachmentHtml, context: context),
                        HtmlComponent(item.attachmentHtml),
                      ]
                    else
                      AttachmentComponent(attachments: onePostInfo.attachmentInfo),
                  if (item.signature.isNotEmpty)
                    ...[
                      const Divider(),
                      HtmlComponent(item.signature),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReadThreadPage extends StatefulWidget {
  final String bid;
  final String threadid;
  final String page;
  final ThreadPageInfo threadPageInfo;
  final Function refreshCallBack;
  final String? postid;
  const ReadThreadPage({Key? key, required this.bid, required this.threadid, required this.page, required this.threadPageInfo, required this.refreshCallBack, this.postid}) : super(key: key);

  @override
  State<ReadThreadPage> createState() => _ReadThreadPageState();
}

class _ReadThreadPageState extends State<ReadThreadPage> {
  final _titleFont = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  final _scrollController = ScrollController();
  var itemKeys = <GlobalKey>[];
  String? postid;

  @override
  void initState() {
    super.initState();
    // getData().then((value) {
    //   setState(() {
    //     threadPageInfo = value;
    //   });
    // });
    for (var _ in widget.threadPageInfo.posts) {
      itemKeys.add(GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_){
      if (widget.postid != null) {
        BuildContext? c;
        var i = 0;
        while (i<widget.threadPageInfo.posts.length) {
          var p = widget.threadPageInfo.posts[i];
          if (p.postID == widget.postid) {
            c = itemKeys[i].currentContext;
            break;
          }
          i+=1;
        }
        if (c!=null) {
          Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 1500));
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    clearAllExtendedImageCache();
    super.dispose();
  }

  Widget _onepost(OnePostInfo item, int idx) {
    return OnePostComponent(onePostInfo: item, bid: widget.bid, refreshCallBack: widget.refreshCallBack, boardName: widget.threadPageInfo.board.text, key: itemKeys[idx], threadid: widget.threadid,);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onDoubleTap: () {
            // Scrollable.ensureVisible(itemKeys[0].currentContext!, duration: const Duration(milliseconds: 1500));
            _scrollController.animateTo(0, duration: const Duration(milliseconds: 1500), curve: Curves.ease);
          },
          child: Container(
            padding: const EdgeInsets.all(10.0),
            alignment: Alignment.centerLeft,
            // height: 20,
            child: Text(
              widget.threadPageInfo.title,
              style: _titleFont,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: widget.threadPageInfo.posts.asMap().entries.map((pair) {
                return _onepost(pair.value, pair.key);
              }).toList(),
            ),
          ),
          // child: ListView(
          //   controller: ScrollController(),
          //   padding: const EdgeInsets.all(8),
          //   children: widget.threadPageInfo.posts.asMap().entries.map((pair) {
          //     return _onepost(pair.value, pair.key);
          //   }).toList(),
          // ),
          // child: ListView.builder(
          //   controller: ScrollController(),
          //   padding: const EdgeInsets.all(8),
          //   itemCount: widget.threadPageInfo.posts.length,
          //   itemBuilder: (context, index) {
          //     return _onepost(widget.threadPageInfo.posts[index]);
          //   },
          // ),
        )
      ]
    );
  }
}
