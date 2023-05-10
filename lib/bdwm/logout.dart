import 'dart:convert' show json;

import './req.dart' show bdwmClient;
import '../globalvars.dart' show genHeaders2, v2Host, globalUInfo;

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
  return true;
}
