import 'package:flutter/material.dart';

import '../html_parser/collection_parser.dart';
import './read_thread.dart';
import './html_widget.dart';

class CollectionPage extends StatefulWidget {
  final CollectionList collectionList;
  final String title;
  const CollectionPage({super.key, required this.collectionList, required this.title});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {

  Widget oneItem(CollectionItem item) {
    return Card(
      child: ListTile(
        onTap: () {
          if (item.type == "dir") {
            Navigator.of(context).pushNamed('/collection', arguments: {
              'link': item.link,
              'title': widget.title,
            });
          } else if (item.type == "file") {
            Navigator.of(context).pushNamed('/collectionArticle', arguments: {
              'link': item.link,
              'title': widget.title,
            });
          }
        },
        leading: item.type == "dir" ? const Icon(Icons.folder) : const Icon(Icons.article),
        title: Text(item.name),
        subtitle: Text.rich(
          TextSpan(
            children: [
              if (item.author.isNotEmpty)
                TextSpan(text: "${item.author} "),
              TextSpan(text: item.time),
            ],
          )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: widget.collectionList.collectionItems.map((e) {
        return oneItem(e);
      }).toList(),
    );
  }
}

class CollectionArticlePage extends StatefulWidget {
  final CollectionArticle collectionArticle;
  const CollectionArticlePage({super.key, required this.collectionArticle});

  @override
  State<CollectionArticlePage> createState() => _CollectionArticlePageState();
}

class _CollectionArticlePageState extends State<CollectionArticlePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: ListTile(
            leading: GestureDetector(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(widget.collectionArticle.avatar),
              ),
              onTap: () {
                if (widget.collectionArticle.uid.isEmpty) {
                  return;
                }
                Navigator.of(context).pushNamed('/user', arguments: widget.collectionArticle.uid);
              },
            ),
            title: SelectableText(widget.collectionArticle.title),
            subtitle: SelectableText("创建人 ${widget.collectionArticle.user}\n${widget.collectionArticle.time}"),
            isThreeLine: true,
          ),
        ),
        Card(
          child: Container(
            padding: const EdgeInsets.all(10.0),
            child: HtmlComponent(widget.collectionArticle.content),
          ),
        ),
        if (widget.collectionArticle.attachmentInfo.isNotEmpty)
          Card(
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: AttachmentComponent(attachments: widget.collectionArticle.attachmentInfo,),
            ),
          ),
      ],
    );
  }
}