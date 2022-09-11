import 'package:flutter/material.dart';

import '../html_parser/mail_parser.dart';
import './html_widget.dart' show HtmlComponent;
import './read_thread.dart' show AttachmentComponent;

class MailListPage extends StatefulWidget {
  final MailListInfo mailListInfo;
  final String type;
  const MailListPage({super.key, required this.mailListInfo, required this.type});

  @override
  State<MailListPage> createState() => _MailListPageState();
}

class _MailListPageState extends State<MailListPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: ListView.builder(
        itemCount: widget.mailListInfo.mailItems.length,
        itemBuilder: (context, index) {
          var item = widget.mailListInfo.mailItems[index];
          return Card(
            child: ListTile(
              onTap: () {
                Navigator.of(context).pushNamed('/mailDetail', arguments: {
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
                    backgroundImage: NetworkImage(item.avatar),
                  ),
                ),
                onTap: () {
                  if (item.uid.isEmpty) {
                    return;
                  }
                  Navigator.of(context).pushNamed('/user', arguments: item.uid);
                },
              ),
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: item.userName),
                    const TextSpan(text: "  "),
                    TextSpan(text: item.time),
                  ]
                ),
              ),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    if (item.unread)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.circle, color: Colors.red, size: 8),
                      ),
                    WidgetSpan(child: Text(
                      item.title,
                      overflow: TextOverflow.ellipsis,
                    )),
                    if (item.hasAttachment)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.attachment),
                      ),
                    const TextSpan(text: "\n"),
                    WidgetSpan(child: Text(
                      item.content,
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

class MailDetailPage extends StatefulWidget {
  final MailDetailInfo mailDetailInfo;
  final String postid;
  final String type;
  const MailDetailPage({super.key, required this.mailDetailInfo, required this.postid, required this.type});

  @override
  State<MailDetailPage> createState() => _MailDetailPageState();
}

class _MailDetailPageState extends State<MailDetailPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: ListTile(
            leading: GestureDetector(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(widget.mailDetailInfo.avatar),
              ),
              onTap: () {
                if (widget.mailDetailInfo.uid.isEmpty) {
                  return;
                }
                Navigator.of(context).pushNamed('/user', arguments: widget.mailDetailInfo.uid);
              },
            ),
            title: SelectableText(widget.mailDetailInfo.title),
            subtitle: SelectableText("创建人 ${widget.mailDetailInfo.user}\n${widget.mailDetailInfo.time}"),
            isThreeLine: true,
          ),
        ),
        Card(
          child: Container(
            padding: const EdgeInsets.all(10.0),
            child: HtmlComponent(widget.mailDetailInfo.content),
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
      ],
    );
  }
}