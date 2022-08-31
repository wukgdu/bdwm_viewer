import 'package:flutter/material.dart';

import '../bdwm/vote.dart';
import '../bdwm/posts.dart';
import './utils.dart';
import './constants.dart';
import '../html_parser/read_thread_parser.dart';
import '../globalvars.dart';
import '../pages/detail_image.dart';
import './html_widget.dart';

class OperateComponent extends StatefulWidget {
  final String bid;
  final String boardName;
  final String threadid;
  final String postid;
  final String uid;
  final Function refreshCallBack;
  const OperateComponent({super.key, required this.bid, required this.threadid, required this.postid, required this.uid, required this.refreshCallBack, required this.boardName});

  @override
  State<OperateComponent> createState() => _OperateComponentState();
}

class _OperateComponentState extends State<OperateComponent> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () {},
          child: const Text("回帖"),
        ),
        // TODO: get info from html parser
        if (globalUInfo.uid == widget.uid && globalUInfo.login == true)
          TextButton(
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
        if (globalUInfo.uid == widget.uid && globalUInfo.login == true)
          TextButton(
            onPressed: () {
              bdwmDeletePost(bid: widget.bid, postid: widget.postid).then((value) {
                var title = "";
                var content = "删除成功";
                if (!value.success) {
                  content = "删除失败";
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

  static const voteSize = 12.0;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ok"),
          ),
        );
      } else {
        var text = "";
        switch (value.error) {
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
          ),
        );
      }
    },);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          // padding: const EdgeInsets.only(top: 10),
          height: 20,
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
                  onTap: () {
                    gotoDetailImage(context: context, link: e.link, name: e.text);
                  },
                ),
              ),
            ],
          );
        } else if (e.type == AttachmentType.showThumbnail) {
          return GestureDetector(
            child: Image.network(
              e.thumbnailLink,
              errorBuilder: (context, error, stackTrace) {
                return Text("${e.text} 加载失败");
              },
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
  final String boardName;
  final Function refreshCallBack;

  const OnePostComponent({Key? key, required this.onePostInfo, required this.bid, required this.refreshCallBack, required this.boardName}) : super(key: key);

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
            padding: const EdgeInsets.all(10.0),
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
                  const Text("楼主", style: TextStyle(fontSize: 12, color: Colors.lightBlue)),
                Text(item.postNumber, style: TextStyle(fontSize: 12, color: item.postNumber.contains("高亮") ? hightlightColor : Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 10.0, right: 10.0, bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: item.authorInfo.userName),
                        const TextSpan(text: ' ('),
                        WidgetSpan(child: HtmlComponent(item.authorInfo.nickName, needSelect: true),),
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
                  OperateComponent(bid: bid, threadid: bid, postid: onePostInfo.postID, uid: onePostInfo.authorInfo.uid, refreshCallBack: refreshCallBack, boardName: boardName,),
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
  const ReadThreadPage({Key? key, required this.bid, required this.threadid, required this.page, required this.threadPageInfo, required this.refreshCallBack}) : super(key: key);

  @override
  State<ReadThreadPage> createState() => _ReadThreadPageState();
}

class _ReadThreadPageState extends State<ReadThreadPage> {
  final _titleFont = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    // getData().then((value) {
    //   setState(() {
    //     threadPageInfo = value;
    //   });
    // });
  }

  Widget _onepost(OnePostInfo item) {
    return OnePostComponent(onePostInfo: item, bid: widget.bid, refreshCallBack: widget.refreshCallBack, boardName: widget.threadPageInfo.board.text,);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10.0),
          alignment: Alignment.centerLeft,
          // height: 20,
          child: Text(
            widget.threadPageInfo.title,
            style: _titleFont,
          ),
        ),
        Expanded(
          // child: ListView(
          //   controller: ScrollController(),
          //   padding: const EdgeInsets.all(8),
          //   children: [...widget.threadPageInfo.posts.map((e) {
          //     return _onepost(e);
          //   }).toList()],
          // ),
          child: ListView.builder(
            controller: ScrollController(),
            padding: const EdgeInsets.all(8),
            itemCount: widget.threadPageInfo.posts.length,
            itemBuilder: (context, index) {
              return _onepost(widget.threadPageInfo.posts[index]);
            },
          ),
        )
      ]
    );
  }
}
