import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

import '../bdwm/collection.dart';
import '../html_parser/collection_parser.dart';
import './constants.dart';
import '../globalvars.dart' show globalConfigInfo;
import './utils.dart' show showConfirmDialog, showInformDialog, showAlertDialog;
import './read_thread.dart' show AttachmentComponent;
import './html_widget.dart';
import '../router.dart' show nv2Push;

class CollectionPage extends StatefulWidget {
  final CollectionList collectionList;
  final String title;
  const CollectionPage({super.key, required this.collectionList, required this.title});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget oneItem(CollectionItem item) {
    return Card(
      child: ListTile(
        onTap: () {
          if (item.type == "dir") {
            nv2Push(context, '/collection', arguments: {
              'link': item.link,
              'title': widget.title,
            });
          } else if (item.type == "file") {
            nv2Push(context, '/collectionArticle', arguments: {
              'link': item.link,
              'title': widget.title,
            });
          } else if (item.type == "link_dir") {
            nv2Push(context, '/collection', arguments: {
              'link': item.link,
              'title': widget.title,
            });
          } else if (item.type == "link_file") {
            nv2Push(context, '/collectionArticle', arguments: {
              'link': item.link,
              'title': widget.title,
            });
          }
        },
        leading: item.type.contains("dir") ? const Icon(Icons.folder) : const Icon(Icons.article),
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
      controller: _controller,
      children: widget.collectionList.collectionItems.map((e) {
        return oneItem(e);
      }).toList(),
    );
  }
}

class CollectionArticlePage extends StatefulWidget {
  final CollectionArticle collectionArticle;
  final Function refreshCallBack;
  const CollectionArticlePage({super.key, required this.collectionArticle, required this.refreshCallBack});

  @override
  State<CollectionArticlePage> createState() => _CollectionArticlePageState();
}

class _CollectionArticlePageState extends State<CollectionArticlePage> {
  final _contentFont = TextStyle(fontSize: globalConfigInfo.contentFontSize, fontWeight: FontWeight.normal);
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
                nv2Push(context, '/user', arguments: widget.collectionArticle.uid);
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
            child: HtmlComponent(widget.collectionArticle.content, ts: _contentFont,),
          ),
        ),
        if (widget.collectionArticle.attachmentInfo.isNotEmpty)
          Card(
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: AttachmentComponent(attachments: widget.collectionArticle.attachmentInfo,),
            ),
          ),
        Wrap(
          children: [
            if (widget.collectionArticle.canDelete)
              TextButton(
                onPressed: () {
                  showConfirmDialog(context, "文集", "确认删除？").then((value) {
                    if (value==null) { return; }
                    if (value.isEmpty) { return; }
                    if (value == "yes") {
                      bdwmOperateCollection(action: "delete", path: widget.collectionArticle.path)
                      .then((CollectionImportRes res) {
                        var title = "文集";
                        var content = "删除成功";
                        if (!res.success) {
                          content = "删除失败";
                          if (res.error == -1) {
                            content = res.desc!;
                          }
                        }
                        showInformDialog(context, title, content).then((value2) {
                          if (res.success) {
                            widget.refreshCallBack();
                          }
                        });
                      });
                    }
                  });
                },
                child: const Text("删除"),
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
                  bdwmOperateCollection(action: "copy", path: widget.collectionArticle.path, tobase: value)
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
                    showInformDialog(context, "收入文集", txt,);
                  });
                },);
              },
              child: const Text("收入文集"),
            ),
          ],
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
  String selectedNode = "";
  Set<String> visited = {};

  Future<CollectionRes> getData({String? path}) async {
    var res = await bdwmGetCollections(path: path);
    return res;
  }

  @override
  void initState() {
    super.initState();
    selectedNode = "";
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    });
  }

  @override
  void dispose() {
    // _treeVieweController.dispose();
    visited.clear();
    getDataCancelable.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TreeViewTheme treeViewTheme = TreeViewTheme(
      expanderTheme: const ExpanderThemeData(
        type: ExpanderType.plusMinus,
        // modifier: ExpanderModifier.circleFilled,
        // position: ExpanderPosition.end,
        // color: Colors.grey.shade800,
        size: 20,
        animated: false,
        color: bdwmPrimaryColor,
      ),
      labelStyle: const TextStyle(
        fontSize: 16,
        letterSpacing: 0.3,
      ),
      parentLabelStyle: const TextStyle(
        fontSize: 16,
        letterSpacing: 0.1,
        fontWeight: FontWeight.normal,
        // color: Colors.blue.shade700
      ),
      iconTheme: const IconThemeData(
        size: 18,
        // color: Colors.grey.shade800,
      ),
      colorScheme: Theme.of(context).colorScheme,
    );

    final dSize = MediaQuery.of(context).size;
    final dWidth = dSize.width;
    final dHeight = dSize.height;
    return SizedBox(
      width: min(260, dWidth*0.8),
      height: min(300, dHeight*0.8),
      child: FutureBuilder(
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
          return TreeView(
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
                      var newKey = "$key/${c.path}";
                      if (c.islink) {
                        newKey = c.path;
                      }
                      _treeViewController = _treeViewController.withAddNode(key, Node(key: newKey, label: c.title, parent: true, expanded: false));
                    }
                    visited.add(key);
                    setState(() {
                      Node? node2 = _treeViewController.getNode(key);
                      if (node2==null) {
                        return;
                      }
                      _treeViewController = _treeViewController.withUpdateNode(key, node2.copyWith(expanded: expanded));
                    });
                  });
                }
              }
            },
            onNodeTap: ((key) {
              setState(() {
                selectedNode = key;
                _treeViewController = _treeViewController.copyWith(selectedKey: selectedNode);
              });
            }),
          );
        }),
      ),
    );
  }
}

Future<String?> showCollectionDialog(BuildContext context, {bool? isSingle=false}) {
  var key = GlobalKey<_CollectionImportDialogBodyState>();
  return showAlertDialog(context, "选择文集", CollectionImportDialogBody(key: key,),
    actions1: TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text("不了"),
    ),
    actions2: (isSingle!=null&&isSingle==true)
    ? TextButton(
      onPressed: () {
        Navigator.of(context).pop(key.currentState?.selectedNode ?? 'none');
      },
      child: const Text("收入"),
    )
    : TextButton(
      onPressed: () {
        Navigator.of(context).pop("post ${key.currentState?.selectedNode ?? 'none'}");
      },
      child: const Text("单帖"),
    ),
    actions3: (isSingle!=null&&isSingle==true)
    ? null
    : TextButton(
      onPressed: () {
        Navigator.of(context).pop("thread ${key.currentState?.selectedNode ?? 'none'}");
      },
      child: const Text("同主题"),
    ),
  );
}