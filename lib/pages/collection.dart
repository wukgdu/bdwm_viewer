import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../bdwm/collection.dart' show bdwmCollectionCreateDir;
import '../views/collection.dart';
import '../globalvars.dart';
import '../views/utils.dart';
import '../html_parser/collection_parser.dart';
import '../router.dart' show nv2Push;
import '../views/constants.dart' show bdwmPrimaryColor;
import '../utils.dart' show getCollectionPathFromHttp;

class CollectionCreateDirComponent extends StatefulWidget {
  final String base;
  final Function? callBack;
  const CollectionCreateDirComponent({super.key, required this.base, this.callBack});

  @override
  State<CollectionCreateDirComponent> createState() => _CollectionCreateDirComponentState();
}

class _CollectionCreateDirComponentState extends State<CollectionCreateDirComponent> {
  TextEditingController titleValue = TextEditingController();
  TextEditingController bmsValue = TextEditingController();

  @override
  void dispose() {
    titleValue.dispose();
    bmsValue.dispose();
    super.dispose();
  }

  void createDir() {
    String title = titleValue.text.trim();
    if (title.isEmpty) {
      showInformDialog(context, "创建文件夹", "名称不可为空");
      return;
    }
    String bms = bmsValue.text.trim();
    bdwmCollectionCreateDir(title: title, base: widget.base, bms: bms)
    .then((res) {
      bool success = res.success;
      if (success==true) {
        showInformDialog(context, "创建文件夹成功", "rt")
        .then((_) {
          if (widget.callBack!=null) {
            widget.callBack!();
          }
        });
      } else {
        var txt = "发生错误啦><";
        if (res.error == -1) {
          txt = res.desc ?? txt;
        } else if (res.error == 9) {
          txt = "您没有足够权限执行此操作";
        }
        showInformDialog(context, "创建文件夹失败", txt);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            icon: Icon(Icons.folder),
            hintText: '文件夹名称',
          ),
          controller: titleValue,
          autocorrect: false,
        ),
        TextFormField(
          decoration: const InputDecoration(
            icon: Icon(Icons.assignment_ind),
            hintText: '整理者（可空）',
          ),
          controller: bmsValue,
          autocorrect: false,
        ),
        const SizedBox(height: 12,),
        ElevatedButton(
          onPressed: () {
            createDir();
          },
          child: const Text("新建文件夹"),
        ),
      ],
    );
  }
}

Future<bool?> showAddCollectionMenu(BuildContext context, String base, String curName, {Function? refresh}) async {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (BuildContext contextBottom) {
      return Container(
        margin: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Center(child: SelectableText(curName, style: const TextStyle(fontWeight: FontWeight.bold),),),
            Center(child: SelectableText(base),),
            const Divider(),
            CollectionCreateDirComponent(base: base, callBack: refresh),
            const Divider(),
            ElevatedButton(
              onPressed: () {
                showInformDialog(context, "暂不支持", "以后更新");
              },
              child: const Text("新建文件"),
            ),
          ],
        ),
      );
    },
  );
}

class CollectionApp extends StatefulWidget {
  final String link;
  final String title;
  const CollectionApp({super.key, required this.link, required this.title});

  @override
  State<CollectionApp> createState() => _CollectionAppState();
}

class _CollectionAppState extends State<CollectionApp> {
  int page = 1;
  late CancelableOperation getDataCancelable;

  Future<CollectionList> getData() async {
    // return getExampleCollectionList();
    var link = widget.link;
    var url = link;
    if (page != 1) {
      url += "&page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return CollectionList.error(errorMessage: networkErrorText);
    }
    return parseCollectionList(resp.body);
  }

