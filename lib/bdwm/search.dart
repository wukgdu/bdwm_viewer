import 'dart:convert';

import './req.dart';
import '../globalvars.dart';

class IDandName {
  String id;
  String name;
  IDandName({
    required this.id,
    required this.name,
  });
}

class TopSearchRes {
  bool success = false;
  int error = 0;
  String jsonStr = "";
  List<IDandName> users = <IDandName>[];
  List<IDandName> boards = <IDandName>[];
  String? desc;

  TopSearchRes({
    required this.success,
    required this.error,
    required this.jsonStr,
    required this.users,
    required this.boards,
  });
  TopSearchRes.error({
    required this.success,
    required this.error,
    required this.desc,
  });
}

Future<TopSearchRes> bdwmTopSearch(String pref) async {
  var actionUrl = "$v2Host/ajax/get_topsearch.php";
  var data = {
    'pref': pref,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return TopSearchRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  var users = <IDandName>[];
  var boards = <IDandName>[];
  if (content['success'] == true) {
    for (var u in content['users']) {
      users.add(IDandName(id: u['id'].toString(), name: u['username']));
    }
    for (var u in content['boards']) {
      boards.add(IDandName(id: u['id'].toString(), name: u['name']));
    }
  }
  TopSearchRes topSearchRes = TopSearchRes(
    success: content['success'],
    error: content['error'] ?? 0,
    jsonStr: resp.body,
    users: users,
    boards: boards,
  );
  return topSearchRes;
}

class UserInfoRes {
  bool success = false;
  int error = 0;
  String jsonStr = "";
  List users = [];
  String? desc;

  UserInfoRes({
    required this.success,
    required this.error,
    required this.jsonStr,
    required this.users,
  });
  UserInfoRes.error({
    required this.success,
    required this.error,
    required this.desc,
  });
}

Future<String?> bdwmUserNameToUID(String userName) async {
  var userRes = await bdwmUserInfoSearch([userName]);
  if (userRes.success == true) {
    var r = userRes.users[0];
    // only one result
    if (r == false) {
      return null;
    }
    return (r as IDandName).id;
  }
  return null;
}

Future<UserInfoRes> bdwmUserInfoSearch(List<String> userNames) async {
  var actionUrl = "$v2Host/ajax/get_userinfo_by_names.php";
  var data = {
    'names': jsonEncode(userNames),
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return UserInfoRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  var users = [];
  if (content['success'] == true) {
    for (var u in content['result']) {
      if (u is bool) {
        // false
        users.add(u);
      } else {
        users.add(IDandName(id: u['id'].toString(), name: u['username']));
      }
    }
  }
  UserInfoRes res = UserInfoRes(
    success: content['success'],
    error: content['error'] ?? 0,
    jsonStr: resp.body,
    users: users,
  );
  return res;
}

Future<UserInfoRes> bdwmGetFriends() async {
  var actionUrl = "$v2Host/ajax/get_friends.php";
  var data = {};
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return UserInfoRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  var users = [];
  if (content['success'] == true) {
    for (var u in content['result']) {
      if (u['uinfo'] != null) {
        Map uinfo = u['uinfo'];
        String uid = uinfo['id']?.toString() ?? "";
        String userName = uinfo['username'] ?? "";
        users.add(IDandName(id: uid, name: userName));
      }
    }
  }
  UserInfoRes res = UserInfoRes(
    success: content['success'],
    error: content['error'] ?? 0,
    jsonStr: resp.body,
    users: users,
  );
  return res;
}

class PostInfoResItem {
  String owner = "";
  int ip = 0;
  int threadid = -1;
  int postid = -1;
  PostInfoResItem({
    required this.owner,
    required this.ip,
    required this.threadid,
    required this.postid,
  });
}

class NumToPostInfoRes {
  bool success = false;
  int error = 0;
  List<PostInfoResItem> postInfoItem = [];
  String? errorMessage;
  NumToPostInfoRes({
    required this.success,
    required this.error,
    required this.postInfoItem,
    this.errorMessage,
  });
  NumToPostInfoRes.error({
    required this.success,
    required this.error,
    this.errorMessage,
  });
}

Future<NumToPostInfoRes> bdwmGetPostByNum({required String bid, required String num}) async {
  var actionUrl = "$v2Host/ajax/get_post_by_num.php";
  var data = {
    'bid': bid,
    'num': num,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return NumToPostInfoRes.error(success: false, error: -1, errorMessage: networkErrorText);
  }
  var content = json.decode(resp.body);
  var posts = <PostInfoResItem>[];
  if (content['success'] == true) {
    for (var p in content['list']) {
      String owner = p['owner'];
      int ip = p['ip'] ?? 0;
      int threadid = p['threadid'];
      int postid = p['postid'];
      posts.add(PostInfoResItem(owner: owner, ip: ip, threadid: threadid, postid: postid));
    }
  }
  var res = NumToPostInfoRes(
    success: content['success'],
    error: content['error'] ?? 0,
    postInfoItem: posts,
  );
  return res;
}
