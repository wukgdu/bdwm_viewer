import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../views/zone.dart';
import '../views/drawer.dart';
import '../globalvars.dart';
import '../html_parser/zone_parser.dart';

class ZoneApp extends StatefulWidget {
  final zoneDrawer = const MyDrawer(selectedIdx: 1);
  const ZoneApp({super.key});

  @override
  State<ZoneApp> createState() => _ZoneAppState();
}

class _ZoneAppState extends State<ZoneApp> {
  late CancelableOperation getDataCancelable;

  Future<ZoneInfo> getData() async {
    // return getExampleZone();
    var url = "$v2Host/zone.php";
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return ZoneInfo.error(errorMessage: networkErrorText);
    }
    return parseZone(resp.body);
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
            drawer: widget.zoneDrawer,
            appBar: AppBar(
              title: const Text("版面目录"),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            drawer: widget.zoneDrawer,
            appBar: AppBar(
              title: const Text("版面目录"),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            drawer: widget.zoneDrawer,
            appBar: AppBar(
              title: const Text("版面目录"),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var zoneInfo = snapshot.data as ZoneInfo;
        if (zoneInfo.errorMessage != null) {
          return Scaffold(
            drawer: widget.zoneDrawer,
            appBar: AppBar(
              title: const Text("版面目录"),
            ),
            body: Center(
              child: Text(zoneInfo.errorMessage!),
            ),
          );
        }
        return Scaffold(
          drawer: widget.zoneDrawer,
          appBar: AppBar(
            title: const Text("版面目录"),
          ),
          body: ZonePage(zoneInfo: zoneInfo),
        );
      },
    );
  }
}