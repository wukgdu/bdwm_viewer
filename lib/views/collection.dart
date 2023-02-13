import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

import '../bdwm/collection.dart';
import './constants.dart' show bdwmPrimaryColor;
import '../html_parser/collection_parser.dart';
import '../utils.dart' show getQueryValue;
import '../globalvars.dart' show globalConfigInfo;
import './utils.dart' show showConfirmDialog, showInformDialog, showAlertDialog, showPageDialog;
import './read_thread.dart' show AttachmentComponent;
import './html_widget.dart';
import '../router.dart' show nv2Push;

void deleteCollectionWrap(String path, BuildContext context, Function refreshCallBack) {
  showConfirmDialog(context, "文集", "确认删除？").then((value) {
    if (value==null) { return; }
    if (value.isEmpty) { return; }
    if (value == "yes") {
      bdwmOperateCollection(action: "delete", path: path)
      .then((CollectionImportRes res) {
        var title = "文集";
        var content = "删除成功";
        if (!res.success) {
          content = "删除失败";
          if (res.error == -1) {
            content = "删除失败：${res.desc}";
          }
        }
        showInformDialog(context, title, content).then((value2) {
          if (res.success) {
            refreshCallBack();
          }
        });
      });
    }
  });
}

void reorderCollectionWrap(String httpPath, int index, BuildContext context, {Function? refreshCallBack}) {
  var path = getQueryValue(httpPath, 'path');
  if (path == null) {
    showInformDialog(context, "移动失败", "未找到路径");
    return;
  }
  path = path.replaceAll('%2F', '/');
  bdwmOperateCollection(action: "movepos", path: path, pos: index.toString())
  .then((CollectionImportRes res) {
    var title = "文集";
    var content = "移动成功";
    if (!res.success) {
      content = "移动失败";
      if (res.error == -1) {
        content = "移动失败：${res.desc}";
      }
      showInformDialog(context, title, content);
    } else {
      if (refreshCallBack!=null) {
        refreshCallBack();
      }
    }
  });
}

class CollectionPage extends StatefulWidget {
  final CollectionList collectionList;
  final String title;
  final Function? refresh;
  const CollectionPage({super.key, required this.collectionList, required this.title, this.refresh});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final _controller = ScrollController();
  String oPath = "";
  int oIndex = -1;
  bool inMultiSelect = false;
  Set<CollectionItem> multiSelectedPath = {};

  @override
  void dispose() {
    _controller.dispose();
    multiSelectedPath.clear();
    super.dispose();
  }

  List<String> getSelectedPath({bool onlyFile=false}) {
    var selectItems = multiSelectedPath.toList();
    selectItems.sort((a, b) { return a.id - b.id; });
    var httpPaths = selectItems.map((item) {
      if (onlyFile) {
        if (!item.type.contains("file")) {
          return "";
        }
      }
      var path = getQueryValue(item.path, 'path');
      if (path == null) {
        return "";
      }
      path = path.replaceAll('%2F', '/');
      return path;
    });
    return httpPaths.where((element) => element.isNotEmpty).toList();
  }

  void confirmAfterBatchOperation(BuildContext context, CollectionBatchRes batchRes, {String ope=""}) {
    var txt = "成功";
    bool success = false;
    if (batchRes.success != null) {
      success = batchRes.success!;
      if (batchRes.success==true) {
        txt = "成功";
      } else {
        txt = batchRes.desc ?? "失败";
      }
    } else {
      success = batchRes.results.every((element) => element == false);
      if (success) {
        txt = "成功";
      } else {
        txt = batchRes.desc ?? "不完全成功";
      }
    }
    if (success == false) {
      showInformDialog(context, "$ope操作", txt);
    } else {
      multiSelectedPath.clear();
      if (widget.refresh!=null) {
        widget.refresh!();
      }
    }
  }

  void collectionMoveOrCopy(BuildContext context, CollectionItem item, String action, String ope) {
    var path = getQueryValue(item.path, 'path');
    if (path == null) {
      showInformDialog(context, "$ope失败", "未找到路径");
      return;
    }
    path = path.replaceAll('%2F', '/');
    showCollectionDialog(context, isSingle: true)
    .then((value) {
      if (value == null || value.isEmpty) {
        return;
      }
      var base = value;
      if (base.isEmpty || base=="none") {
        return;
      }
      bdwmOperateCollection(action: action, path: path!, tobase: value)
      .then((importRes) {
        var txt = "$ope成功";
        if (importRes.success == false) {
          txt = "发生错误啦><";
          if (importRes.error == -1) {
            txt = importRes.desc ?? txt;
          } else if (importRes.error == 9) {
            txt = "您没有足够权限执行此操作";
          }
          showInformDialog(context, "$ope文集", txt,);
        } else {
          if (widget.refresh!=null) {
            widget.refresh!();
          }
        }
      });
    });
  }

