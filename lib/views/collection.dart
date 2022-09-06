import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

import '../bdwm/collection.dart';
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

class CollectionImportDialogBody extends StatefulWidget {
  const CollectionImportDialogBody({super.key});

  @override
  State<CollectionImportDialogBody> createState() => _CollectionImportDialogBodyState();
}

class _CollectionImportDialogBodyState extends State<CollectionImportDialogBody> {
  late CancelableOperation getDataCancelable;
  var _treeViewController = TreeViewController();
  String _selectedNode = "";
  Set<String> visited = {};

  Future<CollectionRes> getData({String? path}) async {
    var res = await bdwmGetCollections(path: path);
    return res;
  }

  @override
  void initState() {
    super.initState();
    _selectedNode = "";
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    });
  }

  @override
  void dispose() {
    // _treeVieweController.dispose();
    getDataCancelable.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TreeViewTheme treeViewTheme = TreeViewTheme(
      expanderTheme: const ExpanderThemeData(
        // type: ExpanderType.arrow,
        // modifier: ExpanderModifier.circleFilled,
        // position: ExpanderPosition.end,
        // color: Colors.grey.shade800,
        size: 20,
        color: Colors.blue
      ),
      labelStyle: const TextStyle(
        fontSize: 16,
        letterSpacing: 0.3,
      ),
      parentLabelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w800,
        color: Colors.blue.shade700,
      ),
      iconTheme: IconThemeData(
        size: 18,
        color: Colors.grey.shade800,
      ),
      colorScheme: Theme.of(context).colorScheme,
    );
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: ((context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return const Center(child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text("错误：${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("错误：未获取数据"),);
        }
        var collectionRes = snapshot.data as CollectionRes;
        if (collectionRes.success == false) {
          var txt = "";
          if (collectionRes.error == -1) {
            txt = collectionRes.desc!;
          } else if (collectionRes.error == 9) {
            txt = "您没有足够权限执行此操作";
          } else {
            txt = "发生错误啦><";
          }
          return Center(child: Text(txt),);
        }
        if (_treeViewController.children.isEmpty) {
          _treeViewController = _treeViewController.copyWith(
            children: collectionRes.collections.map((e) {
              if (e.isdir) {
                return Node(key: e.path, label: e.title, parent: true);
              }
              return Node(label: "skip", key: e.path);
            }).toList());
        }
        return Container(
          width: 200,
          height: 200,
          child: TreeView(
            shrinkWrap: true,
            controller: _treeViewController,
            allowParentSelect: true,
            supportParentDoubleTap: false,
            theme: treeViewTheme,
            onExpansionChanged: (key, expanded) {
              Node? node = _treeViewController.getNode(key);
              if (node!=null) {
                if (visited.contains(key)) {
                  var updated = _treeViewController.updateNode(key, node.copyWith(expanded: expanded));
                  setState(() {
                    _treeViewController = _treeViewController.copyWith(children: updated);
                  });
                } else {
                  bdwmGetCollections(path: key)
                  .then((value) {
                    if (value.success==false) {
                      return;
                    }
                    for (var c in value.collections) {
                      if (c.isdir == false) {
                        continue;
                      }
                      _treeViewController = _treeViewController.withAddNode(key, Node(key: "$key/${c.path}", label: c.title, parent: true, expanded: false));
                    }
                    visited.add(key);
                    setState(() {
                      _treeViewController = _treeViewController;
                    });
                  });
                }
              }
            },
            onNodeTap: ((key) {
              setState(() {
                _selectedNode = key;
                _treeViewController = _treeViewController.copyWith(selectedKey: key);
              });
            }),
          ),
        );
      }),
    );
  }
}