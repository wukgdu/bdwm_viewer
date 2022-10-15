import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../views/collection.dart';
import '../globalvars.dart';
import '../views/utils.dart';
import '../html_parser/collection_parser.dart';
import '../router.dart' show nv2Push;
import '../views/constants.dart' show bdwmPrimaryColor;

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
                    'title': "获取父目录中",
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
          body: CollectionPage(collectionList: collectionList, title: collectionList.title),
          bottomNavigationBar: BottomAppBar(
            shape: null,
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
                    'title': "获取父目录中",
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
