import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../views/collection.dart';
import '../globalvars.dart';
import '../views/utils.dart';
import '../html_parser/collection_parser.dart';

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
          return Text("错误：${snapshot.error}");
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text("错误：未获取数据");
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
            title: Text(widget.title),
          ),
          body: CollectionPage(collectionList: collectionList, title: widget.title),
          bottomNavigationBar: BottomAppBar(
            shape: null,
            // color: Colors.blue,
            child: IconTheme(
              data: const IconThemeData(color: Colors.redAccent),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
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
                      setState(() {
                        page = nPage;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                          debugPrint("cancel it");
                        },);
                      });
                    },
                  ),
                  IconButton(
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
          return Text("错误：${snapshot.error}");
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text("错误：未获取数据");
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
          ),
          body: CollectionArticlePage(collectionArticle: collectionArticle),
        );
      },
    );
  }
}
