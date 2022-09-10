import 'package:html/parser.dart' show parse;

import '../globalvars.dart' show defaultAvator;
import './utils.dart';

class FriendInfo {
  String uid = "";
  bool bidirection = false;
  String userName = "";
  String nickName = "";
  String avatar = "";
  String onlineStatus = "";

  FriendInfo.empty();
  FriendInfo({
    required this.uid,
    required this.bidirection,
    required this.userName,
    required this.nickName,
    required this.avatar,
    required this.onlineStatus,
  });
}

class FriendsInfo {
  String? errorMessage;
  List<FriendInfo> friends = [];
  
  FriendsInfo.error({
    required this.errorMessage,
  });
  FriendsInfo.empty();
  FriendsInfo({
    required this.friends,
  });
}

FriendsInfo parseFriends(String htmlStr) {
  var document = parse(htmlStr);
  var errorMessage = checkError(document);
  if (errorMessage != null) {
    return FriendsInfo.error(errorMessage: errorMessage);
  }
  var listDom = document.querySelector(".friend-list");
  if (listDom == null) {
    return FriendsInfo.empty();
  }
  var friends = <FriendInfo>[];
  for (var fc in listDom.querySelectorAll(".friend-card")) {
    var uid = fc.attributes["data-friend-id"] ?? "";
    var src = fc.querySelector(".avatar img")?.attributes['src'] ?? defaultAvator;
    var avatar = absImgSrc(src);
    var bidirection = false;
    if (fc.querySelector("div.friend") != null) {
      bidirection = true;
    }
    var userName = "";
    var onlineStatus = "";
    var userIDDom = fc.querySelector(".user-id");
    if (userIDDom != null) {
      userName = getTrimmedString(userIDDom.querySelector("span"));
      onlineStatus = getTrimmedString(userIDDom.querySelector("span.status"));
    }
    var nickName = getTrimmedString(fc.querySelector(".nickname"));
    friends.add(FriendInfo(uid: uid, bidirection: bidirection, userName: userName, nickName: nickName, avatar: avatar, onlineStatus: onlineStatus));
  }
  return FriendsInfo(friends: friends);
}