import 'dart:io';

import 'package:html/parser.dart' show parse;

import '../globalvars.dart';
import './utils.dart';
import '../utils.dart';

class UserProfile {
  String bbsID = "";
  String nickName = "";
  String nickNameHtml = "";
  String status = "";
  String avatarLink = absImgSrc(defaultAvator);
  String avatarFrameLink = "";
  TextAndLink personalCollection = TextAndLink.empty();
  String gender = "保密";
  String constellation = "保密";
  String countLogin = "";
  String countPost = "";
  String value = ""; // 生命力
  String score = ""; // 积分
  String rankName = "";
  String rating = ""; // 原创分
  String recentLogin = "";
  String recentLogout = "";
  String? timeReg;
  String? timeOnline;
  String signature = "";
  String signatureHtml = "";
  String? duty;
  List<String>? dutyBoards;
  List<String>? dutyBoardLinks;
  String? errorMessage;

  UserProfile();
  UserProfile.error({required this.errorMessage});

  UserProfile.init({
    required this.bbsID,
    required this.nickName,
    required this.nickNameHtml,
    required this.status,
    required this.avatarLink,
    required this.avatarFrameLink,
    required this.personalCollection,
    required this.gender,
    required this.constellation,
    required this.countLogin,
    required this.countPost,
    required this.value,
    required this.score,
    required this.rankName,
    required this.rating,
    required this.recentLogin,
    required this.recentLogout,
    this.timeReg,
    this.timeOnline,
    required this.signature,
    required this.signatureHtml,
    this.duty,
    this.dutyBoards,
    this.dutyBoardLinks,
    this.errorMessage,
  });

  @override
  String toString() {
    return "$bbsID($nickName): ${personalCollection.text}";
  }
}

UserProfile parseUser(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return UserProfile.error(errorMessage: errorMessage);
  }
  var basicInfo = document.querySelector('.basic-info');
  var nickInfo = basicInfo?.querySelector('.nick');
  if (basicInfo == null || nickInfo == null) {
    return UserProfile();
  }
  var bbsID = getTrimmedString(nickInfo.querySelector(".bbsid"));
  var nickName = getTrimmedString(nickInfo.querySelector(".nickname"));
  var status = getTrimmedString(nickInfo.querySelector(".status"));
  var avatarLink = absImgSrc(basicInfo.querySelector(".portrait")?.attributes['src'] ?? defaultAvator);
  var afl = basicInfo.querySelector(".avatar-frame")?.attributes['src'];
  var avatarFrameLink = afl == null ? "" : absImgSrc(afl);
  var personalCollection = getTrimmedString(nickInfo.querySelector(".personal-collection"));
  var tmpDutyDom = nickInfo.querySelector(".personal-duty");
  String? duty;
  if (tmpDutyDom != null) {
    duty = getTrimmedString(tmpDutyDom);
  }

  String? personalCollectionLink;
  var tmpPCLink = nickInfo.querySelector(".link");
  if (tmpPCLink != null) {
    personalCollectionLink = absThreadLink(tmpPCLink.attributes['href'] ?? "");
    personalCollection = getTrimmedString(tmpPCLink);
  }

  var profileDom = document.querySelector('.profile');
  if (profileDom == null) {
    return UserProfile();
  }

  String gender = "";
  String constellation = "";
  String countLogin = "";
  String countPost = "";
  String value = "";
  String score = "";
  String rankName = "";
  String rating = "";
  String recentLogin = "";
  String recentLogout = "";
  String nickNameHtml = "";
  String? timeReg;
  String? timeOnline;
  for (var divDom in profileDom.querySelectorAll(".table-layout div")) {
    if (getTrimmedString(divDom.querySelector("label")).startsWith("昵称")) {
      nickNameHtml = getTrimmedHtml(divDom);
      var nickIdx = nickNameHtml.indexOf("</label>");
      if (nickIdx != -1) {
        nickNameHtml = nickNameHtml.substring(nickIdx+8).trim();
      }
    }
    var divText = getTrimmedString(divDom);
    List<String> pairText = divText.split("：").map((e) => e.trim()).toList();
    switch (pairText[0]) {
      case "性别": gender = pairText[1]; break;
      case "星座": constellation = pairText[1]; break;
      case "上站次数": countLogin = pairText[1]; break;
      case "发帖数": countPost = pairText[1]; break;
      case "生命力": value = pairText[1]; break;
      case "积分": score = pairText[1]; break;
      case "等级": rankName = pairText[1]; break;
      case "原创分": rating = pairText[1]; break;
      case "最近上站时间": recentLogin = pairText[1]; break;
      case "最近离站时间": recentLogout = pairText[1]; break;
      case "注册时间": timeReg = pairText[1]; break;
      case "在线总时长": timeOnline = pairText[1]; break;
    }
  }

  String signature = "";
  String signatureHtml = "";
  var sigDom = profileDom.querySelector(".signature");
  if (sigDom != null) {
    signature = getTrimmedString(sigDom);
    signatureHtml = getTrimmedHtml(sigDom);
  }

  List<String>? dutyBoards;
  List<String>? dutyBoardLinks;
  var boardsDom = profileDom.querySelectorAll(".link");
  if (boardsDom.isNotEmpty) {
    dutyBoards = <String>[];
    dutyBoardLinks = <String>[];
    for (var dom in boardsDom) {
      dutyBoards.add(getTrimmedString(dom));
      dutyBoardLinks.add(absThreadLink(dom.attributes['href'] ?? ''));
    }
  }

  return UserProfile.init(
    bbsID: bbsID, nickName: nickName, status: status, avatarLink: avatarLink, nickNameHtml: nickNameHtml,
    personalCollection: TextAndLink(personalCollection, personalCollectionLink), gender: gender, constellation: constellation,
    countLogin: countLogin, countPost: countPost, value: value, score: score, rankName: rankName, avatarFrameLink: avatarFrameLink,
    rating: rating, recentLogin: recentLogin, recentLogout: recentLogout, signature: signature, signatureHtml: signatureHtml,
    timeReg: timeReg, timeOnline: timeOnline, duty: duty, dutyBoards: dutyBoards, dutyBoardLinks: dutyBoardLinks,
  );
}

UserProfile getExampleUser() {
  const filename = '../useraho.html';
  var htmlStr = File(filename).readAsStringSync();
  final items = parseUser(htmlStr);
  return items;
}