  void refresh() {
    if (!mounted) { return; }
    setState(() {
      page = page;
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      },);
    });
  }

  @override
  void initState() {
    super.initState();
    page = 1;
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    },);
  }

  @override
  void dispose() {
    Future.microtask(() => getDataCancelable.cancel(),);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var collectionList = snapshot.data as CollectionList;
        if (collectionList.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(
              child: Text(collectionList.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(collectionList.title),
            actions: [
              IconButton(
                onPressed: (widget.link.contains("?")) ? () {
                  var p1 = widget.link.lastIndexOf("%2F");
                  if (p1 == -1) {
                    p1 = Uri.parse(widget.link).query.lastIndexOf("/");
                  }
                  var newLink = p1 == -1 ? "$v2Host/collection.php" : widget.link.substring(0, p1);
                  nv2Push(context, '/collection', arguments: {
                    'link': newLink,
                    'title': "获取目录中",
                  });
                } : null,
                icon: const Icon(Icons.arrow_upward)
              ),
              IconButton(
                onPressed: () {
                  if (!mounted) { return; }
                  shareWithResultWrap(context, widget.link, subject: "分享个人文集");
                },
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          body: CollectionPage(collectionList: collectionList, title: collectionList.title, refresh: () { refresh(); },),
          bottomNavigationBar: BottomAppBar(
            // shape: const CircularNotchedRectangle(),
            // color: Colors.blue,
            child: IconTheme(
              data: const IconThemeData(color: Colors.redAccent),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '刷新',
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      if (!mounted) { return; }
                      refresh();
                    },
                  ),
                  IconButton(
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '上一页',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: page <= 1 ? null : () {
                      if (!mounted) { return; }
                      setState(() {
                        page = page - 1;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                        },);
                      });
                    },
                  ),
                  TextButton(
                    child: Text("$page/${collectionList.maxPage}"),
                    onPressed: () async {
                      var nPageStr = await showPageDialog(context, page, collectionList.maxPage);
                      if (nPageStr == null) { return; }
                      if (nPageStr.isEmpty) { return; }
                      var nPage = int.parse(nPageStr);
                      if (!mounted) { return; }
                      setState(() {
                        page = nPage;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                          debugPrint("cancel it");
                        },);
                      });
                    },
                  ),
                  IconButton(
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '下一页',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: page >= collectionList.maxPage ? null : () {
                      // if (page == threadPageInfo.pageNum) {
                      //   return;
                      // }
                      if (!mounted) { return; }
                      setState(() {
                        page = page + 1;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                        },);
                      });
                    },
                  ),
                  IconButton(
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '新建',
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      var path = getCollectionPathFromHttp(widget.link);
                      if (path == null) { return; }
                      showAddCollectionMenu(context, path, collectionList.title, refresh: () { refresh(); });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CollectionArticleApp extends StatefulWidget {
  final String link;
  final String title;
  const CollectionArticleApp({super.key, required this.link, required this.title});

  @override
  State<CollectionArticleApp> createState() => _CollectionArticleAppState();
}

class _CollectionArticleAppState extends State<CollectionArticleApp> {
  late CancelableOperation getDataCancelable;

  Future<CollectionArticle> getData() async {
    // return getExampleCollectionArticle();
    var link = widget.link;
    var url = link;
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return CollectionArticle.error(errorMessage: networkErrorText);
    }
    return parseCollectionArticle(resp.body);
  }

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    },);
  }

  @override
  void dispose() {
    Future.microtask(() => getDataCancelable.cancel(),);
    super.dispose();
  }

  void refresh() {
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      },);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var collectionArticle = snapshot.data as CollectionArticle;
        if (collectionArticle.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(
              child: Text(collectionArticle.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                onPressed: () {
                  var p1 = widget.link.lastIndexOf("%2F");
                  if (p1 == -1) {
                    p1 = widget.link.lastIndexOf("/");
                  }
                  if (p1 == -1) {
                    return;
                  }
                  var newLink = widget.link.substring(0, p1);
                  newLink = newLink.replaceFirst("collection-read.php", "collection.php");
                  nv2Push(context, '/collection', arguments: {
                    'link': newLink,
                    'title': "获取目录中",
                  });
                },
                icon: const Icon(Icons.arrow_upward)
              ),
              IconButton(
                onPressed: () {
                  if (!mounted) { return; }
                  shareWithResultWrap(context, widget.link, subject: "分享个人文集");
                },
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          body: CollectionArticlePage(collectionArticle: collectionArticle, refreshCallBack: () { refresh(); },),
        );
      },
    );
  }
}
