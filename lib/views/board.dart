import 'package:flutter/material.dart';

import '../html_parser/board_parser.dart';
import '../html_parser/board_single_parser.dart';
import '../utils.dart' show getQueryValue, breakLongText;
import './constants.dart';
import '../bdwm/set_read.dart';
import '../bdwm/star_board.dart';
import './html_widget.dart' show innerLinkJump;
import './utils.dart';
import '../router.dart' show nv2Replace, nv2Push;
import '../html_parser/utils.dart' show SignatureItem;
import '../bdwm/admin_board.dart';

class BoardIntroComponent extends StatefulWidget {
  final String intro;
  final bool canEditIntro;
  final String bid;
  const BoardIntroComponent({super.key, required this.intro, required this.canEditIntro, required this.bid});

  @override
  State<BoardIntroComponent> createState() => _BoardIntroComponentState();
}

class _BoardIntroComponentState extends State<BoardIntroComponent> {
  bool changingIntro = false;
  late TextEditingController textController;
  String curIntro = "";
  static const String defaultBoardDesc = "请用一句话介绍本版面";

  Icon genIcon(IconData icons) {
    return Icon(icons, color: bdwmPrimaryColor, size: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14,);
  }


@override
  void initState() {
    super.initState();
    curIntro = widget.intro;
    textController = TextEditingController(text: curIntro);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (changingIntro) {
      textController.text = curIntro;
      if (curIntro == defaultBoardDesc) {
        textController.text = "";
      }
      return Column(
        children: [
          TextField(
            controller: textController,
            minLines: 1,
            maxLines: 6,
            autocorrect: false,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(
              // contentPadding: EdgeInsets.zero,
              isDense: true,
            )
          ),
          const SizedBox(height: 5,),
          Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  var newIntro = textController.text;
                  var res = await bdwmAdminBoardSetBoardDesc(bid: widget.bid, content: newIntro);
                  if (res.success) {
                    curIntro = newIntro;
                    if (curIntro.isEmpty) {
                      curIntro = defaultBoardDesc;
                    }
                    setState(() {
                      changingIntro = false;
                    });
                  } else {
                    if (!context.mounted) { return; }
                    var alertText = res.errorMessage ?? "编辑失败~请稍后重试";
                    showInformDialog(context, "编辑失败", alertText);
                  }
                },
                child: genIcon(Icons.check),
              ),
              const SizedBox(width: 20,),
              GestureDetector(
                onTap: () {
                  setState(() {
                    changingIntro = false;
                  });
                },
                child: genIcon(Icons.close),
              )
            ],
          )
        ],
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: curIntro),
          if (widget.canEditIntro) ...[
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    changingIntro = true;
                  });
                },
                child: genIcon(Icons.edit),
              ),
              alignment: PlaceholderAlignment.middle,
            )
          ],
        ],
      ),
    );
  }
}

class BoardExtraComponent extends StatefulWidget {
  final String boardName;
  final String bid;
  final String? curThreadMode;
  final String? curPostMode;
  const BoardExtraComponent({super.key, required this.bid, required this.boardName, this.curThreadMode, this.curPostMode});

  @override
  State<BoardExtraComponent> createState() => _BoardExtraComponentState();
}

class _BoardExtraComponentState extends State<BoardExtraComponent> {
  static final SignatureItem threadMode = SignatureItem(key: "主题模式", value: "thread");
  static final SignatureItem postMode = SignatureItem(key: "单帖模式", value: "post");

