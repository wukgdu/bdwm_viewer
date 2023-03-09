import 'dart:convert';

import './req.dart';
import '../globalvars.dart' show v2Host, genHeaders2, networkErrorText;

class SetProfileRes {
  bool success = false;
  int error = 0;
  String? errorMessage;

  SetProfileRes({
    required this.success,
    required this.error,
  });
  SetProfileRes.error({
    this.success = false,
    required this.error,
    required this.errorMessage,
  });
}

Future<SetProfileRes> bdwmSetProfileRankOnly(String newRankValue) async {
  // 不行，不能只修改等级系统
  var actionUrl = "$v2Host/ajax/set_profile.php";
  var data = {
    'ranksys': newRankValue,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return SetProfileRes.error(success: false, error: -1, errorMessage: networkErrorText);
  }
  var content = json.decode(resp.body);
  var setProfileRes = SetProfileRes(
    success: content['success'],
    error: content['error'] ?? 0,
  );
  return setProfileRes;
}
