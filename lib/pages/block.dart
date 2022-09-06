import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../views/block.dart';
import '../globalvars.dart';
import '../html_parser/block_parser.dart';

class BlockApp extends StatefulWidget {
  final String bid;
  final String title;
  const BlockApp({super.key, required this.bid, required this.title});

  @override
  State<BlockApp> createState() => _BlockAppState();
}

class _BlockAppState extends State<BlockApp> {
  late CancelableOperation getDataCancelable;

  Future<BlockInfo> getData() async {
    // return getExampleBlockInfo();
    var url = "$v2Host/board.php?bid=${widget.bid}";
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return BlockInfo.error(errorMessage: networkErrorText);
    }
    return parseBlock(resp.body);
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
        var blockInfo = snapshot.data as BlockInfo;
        if (blockInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(
              child: Text(blockInfo.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(blockInfo.name),
          ),
          body: BlockPage(blockInfo: blockInfo, bid: widget.bid, name: blockInfo.name,),
        );
      },
    );
  }
}