  static final SignatureItem allPostMode = SignatureItem(key: "全部", value: "-1");
  static final SignatureItem markPostMode = SignatureItem(key: "保留", value: "3");
  static final SignatureItem digestPostMode = SignatureItem(key: "文摘", value: "2");
  static final SignatureItem selfDeletePostMode = SignatureItem(key: "自删", value: "6");
  static final SignatureItem deletePostMode = SignatureItem(key: "删除", value: "8");
  static final SignatureItem attachPostMode = SignatureItem(key: "附件", value: "10");
  static const dBox = SizedBox(width: 10,);
  var curThreadMode = threadMode;
  var curPostMode = allPostMode;
  @override
  void initState() {
    super.initState();
    if (widget.curThreadMode != null) {
      if (widget.curThreadMode == threadMode.value) { curThreadMode = threadMode; }
      else if (widget.curThreadMode == postMode.value) { curThreadMode = postMode; }
    }
    if (widget.curPostMode != null) {
      if (widget.curPostMode == allPostMode.value) { curPostMode = allPostMode; }
      else if (widget.curPostMode == markPostMode.value) { curPostMode = markPostMode; }
      else if (widget.curPostMode == digestPostMode.value) { curPostMode = digestPostMode; }
      else if (widget.curPostMode == attachPostMode.value) { curPostMode = attachPostMode; }
      else if (widget.curPostMode == selfDeletePostMode.value) { curPostMode = selfDeletePostMode; }
      else if (widget.curPostMode == deletePostMode.value) { curPostMode = deletePostMode; }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DropdownButton<SignatureItem>(
          hint: const Text("全部"),
          icon: const Icon(Icons.arrow_drop_down),
          style: Theme.of(context).textTheme.bodyMedium,
          isDense: true,
          value: curPostMode,
          items: [allPostMode, markPostMode, digestPostMode, attachPostMode, selfDeletePostMode, deletePostMode].map<DropdownMenuItem<SignatureItem>>((SignatureItem item) {
            return DropdownMenuItem<SignatureItem>(
              value: item,
              child: Text(item.key),
            );
          }).toList(),
          onChanged: (SignatureItem? value) {
            if (value == null) { return; }
            if (curPostMode == value) { return; }
            if (value.value == "-1") {
              if (widget.curThreadMode == "thread") {
                nv2Replace(context, '/board', arguments: {
                  'bid': widget.bid,
                  'boardName': widget.boardName,
                });
              } else {
                nv2Replace(context, '/boardSingle', arguments: {
                  'bid': widget.bid,
                  'boardName': widget.boardName,
                  'stype': "-1",
                  'smode': widget.curThreadMode,
                });
              }
            } else {
              nv2Replace(context, '/boardSingle', arguments: {
                'bid': widget.bid,
                'boardName': widget.boardName,
                'stype': value.value,
                'smode': widget.curThreadMode,
              });
            }
          },
        ),
        if ((widget.curPostMode ?? "-1") == "-1") ...[
          dBox,
          DropdownButton<SignatureItem>(
            hint: const Text("主题模式"),
            icon: const Icon(Icons.arrow_drop_down),
            style: Theme.of(context).textTheme.bodyMedium,
            isDense: true,
            value: curThreadMode,
            items: [threadMode, postMode].map<DropdownMenuItem<SignatureItem>>((SignatureItem item) {
              return DropdownMenuItem<SignatureItem>(
                value: item,
                child: Text(item.key),
              );
            }).toList(),
            onChanged: (SignatureItem? value) {
              if (value == null) { return; }
              if (curThreadMode == value) { return; }
              if (value.value == "thread") {
                nv2Replace(context, '/board', arguments: {
                  'bid': widget.bid,
                  'boardName': widget.boardName,
                });
              } else if (value.value == "post") {
                nv2Replace(context, '/boardSingle', arguments: {
                  'bid': widget.bid,
                  'boardName': widget.boardName,
                  'stype': '-1',
                  'smode': value.value,
                });
              }
            },
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: () {
            nv2Push(context, '/boardNote', arguments: {
              'bid': widget.bid,
              'boardName': widget.boardName,
            });
          },
          child: Text("备忘录", style: TextStyle(color: bdwmPrimaryColor),),
        ),
      ],
    );
  }
}

class StarBoard extends StatefulWidget {
  final int starCount;
  final bool likeIt;
  final int bid;
  const StarBoard({super.key, required this.starCount, required this.likeIt, required this.bid});

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
          icon: likeIt ? Icon(Icons.star, color: bdwmPrimaryColor,) : const Icon(Icons.star_outline),
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
                if (context.mounted) {
                  showAlertDialog(context, "失败", Text(reason),
                    actions1: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("知道了"),
                    ),
                  );
                }
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

Future<int?> showRatePostDialog(BuildContext context, List<int> scores) {
  List<SimpleDialogOption> children = scores.map((s) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context, s);
      },
      child: Text("$s 分"),
    );
  }).toList();
  var dialog = SimpleDialog(
    title: const Text("原创分"),
    children: children,
  );

  return showDialog<int>(
    context: context,
    builder: (BuildContext context) {
      return dialog;
    },
  );
}

