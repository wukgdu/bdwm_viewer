import 'dart:convert';

import './req.dart';
import '../globalvars.dart';

Future<bool> bdwmLogout() async {
  var logoutUrl = "$v2Host/ajax/logout.php";
  var resp = await bdwmClient.post(logoutUrl, headers: genHeaders2(), data: {});
  if (resp == null) {
    return false;
  }
  var status = json.decode(resp.body);
  if (!status['success']) {
    return false;
  }
  await globalUInfo.setLogout();
  // List<String> res = parseCookie(resp.headers['set-cookie'] ?? "");
  // if (res.isNotEmpty) {
  //   globalUInfo.setInfo(res[1], res[0], username);
  // }
  return true;
}
