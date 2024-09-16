import 'package:flutter/material.dart';

import '../html_parser/mail_parser.dart';
import './html_widget.dart' show HtmlComponent, genSimpleCachedImageProvider;
import './read_thread.dart' show AttachmentComponent;
import './collection.dart' show showCollectionDialog;
import '../bdwm/collection.dart';
import '../bdwm/forward.dart';
import './utils.dart';
import './constants.dart' show bdwmPrimaryColor;
import '../globalvars.dart' show globalConfigInfo;
import '../bdwm/mail.dart' show bdwmOperateMail;
import '../router.dart' show nv2Push;
import '../services_instance.dart' show unreadMail;

class MailListView extends StatefulWidget {
  final MailListInfo mailListInfo;
  final String type;
  final Function refreshCallBack;
  const MailListView({super.key, required this.mailListInfo, required this.type, required this.refreshCallBack});

  @override
  State<MailListView> createState() => _MailListViewState();
}

class _MailListViewState extends State<MailListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.mailListInfo.mailItems.length,
      itemBuilder: (context, index) {
        var item = widget.mailListInfo.mailItems[index];
        return Card(
          child: ListTile(
            onLongPress: widget.type == "5" ? null : () async {
              var toStar = item.hasStar ? "unmark" : "mark";
              var toStarName = item.hasStar ? "取消星标" : "星标";
              var opt = await getOptOptions(context, [
                SimpleTuple2(name: toStarName, action: toStar),
                SimpleTuple2(name: "删除", action: "delete"),
              ]);
              if (opt == null) { return; }
              var res = await bdwmOperateMail(postid: item.id, action: opt);
              var title = "站内信";
              var actionName = opt == "delete" ? "删除" : toStarName;
              var content = "$actionName成功";
              if (!res.success) {
                content = "$actionName失败";
                if (res.error == -1) {
                  content = res.result!;
                }
              }
              if (!context.mounted) { return; }
              await showInformDialog(context, title, content);
              if (res.success) {
                widget.refreshCallBack();
              }
            },
            onTap: () {
              nv2Push(context, '/mailDetail', arguments: {
                'postid': item.id,
                'type': widget.type,
              });
            },
            leading: GestureDetector(
              child: Container(
                width: 40,
                alignment: Alignment.center,
                child: CircleAvatar(
                  // radius: 100,
                  backgroundColor: Colors.white,
                  backgroundImage: genSimpleCachedImageProvider(item.avatar),
                ),
              ),
              onTap: () {
                if (item.uid.isEmpty) {
                  return;
                }
                nv2Push(context, '/user', arguments: item.uid);
              },
            ),
            title: Text.rich(
              TextSpan(
                children: [
                  if (item.hasStar) ...[
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(Icons.star, color: bdwmPrimaryColor, size: 12),
                    ),
                  ],
                  TextSpan(text: item.userName),
                  const TextSpan(text: "  "),
                  TextSpan(text: item.time),
                ]
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.unread) ...[
                      Icon(Icons.circle, color: bdwmPrimaryColor, size: 8),
                    ],
                    Expanded(
                      child: Text(
                        item.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.hasAttachment) ...[
                      const Icon(Icons.attachment),
                    ]
                  ],
                ),
                Text(
                  item.content,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class MailDetailView extends StatefulWidget {
  final MailDetailInfo mailDetailInfo;
  final String postid;
  final String type;
  final Function refreshCallBack;
  const MailDetailView({super.key, required this.mailDetailInfo, required this.postid, required this.type, required this.refreshCallBack});

  @override
  State<MailDetailView> createState() => _MailDetailViewState();
}

class _MailDetailViewState extends State<MailDetailView> {
  final _contentFont = TextStyle(fontSize: globalConfigInfo.contentFontSize, fontWeight: FontWeight.normal);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _controller.jumpTo(_controller.position.maxScrollExtent);
      unreadMail.clearOne(widget.postid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: ListTile(
            leading: GestureDetector(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: genSimpleCachedImageProvider(widget.mailDetailInfo.avatar),
              ),
              onTap: () {
                if (widget.mailDetailInfo.uid.isEmpty) {
                  return;
                }
                nv2Push(context, '/user', arguments: widget.mailDetailInfo.uid);
              },
            ),
            title: SelectableText(widget.mailDetailInfo.title),
            subtitle: SelectableText("${widget.mailDetailInfo.userDescription} ${widget.mailDetailInfo.user}\n${widget.mailDetailInfo.time}"),
            isThreeLine: true,
          ),
        ),
        Card(
          child: Container(
            padding: const EdgeInsets.all(10.0),
            child: HtmlComponent(widget.mailDetailInfo.content, ts: _contentFont,),
          ),
        ),
        if (widget.mailDetailInfo.signatureHtml.isNotEmpty)
          Card(
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: HtmlComponent(widget.mailDetailInfo.signatureHtml),
            ),
          ),
        if (widget.mailDetailInfo.attachmentInfo.isNotEmpty)
          Card(
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: AttachmentComponent(attachments: widget.mailDetailInfo.attachmentInfo,),
            ),
          ),
        Card(
          child: Wrap(
            children: [
              if (widget.type.isEmpty || widget.type == "3") // 收件箱，星标
                TextButton(
                  onPressed: () {
                    nv2Push(context, "/mailNew", arguments: {
                      'parentid': widget.postid,
                    });
                  },
                  child: const Text("回复"),
                ),
              TextButton(
                onPressed: () {
                showCollectionDialog(context, isSingle: true)
                .then((value) {
                  if (value == null || value.isEmpty) {
                    return;
                  }
                  var base = value;
                  if (base.isEmpty || base=="none") {
                    return;
                  }
                  bdwmCollectionImport(from: "mail", bid: "", postid: widget.postid, threadid: "", base: base, mode: "")
                  .then((importRes) {
                    var txt = "收藏成功";
                    if (importRes.success == false) {
                      txt = "发生错误啦><";
                      if (importRes.error == -1) {
                        txt = importRes.desc ?? txt;
                      } else if (importRes.error == 9) {
                        txt = "您没有足够权限执行此操作";
                      }
                    }
                    if (context.mounted) {
                      showAlertDialog(context, "收入文集", Text(txt),
                        actions1: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("知道了"),
                        ),
                      );
                    }
                  });
                });
                },
                child: const Text("收入文集"),
              ),
              TextButton(
                onPressed: () {
                  showTextDialog(context, "转载到的版面")
                  .then((value) {
                    if (value == null || value.isEmpty) {
                      return;
                    }
                    bdwmForwrad("mail", "post", "", widget.postid, value)
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
                      if (context.mounted) {
                        showAlertDialog(context, title, Text(content),
                          actions1: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("知道了"),
                          ),
                        );
                      }
                    });
                  },);
                },
                child: const Text("转载"),
              ),
              TextButton(
                onPressed: () {
                  showTextDialog(context, "转寄给")
                  .then((value) {
                    if (value == null || value.isEmpty) {
                      return;
                    }
                    bdwmForwrad("mail", "mail", "", widget.postid, value)
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
                      if (context.mounted) {
                        showAlertDialog(context, title, Text(content),
                          actions1: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("知道了"),
                          ),
                        );
                      }
                    });
                  },);
                },
                child: const Text("转寄"),
              ),
              TextButton(
                onPressed: () {
                  showConfirmDialog(context, "站内信", "确认删除？").then((value) {
                    if (value==null) { return; }
                    if (value.isEmpty) { return; }
                    if (value == "yes") {
                      bdwmOperateMail(postid: widget.postid, action: "delete")
                      .then((mailRes) {
                        var title = "站内信";
                        var content = "删除成功";
                        if (!mailRes.success) {
                          content = "删除失败";
                          if (mailRes.error == -1) {
                            content = mailRes.result!;
                          }
                        }
                        if (context.mounted) {
                          showAlertDialog(context, title, Text(content),
                            actions1: TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("知道了"),
                            ),
                          ).then((value2) {
                            if (mailRes.success) {
                              widget.refreshCallBack();
                            }
                          });
                        }
                      });
                    }
                  });
                },
                child: const Text("删除"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}