class OneThreadInBoard extends StatefulWidget {
  final BoardPostInfo boardPostInfo;
  final String bid;
  final String boardName;
  final bool canOpt;
  final Function refresh;
  const OneThreadInBoard({super.key, required this.boardPostInfo, required this.bid, required this.boardName, required this.canOpt, required this.refresh});

  @override
  State<OneThreadInBoard> createState() => _OneThreadInBoardState();
}

class _OneThreadInBoardState extends State<OneThreadInBoard> {
  @override
  Widget build(BuildContext context) {
    bool pinned = widget.boardPostInfo.bpID == "置顶";
    bool ad = widget.boardPostInfo.bpID == "推广";
    bool specialOne = pinned || ad;
    return Card(
        child: ListTile(
          title: Text.rich(
            textAlign: TextAlign.left,
            TextSpan(
              children: <InlineSpan>[
                if (pinned)
                  WidgetSpan(child: Icon(Icons.pin_drop, color: bdwmPrimaryColor, size: 16), alignment: PlaceholderAlignment.middle)
                else if (ad)
                  TextSpan(text: widget.boardPostInfo.bpID, style: const TextStyle(backgroundColor: Colors.amber, color: Colors.white))
                else if (widget.boardPostInfo.isNew)
                  WidgetSpan(
                    child: Icon(Icons.circle, color: bdwmPrimaryColor, size: 7),
                    alignment: PlaceholderAlignment.middle,
                  ),
                TextSpan(
                  text: breakLongText(widget.boardPostInfo.title),
                  style: widget.boardPostInfo.isGaoLiang ? const TextStyle(color: highlightColor) : null,
                ),
                if (widget.boardPostInfo.hasAttachment)
                  WidgetSpan(child: Icon(Icons.attachment, color: bdwmPrimaryColor, size: 16), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.lock)
                  WidgetSpan(child: Icon(Icons.lock, color: bdwmPrimaryColor, size: 16), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isZhiDing)
                  WidgetSpan(child: genThreadLabel("置顶"), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isBaoLiu)
                  WidgetSpan(child: genThreadLabel("保留"), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isWenZhai)
                  WidgetSpan(child: genThreadLabel("文摘"), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isYuanChuang)
                  WidgetSpan(child: genThreadLabel("原创分"), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isJingHua)
                  WidgetSpan(child: genThreadLabel("精华"), alignment: PlaceholderAlignment.middle),
              ],
            )
          ),
          subtitle: specialOne ? null
            : Text.rich(
              TextSpan(
                children: [
                  widget.boardPostInfo.userName=="原帖已删除"
                  ? TextSpan(text: widget.boardPostInfo.userName)
                  : TextSpan(
                    children: [
                      TextSpan(text: widget.boardPostInfo.userName, style: serifFont),
                      TextSpan(text: " 发表于 ${widget.boardPostInfo.pTime}"),
                    ],
                  ),
                  const TextSpan(text: "   "),
                  const WidgetSpan(
                    child: Icon(Icons.comment, size: 12),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  const TextSpan(text: " "),
                  TextSpan(text: widget.boardPostInfo.commentCount),
                  const TextSpan(text: "\n"),
                  TextSpan(
                    children: [
                      TextSpan(text: widget.boardPostInfo.lastUser, style: serifFont),
                      TextSpan(text: " 最后回复于 ${widget.boardPostInfo.lastTime}"),
                    ],
                  ),
                ],
              )
            ),
          isThreeLine: specialOne ? false : true,
          onTap: () {
            if (specialOne) {
              var link = widget.boardPostInfo.link;
              innerLinkJump(link, context);
            } else {
              nv2Push(context, '/thread', arguments: {
                'bid': widget.bid,
                'threadid': widget.boardPostInfo.itemid,
                'boardName': widget.boardName,
                'page': '1',
              });
            }
          },
          onLongPress: !widget.canOpt ? null : !specialOne ? () async {
            var opt = await getOptOptions(context, [
              SimpleTuple2(name: "同主题不可回复", action: "noreply"),
              SimpleTuple2(name: "同主题取消不可回复", action: "unnoreply"),
              SimpleTuple2(name: "同主题合集", action: "create-collect"),
              SimpleTuple2(name: "同主题删除", action: "delete"),
            ]);
            if (opt == null) { return; }
            if (opt == "noreply" || opt == "unnoreply" || opt == "delete") {
              if (opt == "delete") {
                if (!context.mounted) { return; }
                var confirm = await showConfirmDialog(context, "同主题删除", "是否确定删除帖子");
                if (confirm != "yes") { return; }
              }
              var optRes = await bdwmAdminBoardOperateThread(bid: widget.bid, threadid: widget.boardPostInfo.itemid, action: opt);
              if (optRes.success) {
                // if (!mounted) { return; }
                // var boardPageWidget = context.findAncestorWidgetOfExactType<BoardPage>();
                // if (boardPageWidget == null) { return; }
                // boardPageWidget.refresh();
                widget.refresh();
              } else {
                var confirmText = optRes.errorMessage ?? "$opt 失败~请稍后重试";
                if (!context.mounted) { return; }
                showInformDialog(context, "同主题操作失败", confirmText);
              }
            } else if (opt == "create-collect") {
              if (!context.mounted) { return; }
              var confirm = await showConfirmDialog(context, "同主题合集", "是否确定在版面生成本主题帖的合集");
              if (confirm != "yes") { return; }
              var optRes = await bdwmAdminBoardCreateThreadCollect(bid: widget.bid, threadid: widget.boardPostInfo.itemid);
              if (optRes.success) {
                widget.refresh();
              } else {
                var confirmText = optRes.errorMessage ?? "合集失败~请稍后重试";
                if (!context.mounted) { return; }
                showInformDialog(context, "同主题操作失败", confirmText);
              }
            }
          } : pinned ? () async {
            var toTop = "untop";
            var toMark = widget.boardPostInfo.isBaoLiu ? "unmark" : "mark";
            var toDigest = widget.boardPostInfo.isWenZhai ? "undigest" : "digest";
            var toHighlightTop = widget.boardPostInfo.isGaoLiang ? "unhighlight_top" : "highlight_top";
            var toNoReply = widget.boardPostInfo.lock ? "unnoreply" : "noreply";
            var opt = await getOptOptions(context, [
              SimpleTuple2(name: getActionName(toTop), action: toTop),
              SimpleTuple2(name: getActionName(toMark), action: toMark),
              SimpleTuple2(name: getActionName(toDigest), action: toDigest),
              SimpleTuple2(name: getActionName(toHighlightTop), action: toHighlightTop),
              SimpleTuple2(name: getActionName(toNoReply), action: toNoReply),
              SimpleTuple2(name: getActionName("rate"), action: "rate"),
            ]);
            if (opt == null) { return; }
            if (opt == "rate") {
              if (!context.mounted) { return; }
              var ycf = await showRatePostDialog(context, [1, 2, 3]);
              if (ycf == null) { return; }
              var optRes = await bdwmAdminBoardOperatePost(bid: widget.bid, postid: widget.boardPostInfo.itemid, action: opt, rating: ycf);
              if (optRes.success) {
                widget.refresh();
              } else {
                var confirmText = optRes.errorMessage ?? "打原创分失败~请稍后重试";
                if (!context.mounted) { return; }
                showInformDialog(context, "操作失败", confirmText);
              }
            } else {
              var optRes = await bdwmAdminBoardOperatePost(bid: widget.bid, postid: widget.boardPostInfo.itemid, action: opt);
              if (optRes.success) {
                widget.refresh();
              } else {
                var confirmText = optRes.errorMessage ?? "${getActionName(opt)}失败~请稍后重试";
                if (!context.mounted) { return; }
                showInformDialog(context, "操作失败", confirmText);
              }
            }
          } : null,
        ),
    );
  }
}

class BoardView extends StatefulWidget {
  final String bid;
  final BoardInfo boardInfo;
  final int page;
  final Function refresh;
  const BoardView({super.key, required this.bid, required this.boardInfo, required this.page, required this.refresh});

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
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
                SelectableText(boardInfo.boardName, style: _titleFont),
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
                SelectableText(boardInfo.engName, style: _titleFont2),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (boardInfo.collectionLink.isEmpty) { return; }
                    nv2Push(context, '/collection', arguments: {
                      'link': boardInfo.collectionLink,
                      'title': boardInfo.boardName,
                    });
                  },
                  child: Text.rich(
                    TextSpan(text: "精华区", style: TextStyle(color: bdwmPrimaryColor)),
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
                Expanded(
                  child: BoardIntroComponent(intro: boardInfo.intro, canEditIntro: boardInfo.canEditIntro, bid: boardInfo.bid,),
                ),
                GestureDetector(
                  onTap: () {
                    var threads = <int>[];
                    for (var p in widget.boardInfo.boardPostInfo) {
                      var pid = int.tryParse(p.bpID);
                      var tid = int.tryParse(p.itemid);
                      if (tid != null && tid >= 0) {
                        if (pid != null && pid >= 0) {
                          threads.add(tid);
                        }
                      }
                    }
                    bdwmSetThreadRead(widget.bid, threads).then((res) {
                      var txt = "清除未读成功";
                      if (!res.success) {
                        if (res.error == -1) {
                          txt = res.desc!;
                        } else {
                          txt = "清除未读失败";
                        }
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(txt), duration: const Duration(milliseconds: 600),),
                        );
                      }
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
                  child: Text("清除未读", style: TextStyle(color: bdwmPrimaryColor),),
                ),
              ],
            ),
          ),
        if (widget.page <= 1 && boardInfo.admins.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: _padding2, right: _padding2, bottom: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    children: [
                      // const Text("版务：", style: _boldFont),
                      for (var admin in boardInfo.admins) ...[
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
                if (boardInfo.canOpt) ...[
                  GestureDetector(
                    onTap: () {
                      nv2Push(context, '/boardBan', arguments: {
                        'bid': boardInfo.bid,
                        'boardName': boardInfo.boardName,
                      });
                    },
                    child: Text("禁言", style: TextStyle(color: bdwmPrimaryColor),),
                  ),
                ]
              ],
            )
          ),
        if (widget.page <= 1) ...[
          Container(
            margin: const EdgeInsets.only(top: _padding1, left: _padding2, right: _padding2, bottom: 0),
            child: BoardExtraComponent(bid: widget.bid, boardName: widget.boardInfo.boardName, curThreadMode: "thread", curPostMode: "-1",),
          ),
          const Divider(),
        ],
        ListView.builder(
          primary: false,
          shrinkWrap: true,
          itemCount: boardInfo.boardPostInfo.length,
          itemBuilder: (context, index) {
            return OneThreadInBoard(
              boardPostInfo: boardInfo.boardPostInfo[index], boardName: boardInfo.boardName, bid: boardInfo.bid,
              canOpt: boardInfo.canOpt, refresh: widget.refresh,
            );
          },
        ),
      ],
    );
  }
}

