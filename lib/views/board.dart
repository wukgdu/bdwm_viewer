import 'package:bdwm_viewer/bdwm/set_read.dart';
import 'package:flutter/material.dart';

import '../html_parser/board_parser.dart';
import './constants.dart';
import '../bdwm/req.dart';
import '../bdwm/star_board.dart';
import '../globalvars.dart';
import './utils.dart';
import '../router.dart' show nv2Push;

class StarBoard extends StatefulWidget {
  final int starCount;
  final bool likeIt;
  final int bid;
  const StarBoard({Key? key, required this.starCount, required this.likeIt, required this.bid}) : super(key: key);

  @override
  State<StarBoard> createState() => _StarBoardState();
}

class _StarBoardState extends State<StarBoard> {
  int starCount = 0;
  bool likeIt = false;

  @override
  void initState() {
    super.initState();
    starCount = widget.starCount;
    likeIt = widget.likeIt;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: likeIt ? const Icon(Icons.star, color: bdwmPrimaryColor,) : const Icon(Icons.star_outline),
          onPressed: () {
            var action = likeIt ? "delete" : "add";
            bdwmStarBoard(widget.bid, action).then((value) {
              if (value.success) {
                setState(() {
                  if (action == "add") {
                    setState(() {
                      starCount += 1;
                      likeIt = true;
                    });
                  } else {
                    setState(() {
                      starCount -= 1;
                      likeIt = false;
                    });
                  }
                });
              } else {
                var reason = "不知道为什么";
                if (value.error == -1) {
                  reason = value.desc!;
                }
                showAlertDialog(context, "失败", Text(reason),
                  actions1: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("知道了"),
                  ),
                );
              }
            });
          },
        ),
        Text(
          starCount.toString(),
        ),
      ]
    );
  }
}

