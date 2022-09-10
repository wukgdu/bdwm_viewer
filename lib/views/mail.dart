import 'package:flutter/material.dart';

import '../html_parser/mail_parser.dart';

class MailListPage extends StatefulWidget {
  final MailListInfo mailListInfo;
  const MailListPage({super.key, required this.mailListInfo});

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
              title: SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(text: item.userName),
                    const TextSpan(text: "  "),
                    TextSpan(text: item.time),
                  ]
                ),
              ),
              subtitle: SelectableText.rich(
                TextSpan(
                  children: [
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