class OnePostInBoard extends StatefulWidget {
  final BoardSinglePostInfo boardPostInfo;
  final String bid;
  final String boardName;
  final bool canOpt;
  final Function refresh;
  final String? stype;
  const OnePostInBoard({super.key, required this.boardPostInfo, required this.bid, required this.boardName, required this.canOpt, required this.refresh, required this.stype});

  @override
  State<OnePostInBoard> createState() => _OnePostInBoardState();
}

class _OnePostInBoardState extends State<OnePostInBoard> {
  @override
  Widget build(BuildContext context) {
    bool pinned = widget.boardPostInfo.bpID == "置顶";
    bool ad = widget.boardPostInfo.bpID == "推广";
    bool specialOne = pinned || ad;
    return Card(
        child: ListTile(
          title: Text.rich(
            textAlign: TextAlign.left,
            TextSpan(
              children: <InlineSpan>[
                if (pinned)
                  WidgetSpan(child: Icon(Icons.pin_drop, color: bdwmPrimaryColor, size: 16), alignment: PlaceholderAlignment.middle)
                else if (ad)
                  TextSpan(text: widget.boardPostInfo.bpID, style: const TextStyle(backgroundColor: Colors.amber, color: Colors.white))
                else if (widget.boardPostInfo.isNew) ...[
                  WidgetSpan(
                    child: Icon(Icons.circle, color: bdwmPrimaryColor, size: 7),
                    alignment: PlaceholderAlignment.middle,
                  )
                ],
                TextSpan(
                  text: widget.boardPostInfo.title,
                  style: widget.boardPostInfo.isGaoLiang ? const TextStyle(color: highlightColor) : null,
                ),
                if (widget.boardPostInfo.hasAttachment)
                  WidgetSpan(child: Icon(Icons.attachment, color: bdwmPrimaryColor, size: 16), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.lock)
                  WidgetSpan(child: Icon(Icons.lock, color: bdwmPrimaryColor, size: 16), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isZhiDing)
                  WidgetSpan(child: genThreadLabel("置顶"), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isBaoLiu)
                  WidgetSpan(child: genThreadLabel("保留"), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isWenZhai)
                  WidgetSpan(child: genThreadLabel("文摘"), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isYuanChuang)
                  WidgetSpan(child: genThreadLabel("原创分"), alignment: PlaceholderAlignment.middle),
                if (widget.boardPostInfo.isJingHua)
                  WidgetSpan(child: genThreadLabel("精华"), alignment: PlaceholderAlignment.middle),
              ],
            )
          ),
          subtitle: specialOne ? null
            : Text.rich(
              TextSpan(
                children: [
                  widget.boardPostInfo.userName=="原帖已删除"
                  ? TextSpan(text: widget.boardPostInfo.userName)
                  : TextSpan(
                    children: [
                      TextSpan(text: widget.boardPostInfo.userName, style: serifFont),
                      TextSpan(text: " 发表于 ${widget.boardPostInfo.pTime}"),
                    ],
                  ),
                  const TextSpan(text: "\n"),
                  TextSpan(text: widget.boardPostInfo.bpID, style: widget.boardPostInfo.isOrigin ? const TextStyle(fontWeight: FontWeight.bold) : null),
                ],
              )
            ),
          isThreeLine: specialOne ? false : true,
          onTap: () {
            var link = widget.boardPostInfo.link;
            if (link.contains("post-read-single.php")) {
              var bid1 = getQueryValue(link, 'bid');
              var postid1 = getQueryValue(link, 'postid');
              var type = getQueryValue(link, 'type');
              nv2Push(context, '/singlePost', arguments: {
                'bid': bid1,
                'postid': postid1,
                'boardName': widget.boardName,
                'type': type,
              });
            } else {
              innerLinkJump(link, context);
            }
          },
          onLongPress: widget.boardPostInfo.isDelete ? () async {
            var item = widget.boardPostInfo;
            var toRecover = "recover";
            var opt = await getOptOptions(context, [
              SimpleTuple2(name: getActionName(toRecover), action: "recover"),
            ], desc: Center(child: SelectableText("${item.deleteUser} ${item.deleteTime}")));
            if (opt == null) { return; }
            if (opt == toRecover) {
              if (!mounted) { return; }
              var optRes = await bdwmAdminBoardOperatePost(bid: widget.bid, postid: widget.boardPostInfo.itemid, action: opt);
              if (optRes.success) {
                widget.refresh();
              } else {
                var confirmText = optRes.errorMessage ?? "${getActionName(toRecover)}失败~请稍后重试";
                if (!context.mounted) { return; }
                showInformDialog(context, "操作失败", confirmText);
              }
            }
          } : !widget.canOpt ? null : ((!specialOne) || pinned) ? () async {
            var item = widget.boardPostInfo;
            var toTop = item.isZhiDing ? "untop" : "top";
            var toMark = item.isBaoLiu ? "unmark" : "mark";
            var toDigest = item.isWenZhai ? "undigest" : "digest";
            var toHighlight = item.isGaoLiang ? "unhighlight" : "highlight";
            var toNoReply = item.lock ? "unnoreply" : "noreply";
            var toMarkDigest = widget.boardPostInfo.isBaoLiu ? "unmark_digest" : "mark_digest";
            var opt = await getOptOptions(context, [
              SimpleTuple2(name: getActionName(toTop), action: toTop),
              if (widget.stype == "2") ...[ // 文摘区
                SimpleTuple2(name: getActionName(toMarkDigest), action: toMarkDigest),
              ] else ...[
                SimpleTuple2(name: getActionName(toMark), action: toMark),
              ],
              SimpleTuple2(name: getActionName(toDigest), action: toDigest),
              SimpleTuple2(name: getActionName(toHighlight), action: toHighlight),
              SimpleTuple2(name: getActionName(toNoReply), action: toNoReply),
              SimpleTuple2(name: getActionName("rate"), action: "rate"),
              if (!item.isBaoLiu) SimpleTuple2(name: getActionName("delete"), action: "delete"),
            ]);
            if (opt == null) { return; }
            if (opt == "rate") {
              if (!context.mounted) { return; }
              var ycf = await showRatePostDialog(context, [1, 2, 3]);
              if (ycf == null) { return; }
              var optRes = await bdwmAdminBoardOperatePost(bid: widget.bid, postid: widget.boardPostInfo.itemid, action: opt, rating: ycf);
              if (optRes.success) {
                widget.refresh();
              } else {
                var confirmText = optRes.errorMessage ?? "${getActionName(opt)}失败~请稍后重试";
                if (!context.mounted) { return; }
                showInformDialog(context, "操作失败", confirmText);
              }
            } else {
              if (opt == "delete") {
                if (!context.mounted) { return; }
                var confirm = await showConfirmDialog(context, "删除", "是否确定删除帖子");
                if (confirm != "yes") { return; }
              }
              var optRes = await bdwmAdminBoardOperatePost(bid: widget.bid, postid: item.itemid, action: opt);
              if (optRes.success) {
                widget.refresh();
              } else {
                var confirmText = optRes.errorMessage ?? "${getActionName(opt)}失败~请稍后重试";
                if (!context.mounted) { return; }
                showInformDialog(context, "操作失败", confirmText);
              }
            }
          } : null,
        ),
    );
  }
}

