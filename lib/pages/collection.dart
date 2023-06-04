import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../bdwm/collection.dart' show bdwmCollectionCreateDir, bdwmCollectionSetGood;
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
  final bool canCreateDir;
  const CollectionCreateDirComponent({super.key, required this.base, this.callBack, required this.canCreateDir});

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
          Navigator.of(context).pop();
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
          onPressed: !widget.canCreateDir ? null : () {
            createDir();
          },
          child: const Text("新建文件夹"),
        ),
      ],
    );
  }
}

class CollectionCreateComponent extends StatelessWidget {
  final String curName;
  final String base;
  final Function? refresh;
  final bool canCreateDir;
  final bool canCreateFile;
  const CollectionCreateComponent({
    super.key, required this.curName, required this.base,
    this.refresh, required this.canCreateDir, required this.canCreateFile,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actions: null,
      title: const Text("新建"),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(child: SelectableText(curName, style: const TextStyle(fontWeight: FontWeight.bold),),),
          Center(child: SelectableText(base),),
          const Divider(),
          CollectionCreateDirComponent(base: base, callBack: refresh, canCreateDir: canCreateDir),
          const Divider(),
          ElevatedButton(
            onPressed: !canCreateFile ? null : () {
              Navigator.of(context).pop();
              nv2Push(context, '/collectionNew', arguments: {
                'mode': "new",
                'title': curName,
                'baseOrPath': base,
              });
            },
            child: const Text("新建文件"),
          ),
        ],
      ),
    );
  }
}

class CollectionPage extends StatefulWidget {
  final String link;
  final String title;
  const CollectionPage({super.key, required this.link, required this.title});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
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
                onPressed: () async {
                  var path = getCollectionPathFromHttp(widget.link);
                  if (path == null) { return; }
                  var res = await bdwmCollectionSetGood(action: "add", paths: [path]);
                  if (!mounted) { return; }
                  bool success = res.success;
                  var txt = "收藏成功";
                  if (success==false) {
                    txt = res.errorMessage ?? "收藏失败";
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(txt), duration: const Duration(milliseconds: 600),),
                  );
                },
                icon: const Icon(Icons.star_border_rounded),
              ),
              IconButton(
                onPressed: (widget.link.contains("?")) ? () {
                  var newLink = "$v2Host/collection.php";
                  var queryStr = Uri.parse(widget.link).query;
                  if (queryStr.contains("/") || queryStr.contains("%2F")) {
                    var p1 = widget.link.lastIndexOf("%2F");
                    if (p1 == -1) {
                      p1 = widget.link.lastIndexOf("/");
                    }
                    if (p1 != -1) {
                      newLink = widget.link.substring(0, p1);
                    }
                  }
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
          body: CollectionView(collectionList: collectionList, title: collectionList.title, refresh: () { refresh(); },),
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
                    onPressed: !(collectionList.canCreateDir || collectionList.canCreateFile) ? null : () {
                      var path = getCollectionPathFromHttp(widget.link);
                      if (path == null) { return; }
                      showAlertDialog2(
                        context,
                        CollectionCreateComponent(
                          curName: collectionList.title, base: path, refresh: () { refresh(); },
                          canCreateDir: collectionList.canCreateDir, canCreateFile: collectionList.canCreateFile,
                        ),
                      );
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

class CollectionArticlePage extends StatefulWidget {
  final String link;
  final String title;
  const CollectionArticlePage({super.key, required this.link, required this.title});

  @override
  State<CollectionArticlePage> createState() => _CollectionArticlePageState();
}

class _CollectionArticlePageState extends State<CollectionArticlePage> {
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
          body: CollectionArticleView(collectionArticle: collectionArticle, refreshCallBack: () { refresh(); }, title: widget.title),
        );
      },
    );
  }
}
