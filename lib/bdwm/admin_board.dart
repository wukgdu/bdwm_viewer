import 'dart:convert';

import './req.dart';
import '../globalvars.dart' show v2Host, genHeaders2, networkErrorText;
import './posts.dart' show bdwmOperatePost;
import './search.dart' show bdwmUserNameToUID;
import '../utils.dart' show isIP;

class AdminBoardOperateRes {
  bool success = false;
  bool? rawSuccess;
  int error = 0;
  String? errorMessage;

  AdminBoardOperateRes({
    required this.success,
    required this.error,
    this.rawSuccess,
    this.errorMessage,
  });
  AdminBoardOperateRes.error({
    this.success = false,
    required this.error,
    this.errorMessage,
  });
}

Future<AdminBoardOperateRes> bdwmAdminBoardOperateThread({required String bid, required String threadid, required String action}) async {
  var actionUrl = "$v2Host/ajax/operate_thread.php";
  var data = {
    "bid": bid,
    "list": '[$threadid]',
    "action": action, // noreply
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return AdminBoardOperateRes.error(success: false, error: -1, errorMessage: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  var res = AdminBoardOperateRes(
    success: respContent['results'][0]==false,
    error: respContent['error'] ?? 0,
  );
  return res;
}

Future<AdminBoardOperateRes> bdwmAdminBoardCreateThreadCollect({required String bid, required String threadid}) async {
  var actionUrl = "$v2Host/ajax/create_thread_collect.php";
  var data = {
    "bid": bid,
    "threadid": threadid,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return AdminBoardOperateRes.error(success: false, error: -1, errorMessage: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  var res = AdminBoardOperateRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
  );
  return res;
}

// x = "ajax/set_board_note.php"
Future<AdminBoardOperateRes> bdwmAdminBoardOperatePost({required String bid, required String postid, required String action, int? rating}) async {
  var postRes = await bdwmOperatePost(bid: bid, postid: postid, action: action, rating: rating);
  return AdminBoardOperateRes(success: postRes.success, error: postRes.error, errorMessage: postRes.result, rawSuccess: postRes.rawSuccess);
}

Future<AdminBoardOperateRes> bdwmAdminBoardSetBoardDesc({required String bid, required String content}) async {
  var actionUrl = "$v2Host/ajax/set_board_desc.php";
  var data = {
    "bid": bid,
    "content": content,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return AdminBoardOperateRes.error(success: false, error: -1, errorMessage: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  var res = AdminBoardOperateRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
  );
  return res;
}

Future<AdminBoardOperateRes> bdwmAdminBoardBanUser({required String bid, required String action, required int day, required String reason, required String userName, String? uid, String? postid, int? reclocking}) async {
  var actionUrl = "$v2Host/ajax/set_board_denied_user.php";
  var nAction = action;
  if ((action == "add") && (userName.toLowerCase() == "anonymous") && (postid != null)) {
    nAction = "add_anony";
  }
  var data = {
    "bid": bid,
    "action": nAction,
    "reason": reason,
    "day": day.toString(),
  };
  bool userIsIP = isIP(userName);
  // add, edit
  if (userIsIP) {
    data['ip'] = userName;
  } else if (userName.toLowerCase() == "anonymous") {
    data['postid'] = postid!;
  } else {
    String? nUID = uid ?? await bdwmUserNameToUID(userName);
    if (nUID == null) {
      return AdminBoardOperateRes.error(success: false, error: 2, errorMessage: "用户$userName不存在");
    }
    data['uid'] = nUID;
  }
  if (nAction == "delete") {
    data = {
      "action": nAction,
      "bid": bid,
    };
    if (userIsIP) {
      data['ip'] = userName;
    } else {
      String? nUID = uid ?? await bdwmUserNameToUID(userName);
      if (nUID == null) {
        return AdminBoardOperateRes.error(success: false, error: 2, errorMessage: "用户$userName不存在");
      }
      data['uid'] = nUID;
    }
  } else if (nAction == "edit") {
    if (reclocking == null) {
      return AdminBoardOperateRes.error(success: false, error: 2, errorMessage: "未设置是否重新计算时间");
    }
    data['reclocking'] = reclocking.toString();
  }
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return AdminBoardOperateRes.error(success: false, error: -1, errorMessage: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  var res = AdminBoardOperateRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
  );
  return res;
}