class BoardSingleView extends StatefulWidget {
  final String bid;
  final BoardSingleInfo boardInfo;
  final int page;
  final String? stype;
  final String smode;
  final Function refresh;
  const BoardSingleView({super.key, required this.bid, required this.boardInfo, required this.page, this.stype, required this.smode, required this.refresh});

  @override
  State<BoardSingleView> createState() => _BoardSingleViewState();
}

class _BoardSingleViewState extends State<BoardSingleView> {
  BoardSingleInfo boardInfo = BoardSingleInfo.empty();
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
                SelectableText(boardInfo.boardName, style: _titleFont),
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
                SelectableText(boardInfo.engName, style: _titleFont2),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (boardInfo.collectionLink.isEmpty) { return; }
                    nv2Push(context, '/collection', arguments: {
                      'link': boardInfo.collectionLink,
                      'title': boardInfo.boardName,
                    });
                  },
                  child: Text.rich(
                    TextSpan(text: "精华区", style: TextStyle(color: bdwmPrimaryColor)),
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
                    var items = <int>[];
                    for (var p in widget.boardInfo.boardPostInfo) {
                      var pid = int.tryParse(p.bpID);
                      var tid = int.tryParse(p.itemid);
                      if (tid != null && tid >= 0) {
                        if (pid != null && pid >= 0) {
                          items.add(tid);
                        }
                      }
                    }
                    bdwmSetPostRead(widget.bid, items).then((res) {
                      var txt = "清除未读成功";
                      if (!res.success) {
                        if (res.error == -1) {
                          txt = res.desc!;
                        } else {
                          txt = "清除未读失败";
                        }
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(txt), duration: const Duration(milliseconds: 600),),
                        );
                      }
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
                  child: Text("清除未读", style: TextStyle(color: bdwmPrimaryColor),),
                ),
              ],
            ),
          ),
        if (widget.page <= 1 && boardInfo.admins.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: _padding2, right: _padding2, bottom: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    children: [
                      // const Text("版务：", style: _boldFont),
                      for (var admin in boardInfo.admins) ...[
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
                if (boardInfo.canOpt) ...[
                  GestureDetector(
                    onTap: () {
                      nv2Push(context, '/boardBan', arguments: {
                        'bid': boardInfo.bid,
                        'boardName': boardInfo.boardName,
                      });
                    },
                    child: Text("禁言", style: TextStyle(color: bdwmPrimaryColor),),
                  ),
                ]
              ],
            )
          ),
        if (widget.page <= 1) ...[
          Container(
            margin: const EdgeInsets.only(top: _padding1, left: _padding2, right: _padding2, bottom: 0),
            child: BoardExtraComponent(bid: widget.bid, boardName: widget.boardInfo.boardName, curThreadMode: widget.smode, curPostMode: widget.stype,),
          ),
          const Divider(),
        ],
        ListView.builder(
          primary: false,
          shrinkWrap: true,
          itemCount: boardInfo.boardPostInfo.length,
          itemBuilder: (context, index) {
            return OnePostInBoard(
              boardPostInfo: boardInfo.boardPostInfo[index], boardName: boardInfo.boardName, bid: boardInfo.bid, canOpt: boardInfo.canOpt, refresh: widget.refresh,
              stype: widget.stype,
            );
          },
        ),
      ],
    );
  }
}