  Widget oneItem(CollectionItem item, int index, {Key? key}) {
    return Card(
      key: key,
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
        onLongPress: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context1) {
              return Container(
                margin: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Center(child: SelectableText("${item.name}（位置：${item.id}）"),),
                    const Divider(),
                    ElevatedButton(
                      child: const Text('删除'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (!inMultiSelect) {
                          var path = getQueryValue(item.path, 'path');
                          if (path == null) {
                            showInformDialog(context, "删除失败", "未找到路径");
                            return;
                          }
                          path = path.replaceAll('%2F', '/');
                          deleteCollectionWrap(path, context, () {
                            widget.collectionList.collectionItems.remove(item);
                            if (widget.refresh!=null) {
                              widget.refresh!();
                            }
                          });
                        } else {
                          if (multiSelectedPath.isEmpty) { return; }
                          var paths = getSelectedPath();
                          showConfirmDialog(context, "文集", "确认删除？").then((value) {
                            if (value==null) { return; }
                            if (value.isEmpty) { return; }
                            if (value == "yes") {
                              bdwmOperateCollectionBatched(action: "delete", list: paths)
                              .then((batchRes) {
                                confirmAfterBatchOperation(context, batchRes, ope: "删除");
                              });
                            }
                          });
                        }
                      }
                    ),
                    if (!inMultiSelect) ...[
                      const Divider(),
                      ElevatedButton(
                        child: const Text('移动到其他位置'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          var nIndexStr = await showPageDialog(context, item.id, widget.collectionList.totalCount);
                          if (nIndexStr == null) { return; }
                          if (nIndexStr.isEmpty) { return; }
                          var nIndex = int.parse(nIndexStr);
                          if (!mounted) { return; }
                          reorderCollectionWrap(item.path, nIndex-1, context, refreshCallBack: () {
                            if (widget.refresh!=null) {
                              widget.refresh!();
                            }
                          });
                        }
                      ),
                    ],
                    const Divider(),
                    ElevatedButton(
                      child: const Text('移动到其他文件夹'),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        if (!inMultiSelect) {
                          collectionMoveOrCopy(context, item, "move", "移动");
                        } else {
                          if (multiSelectedPath.isEmpty) { return; }
                          var paths = getSelectedPath();
                          showCollectionDialog(context, isSingle: true)
                          .then((value) {
                            if (value == null || value.isEmpty) {
                              return;
                            }
                            var base = value;
                            if (base.isEmpty || base=="none") {
                              return;
                            }
                            bdwmOperateCollectionBatched(action: "move", list: paths, tobase: value)
                            .then((batchRes) {
                              confirmAfterBatchOperation(context, batchRes, ope: "移动");
                            });
                          });
                        }
                      }
                    ),
                    if (item.type.contains("file")) ...[
                      const Divider(),
                      ElevatedButton(
                        child: const Text("收入文集"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (!inMultiSelect) {
                            collectionMoveOrCopy(context, item, "copy", "收入文集");
                          } else {
                            if (multiSelectedPath.isEmpty) { return; }
                            var paths = getSelectedPath(onlyFile: true);
                            showConfirmDialog(context, "只有文章可收入", "共有${paths.length}个，确认收入？").then((value) {
                              if (value==null) { return; }
                              if (value.isEmpty) { return; }
                              if (value != "yes") { return; }
                              showCollectionDialog(context, isSingle: true)
                              .then((value) {
                                if (value == null || value.isEmpty) {
                                  return;
                                }
                                var base = value;
                                if (base.isEmpty || base=="none") {
                                  return;
                                }
                                bdwmOperateCollectionBatched(action: "copy", list: paths, tobase: value)
                                .then((batchRes) {
                                  confirmAfterBatchOperation(context, batchRes, ope: "收入文集");
                                });
                              });
                            });
                          }
                        }
                      ),
                    ],
                    const Divider(),
                    ElevatedButton(
                      child: Text(inMultiSelect ? '取消多选' : '多选'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          inMultiSelect = !inMultiSelect;
                          multiSelectedPath.clear();
                          if (inMultiSelect) {
                            multiSelectedPath.add(item);
                          }
                        });
                      }
                    ),
                    const Divider(),
                    ElevatedButton(
                      child: const Text('取消'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      }
                    ),
                  ],
                ),
              );
            },
          );
        },
        leading: item.type.contains("dir") ? const Icon(Icons.folder) : const Icon(Icons.article),
        trailing: inMultiSelect ? GestureDetector(
          onLongPress: () {
            if (multiSelectedPath.length != widget.collectionList.collectionItems.length) {
              multiSelectedPath.addAll(widget.collectionList.collectionItems);
            } else {
              multiSelectedPath.clear();
            }
            setState(() { });
          },
          child: Checkbox(
            activeColor: bdwmPrimaryColor,
            value: multiSelectedPath.contains(item),
            onChanged: (value) {
              if (value == null) { return; }
              if (value) {
                multiSelectedPath.add(item);
              } else {
                multiSelectedPath.remove(item);
              }
              setState(() { });
            },
          ),
        ) : ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
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
    return ReorderableListView.builder(
      scrollController: _controller,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        var e = widget.collectionList.collectionItems[index];
        return oneItem(e, index, key: Key("$index"));
      },
      itemCount: widget.collectionList.collectionItems.length,
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = widget.collectionList.collectionItems.removeAt(oldIndex);
          widget.collectionList.collectionItems.insert(newIndex, item);
        });
      },
      onReorderStart: (index) {
        oPath = widget.collectionList.collectionItems[index].path;
        oIndex = index;
      },
      onReorderEnd: (index) {
        if (oIndex < index) {
          index -= 1;
        }
        reorderCollectionWrap(oPath, index, context, refreshCallBack: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("移动成功"), duration: Duration(milliseconds: 600),),
          );
        });
      },
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
                  deleteCollectionWrap(widget.collectionArticle.path, context, widget.refreshCallBack);
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
                      txt = "发生错误啦><";
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
      expanderTheme: ExpanderThemeData(
        type: ExpanderType.plusMinus,
        // modifier: ExpanderModifier.circleFilled,
        // position: ExpanderPosition.end,
        size: 20,
        animated: false,
        // color: bdwmPrimaryColor,
        color: Colors.grey.shade800,
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