import 'package:html/parser.dart' show parse;

import './utils.dart';

class SelfProfileRankSysInfo {
  String selected = "";
  List<String> names = [];
  List<String> values = [];
  List<List<String>> rankSysDesc = [];

  SelfProfileRankSysInfo.empty();
  SelfProfileRankSysInfo({
    required this.selected,
    required this.names,
    required this.values,
    required this.rankSysDesc,
  });
}

class SelfProfileInfo {
  String? errorMessage;
  SelfProfileRankSysInfo selfProfileRankSysInfo = SelfProfileRankSysInfo.empty();

  SelfProfileInfo.empty();
  SelfProfileInfo.error({
    required this.errorMessage,
  });
  SelfProfileInfo({
    required this.selfProfileRankSysInfo,
  });
}

SelfProfileInfo parseSelfProfile(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return SelfProfileInfo.error(errorMessage: errorMessage);
  }
  var mainBlockDom = document.querySelector(".main-block");
  if (mainBlockDom == null) {
    return SelfProfileInfo.empty();
  }
  var rankSysSelectDom = mainBlockDom.querySelector(".cs-select");
  var selfProfileRankSysInfo = SelfProfileRankSysInfo.empty();
  if (rankSysSelectDom != null) {
    var rankSysOptionsDom = rankSysSelectDom.querySelectorAll("option");
    for (var item in rankSysOptionsDom) {
      final value = item.attributes['value'] ?? "";
      final name = getTrimmedString(item);
      if (item.attributes.containsKey("selected")) {
        selfProfileRankSysInfo.selected = value;
      }
      final rankDesc = item.attributes['data-desc'] ?? "";
      selfProfileRankSysInfo.names.add(name);
      selfProfileRankSysInfo.values.add(value);
      selfProfileRankSysInfo.rankSysDesc.add(rankDesc.split(" » "));
    }
  }
  return SelfProfileInfo(selfProfileRankSysInfo: selfProfileRankSysInfo);
}
