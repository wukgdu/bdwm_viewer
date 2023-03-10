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
  String nickName = "";
  int birthYear = 1970;
  int birthMonth = 1;
  int birthDay = 1;
  String gender = "M";
  bool hideHoroscope = false;
  bool hideGender = false;
  String desc = "";
  SelfProfileRankSysInfo selfProfileRankSysInfo = SelfProfileRankSysInfo.empty();

  SelfProfileInfo.empty();
  SelfProfileInfo.error({
    required this.errorMessage,
  });
  SelfProfileInfo({
    required this.nickName,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
    required this.gender,
    required this.hideHoroscope,
    required this.hideGender,
    required this.desc,
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
  String nickName = "", gender = "M", desc = "";
  int birthYear = 1970, birthMonth = 1, birthDay = 1;
  bool hideHoroscope = false, hideGender = false;

  var nickNameDom = mainBlockDom.querySelector("input[name=nickname]");
  nickName = nickNameDom?.attributes['value'] ?? nickName;
  var genderDom = mainBlockDom.querySelectorAll("input[name=gender]");
  for (var itemDom in genderDom) {
    if (itemDom.attributes.containsKey("checked")) {
      gender = itemDom.attributes["value"] ?? gender;
      break;
    }
  }

  var hideGenderDom = mainBlockDom.querySelector("input[name=hide_gender]");
  hideGender = hideGenderDom?.attributes.containsKey("checked") ?? hideGender;
  var hideHoroscopeDom = mainBlockDom.querySelector("input[name=hide_horoscope]");
  hideHoroscope = hideHoroscopeDom?.attributes.containsKey("checked") ?? hideHoroscope;

  var birthYearDom = mainBlockDom.querySelector("input[name=birthyear]");
  birthYear = int.tryParse(birthYearDom?.attributes['value'] ?? "") ?? birthYear;
  var birthMonthDom = mainBlockDom.querySelector("input[name=birthmonth]");
  birthMonth = int.tryParse(birthMonthDom?.attributes['value'] ?? "") ?? birthMonth;
  var birthDayDom = mainBlockDom.querySelector("input[name=birthday]");
  birthDay = int.tryParse(birthDayDom?.attributes['value'] ?? "") ?? birthDay;

  var descDom = mainBlockDom.querySelector("#desc-origin");
  desc = getTrimmedHtml(descDom);

  return SelfProfileInfo(
    nickName: nickName, gender: gender, desc: desc,
    birthYear: birthYear, birthMonth: birthMonth, birthDay: birthDay,
    hideHoroscope: hideHoroscope, hideGender: hideGender,
    selfProfileRankSysInfo: selfProfileRankSysInfo
  );
}
