import 'dart:convert';

import './req.dart';
import '../globalvars.dart';

class UserRes {
  bool success = false;
  int error = 0;
  String? desc;

  UserRes({
    required this.success,
    required this.error,
  });
  UserRes.error({
    required this.success,
    required this.error,
    required this.desc,
  });
}

Future<UserRes> bdwmUsers(String uid, String action, String desc, {String? mode}) async {
  var actionUrl = "$v2Host/ajax/set_friends.php";
  var data = {
    'action': action,
    'uid': uid,
    'desc': desc,
  };
  if (mode != null) {
    data['mode'] = mode;
  }
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return UserRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  var userRes = UserRes(
    success: content['success'],
    error: content['error'] ?? 0,
  );
  return userRes;
}
