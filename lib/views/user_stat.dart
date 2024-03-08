import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:syncfusion_flutter_charts/charts.dart' show SfCartesianChart, LineSeries, DateTimeAxis, CartesianSeries, TooltipBehavior;
import 'package:intl/intl.dart' show DateFormat;

import '../globalvars.dart' show v2Host, networkErrorText, genHeaders2;
import "../bdwm/req.dart";
import '../html_parser/userstat_parser.dart';

class UserStatFutureView extends StatefulWidget {
  const UserStatFutureView({super.key});

  @override
  State<UserStatFutureView> createState() => _UserStatFutureViewState();
}

class _UserStatFutureViewState extends State<UserStatFutureView> {
  late CancelableOperation getDataCancelable;

  Future<TableDataInfo> getData() async {
    var resp = await bdwmClient.get("$v2Host/userstat.php", headers: genHeaders2());
    if (resp == null) {
      return TableDataInfo.error(errorMessage: networkErrorText);
    }
    return parseUserStat(resp.body);
  }

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
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
        TableDataInfo tableDataInfo = snapshot.data as TableDataInfo;
        if (tableDataInfo.errorMessage != null) {
          return Center(child: Text(tableDataInfo.errorMessage!),);
        }
        return UserStatView(tableDataInfo: tableDataInfo,);
      },
    );
  }
}

class UserStatTableComponent extends StatefulWidget {
  final TableOneInfo tableOneInfo;
  const UserStatTableComponent({super.key, required this.tableOneInfo});

  @override
  State<UserStatTableComponent> createState() => _UserStatTableComponentState();
}

class _UserStatTableComponentState extends State<UserStatTableComponent> {
  final tooltipBehavior = TooltipBehavior(
    enable: true,
    animationDuration: 0,
    duration: 0.0,
    builder: (data, point, series, pointIndex, seriesIndex) {
      var datum = data as TVPair;
      return Container(
        color: Colors.white,
        child: Text("${datum.time}: ${datum.value}")
      );
    },
  );
  bool showTable = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                showTable = !showTable;
              });
            },
            child: Text(widget.tableOneInfo.title),
          ),
          if (showTable) ...[
            SfCartesianChart(
              tooltipBehavior: tooltipBehavior,
              primaryXAxis: DateTimeAxis(dateFormat: DateFormat.yM()),
              series: <CartesianSeries>[
                LineSeries<TVPair, DateTime>(
                  dataSource: widget.tableOneInfo.value,
                  xValueMapper: (TVPair sales, _) => DateTime.parse("${sales.time}-01"),
                  yValueMapper: (TVPair sales, _) => sales.value,
                  animationDuration: 0.0,
                  enableTooltip: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class UserStatView extends StatelessWidget {
  final TableDataInfo tableDataInfo;
  const UserStatView({super.key, required this.tableDataInfo});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tableDataInfo.tables.length,
      itemBuilder: (context, index) {
        return UserStatTableComponent(tableOneInfo: tableDataInfo.tables[index]);
      },
    );
  }
}
