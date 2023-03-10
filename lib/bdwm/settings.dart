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

Future<SetProfileRes> bdwmSetProfile({
  required String nickName,
  required String rankSys,
  required int birthYear,
  required int birthMonth,
  required int birthDay,
  required bool hideHoroscope,
  required String gender,
  required bool hideGender,
  required String desc,
}) async {
  var actionUrl = "$v2Host/ajax/set_profile.php";
  var data = {
    "nickname": nickName,
    "birthyear": birthYear.toString(),
    "birthmonth": birthMonth.toString(),
    "birthday": birthDay.toString(),
    "gender": gender,
    "ranksys": rankSys,
    "desc": desc,
  };
  if (hideGender) {
    data['hide_gender'] = "on";
  }
  if (hideHoroscope) {
    data['hide_horoscope'] = "on";
  }
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
