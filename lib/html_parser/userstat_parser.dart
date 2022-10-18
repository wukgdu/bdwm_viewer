import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' show Element;

import './utils.dart' show checkError;

class TVPair {
  String time = "";
  int value = 0;
  TVPair.empty();
  TVPair({
    required this.time,
    required this.value,
  });
}

class TableOneInfo {
  String title = "";
  List<TVPair> value = [];
  TableOneInfo.empty();
  TableOneInfo({
    required this.title,
    required this.value,
  });
}

class TableDataInfo {
  List<TableOneInfo> tables = [];
  String? errorMessage;
  TableDataInfo.empty();
  TableDataInfo({
    required this.tables,
  });
  TableDataInfo.error({
    required this.errorMessage,
  });
}

List<TableOneInfo> getOneTable(Element tableNode) {
  var thead = tableNode.querySelector("thead");
  if (thead == null) { return []; }
  var tbody = tableNode.querySelector("tbody");
  if (tbody == null) { return []; }
  var trows = tbody.querySelectorAll("tr");
  if (trows.isEmpty) { return []; }
  var tseekStr = tbody.querySelector("tr th")?.attributes["rowspan"];
  var tseek = 1;
  if (tseekStr != null) {
    tseek = int.parse(tseekStr);
  }
  var trNodes = trows;
  var trNodesYears = <List<Element>>[];
  for (var i=0; i<trNodes.length; i+=tseek) {
    var trNodesYear = trNodes.sublist(i, i+tseek);
    trNodesYears.add(trNodesYear);
  }
  var data = List.generate(tseek, (_) { return TableOneInfo.empty(); });
  for (var y=0; y<trNodesYears.length; ++y) {
    var yearNodes = trNodesYears[y];
    var datumYear = int.parse(yearNodes[0].children[0].text.replaceAll("年", ""));
    for (var i=0; i<tseek; ++i) {
      var mStart = (i==0)?1:0;
      if (y==0) {
        data[i].title = yearNodes[i].children[mStart].text;
      }
      for (var m=1; m<=12; ++m) {
        var v = int.tryParse(yearNodes[i].children[m+mStart].text);
        if (v==null) { continue; }
        data[i].value.add(TVPair(time: "$datumYear-${m.toString().padLeft(2, '0')}", value: v));
      }
    }
  }
  return data;
}

TableDataInfo parseUserStat(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return TableDataInfo.error(errorMessage: errorMessage);
  }
  var tables = document.querySelectorAll(".table-stat-normal");
  var tableDataInfo = TableDataInfo.empty();
  for (var t in tables) {
    tableDataInfo.tables.addAll(getOneTable(t));
  }
  return tableDataInfo;
}