class OneThreadInBoard extends StatelessWidget {
  final BoardPostInfo boardPostInfo;
  final String bid;
  final String boardName;
  const OneThreadInBoard({Key? key, required this.boardPostInfo, required this.bid, required this.boardName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool pinned = boardPostInfo.bpID == "置顶";
    bool ad = boardPostInfo.bpID == "推广";
    bool specialOne = pinned || ad;
    return Card(
        child: ListTile(
          title: Text.rich(
            textAlign: TextAlign.left,
            TextSpan(
              children: <InlineSpan>[
                if (pinned)
                  const WidgetSpan(child: Icon(Icons.pin_drop, color: bdwmPrimaryColor, size: 16), alignment: PlaceholderAlignment.middle)
                else if (ad)
                  TextSpan(text: boardPostInfo.bpID, style: const TextStyle(backgroundColor: Colors.amber, color: Colors.white))
                else if (boardPostInfo.isNew)
                  const WidgetSpan(
                    child: Icon(Icons.circle, color: bdwmPrimaryColor, size: 7),
                    alignment: PlaceholderAlignment.middle,
                  ),
                TextSpan(
                  text: boardPostInfo.title,
                  style: boardPostInfo.isGaoLiang ? const TextStyle(color: highlightColor) : null,
                ),
                if (boardPostInfo.hasAttachment)
                  const WidgetSpan(child: Icon(Icons.attachment, color: bdwmPrimaryColor, size: 16), alignment: PlaceholderAlignment.middle),
                if (boardPostInfo.lock)
                  const WidgetSpan(child: Icon(Icons.lock, color: bdwmPrimaryColor, size: 16), alignment: PlaceholderAlignment.middle),
                if (boardPostInfo.isZhiDing)
                  WidgetSpan(child: genThreadLabel("置顶"), alignment: PlaceholderAlignment.middle),
                if (boardPostInfo.isBaoLiu)
                  WidgetSpan(child: genThreadLabel("保留"), alignment: PlaceholderAlignment.middle),
                if (boardPostInfo.isWenZhai)
                  WidgetSpan(child: genThreadLabel("文摘"), alignment: PlaceholderAlignment.middle),
                if (boardPostInfo.isYuanChuang)
                  WidgetSpan(child: genThreadLabel("原创分"), alignment: PlaceholderAlignment.middle),
                if (boardPostInfo.isJingHua)
                  WidgetSpan(child: genThreadLabel("精华"), alignment: PlaceholderAlignment.middle),
              ],
            )
          ),
          subtitle: specialOne ? null
            : Text.rich(
              TextSpan(
                children: [
                  boardPostInfo.userName=="原帖已删除"
                  ? TextSpan(text: boardPostInfo.userName)
                  : TextSpan(
                    children: [
                      TextSpan(text: boardPostInfo.userName, style: serifFont),
                      TextSpan(text: " 发表于 ${boardPostInfo.pTime}"),
                    ],
                  ),
                  const TextSpan(text: "   "),
                  const WidgetSpan(
                    child: Icon(Icons.comment, size: 12),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  const TextSpan(text: " "),
                  TextSpan(text: boardPostInfo.commentCount),
                  const TextSpan(text: "\n"),
                  TextSpan(
                    children: [
                      TextSpan(text: boardPostInfo.lastUser, style: serifFont),
                      TextSpan(text: " 最后回复于 ${boardPostInfo.lastTime}"),
                    ],
                  ),
                ],
              )
            ),
          isThreeLine: specialOne ? false : true,
          onTap: () {
            if (specialOne) {
              var link = boardPostInfo.link;
              var p1Bid = link.indexOf("bid=");
              var p2Bid = link.indexOf("&", p1Bid);
              var nBid = p2Bid == -1 ? link.substring(p1Bid+4) : link.substring(p1Bid+4, p2Bid);
              if (link.contains("post-read-single.php")) {
                bdwmClient.get(link, headers: genHeaders2()).then((value) {
                  if (value == null) {
                    showNetWorkDialog(context);
                  } else {
                    var threadid = directToThread(value.body);
                    if (threadid.isEmpty) { return; }
                    int? link2Int = int.tryParse(threadid);
                    if (link2Int == null) {
                      showAlertDialog(context, "跳转失败", Text(threadid),
                        actions1: TextButton(
                          onPressed: () { Navigator.of(context).pop(); },
                          child: const Text("知道了"),
                        ),
                      );
                    }
                    nv2Push(context, '/thread', arguments: {
                      'bid': nBid,
                      'threadid': threadid,
                      'boardName': boardName,
                      'page': '1',
                    });
                  }
                });
              } else {
                var p1Tid = link.indexOf("threadid=");
                var p2Tid = link.indexOf("&", p1Tid);
                var nTid = p2Tid == -1 ? link.substring(p1Tid+9) : link.substring(p1Tid+9, p2Tid);
                nv2Push(context, '/thread', arguments: {
                  'bid': nBid,
                  'threadid': nTid,
                  'boardName': boardName,
                  'page': '1',
                });
              }
            } else {
              nv2Push(context, '/thread', arguments: {
                'bid': bid,
                'threadid': boardPostInfo.threadID,
                'boardName': boardName,
                'page': '1',
              });
            }
          },
        ),
    );
  }
}
class BoardPage extends StatefulWidget {
  final String bid;
  final BoardInfo boardInfo;
  final int page;
  const BoardPage({Key? key, required this.bid, required this.boardInfo, required this.page}) : super(key: key);

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  BoardInfo boardInfo = BoardInfo.empty();
  bool updateToggle = false;
  final _titleFont = const TextStyle(fontWeight: FontWeight.bold, fontSize: 18);
  final _titleFont2 = const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey);
  // static const _boldFont = TextStyle(fontWeight: FontWeight.bold);
  static const double _padding1 = 10;
  static const double _padding2 = 20;

  @override
  void initState() {
    super.initState();
    // boardInfo = getExampleBoard();
    boardInfo = widget.boardInfo;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (widget.page <= 1)
          Container(
            margin: const EdgeInsets.only(top: _padding1, left: _padding2, right: _padding2, bottom: 0),
            child: Row(
              children: [
                Text(boardInfo.boardName, style: _titleFont),
                const Spacer(),
                StarBoard(starCount: int.parse(boardInfo.likeCount), likeIt: boardInfo.iLike, bid: int.parse(boardInfo.bid),),
              ],
            ),
          ),
        if (widget.page <= 1)
          Container(
            margin: const EdgeInsets.only(top: 0, left: _padding2, right: _padding2, bottom: _padding1),
            child: Row(
              children: [
                Text(boardInfo.engName, style: _titleFont2),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (boardInfo.collectionLink.isEmpty) { return; }
                    nv2Push(context, '/collection', arguments: {
                      'link': boardInfo.collectionLink,
                      'title': boardInfo.boardName,
                    });
                  },
                  child: const Text.rich(
                    TextSpan(text: "精华区", style: textLinkStyle),
                  ),
                ),
              ],
            ),
          ),
        if (widget.page <= 1 && boardInfo.intro.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: _padding1, left: _padding2, right: _padding2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(boardInfo.intro),),
                GestureDetector(
                  onTap: () {
                    var threads = <int>[];
                    for (var p in widget.boardInfo.boardPostInfo) {
                      var pid = int.tryParse(p.bpID);
                      var tid = int.tryParse(p.threadID);
                      if (tid != null && tid >= 0) {
                        if (pid != null && pid >= 0) {
                          threads.add(tid);
                        }
                      }
                    }
                    // will set top read
                    bdwmSetThreadRead(widget.bid, threads)
                    .then((res) {
                      var txt = "清除未读成功";
                      if (!res.success) {
                        if (res.error == -1) {
                          txt = res.desc!;
                        } else {
                          txt = "清除未读失败";
                        }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(txt), duration: const Duration(milliseconds: 600),),
                      );
                      if (res.success) {
                        for (var item in boardInfo.boardPostInfo) {
                          item.isNew = false;
                        }
                        setState(() {
                          updateToggle = !updateToggle;
                        });
                      }
                    });
                  },
                  child: const Text("清除未读", style: TextStyle(color: bdwmPrimaryColor),),
                ),
              ],
            ),
          ),
        if (widget.page <= 1 && boardInfo.admins.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: _padding2, right: _padding2, bottom: 0),
            child: Wrap(
              children: [
                // const Text("版务：", style: _boldFont),
                for (var admin in boardInfo.admins)
                  ...[
                    GestureDetector(
                      child: Text(admin.userName, style: textLinkStyle),
                      onTap: () {
                        nv2Push(context, '/user', arguments: admin.uid);
                      },
                    ),
                    const SizedBox(width: 5,),
                  ],
              ],
            ),
          ),
        if (widget.page <= 1)
          const Divider(),
        ListView.builder(
          primary: false,
          shrinkWrap: true,
          itemCount: boardInfo.boardPostInfo.length,
          itemBuilder: (context, index) {
            return OneThreadInBoard(boardPostInfo: boardInfo.boardPostInfo[index], boardName: boardInfo.boardName, bid: boardInfo.bid);
          },
        ),
      ],
    );
  }
}
