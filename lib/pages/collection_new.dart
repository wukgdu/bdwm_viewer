import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../html_parser/collectionnew_parser.dart';
import '../globalvars.dart' show genHeaders2, networkErrorText, v2Host;
import '../bdwm/req.dart' show bdwmClient;
import '../views/collection_new.dart' show CollectionNewPage;

class CollectionNewApp extends StatefulWidget {
  final String mode;
  final String baseOrPath;
  final String title;
  const CollectionNewApp({
    super.key,
    required this.mode,
    required this.baseOrPath,
    required this.title,
  });

  @override
  State<CollectionNewApp> createState() => _CollectionNewAppState();
}

class _CollectionNewAppState extends State<CollectionNewApp> {
  late CancelableOperation getDataCancelable;

  Future<CollectionNewInfo> getData() async {
    var bpKey = "base";
    if (widget.mode == "modify") {
      bpKey = "path";
    }
    var url = "$v2Host/collection-new.php?mode=${widget.mode}&$bpKey=${widget.baseOrPath}";
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return CollectionNewInfo.error(errorMessage: networkErrorText);
    }
    return parseCollectionNew(resp.body);
  }

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    },);
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: getDataCancelable.value,
        builder: (context, snapshot) {
          // debugPrint(snapshot.connectionState.toString());
          if (snapshot.connectionState != ConnectionState.done) {
            // return const Center(child: CircularProgressIndicator());
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("错误：${snapshot.error}"),);
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("错误：未获取数据"),);
          }
          CollectionNewInfo collectionNewInfo = snapshot.data as CollectionNewInfo;
          if (collectionNewInfo.errorMessage != null) {
            return Center(
              child: Text(collectionNewInfo.errorMessage!),
            );
          }
          return CollectionNewPage(mode: widget.mode, baseOrPath: widget.baseOrPath, collectionNewInfo: collectionNewInfo, baseName: widget.title,);
        }
      ),
    );
  }
}
