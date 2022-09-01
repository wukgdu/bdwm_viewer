import 'dart:convert';

import './req.dart';
import './utils.dart';
import './search.dart';
import '../globalvars.dart';

class ForwardRes extends SimpleRes {
  ForwardRes({
    required super.success,
    required super.error,
  });
}

Future<ForwardRes> bdwmForwrad(String fromBid, String fromPostid, {String? toBoardName, String? toBid}) async {
  var actionUrl = "$v2Host/ajax/forward.php";
  var toBid2 = toBid;
  if (toBoardName == null && toBid == null) {
    return ForwardRes(success: false, error: 2);
  }
  if (toBid == null) {
    var searchResp = await bdwmTopSearch(toBoardName!);
    bool findIt = false;
    if (searchResp.success) {
      var toBoardNameLc = toBoardName.toLowerCase();
      for (var b in searchResp.boards) {
        if (b.name.toLowerCase() == toBoardNameLc) {
          toBid2 = b.id;
          findIt = true;
          break;
        }
      }
    }
    if (!findIt) {
      return ForwardRes(success: false, error: 1);
    }
  }
  var data = {
    "from": "post",
    "bid": fromBid,
    "postid": fromPostid,
    "to": "post",
    "tobid": toBid2,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  var content = json.decode(resp.body);
  var forwardRes = ForwardRes(
    success: content['success'],
    error: content['error'] ?? 0,
  );
  return forwardRes;
  // return ForwardRes(success: true, error: 0);
}
