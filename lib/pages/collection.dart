import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../views/collection.dart';
import '../globalvars.dart';
import '../html_parser/collection_parser.dart';

class CollectionApp extends StatefulWidget {
  final String link;
  final String title;
  const CollectionApp({super.key, required this.link, required this.title});

  @override
  State<CollectionApp> createState() => _CollectionAppState();
}

class _CollectionAppState extends State<CollectionApp> {
  late CancelableOperation getDataCancelable;

  Future<CollectionList> getData() async {
    // return getExampleCollectionList();
    var link = widget.link;
    var url = link;
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    return parseCollectionList(resp.body);
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
