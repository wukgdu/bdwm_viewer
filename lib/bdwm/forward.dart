import 'dart:convert';

import './req.dart';
import './utils.dart';
import './search.dart';
import '../globalvars.dart';

class ForwardRes extends SimpleRes {
  String? desc;
  ForwardRes({
    required super.success,
    required super.error,
  });
  ForwardRes.error({
    required super.success,
    required super.error,
    required this.desc,
  });
}

Future<ForwardRes> bdwmForwrad(String from, String to, String fromID1, String fromID2, String toName, {String? toID}) async {
  var actionUrl = "$v2Host/ajax/forward.php";
  var localToID = toName;
  if (toID != null && toID.isNotEmpty) {
    localToID = toID;
  } else {
    if (toName.isEmpty) {
      return ForwardRes(success: false, error: 2);
    }
    var searchResp = await bdwmTopSearch(toName);
    bool findIt = false;
    if (searchResp.success) {
      var toNameLc = toName.toLowerCase();
      var toSearch = searchResp.boards;
      if (to == "mail") {
        toSearch = searchResp.users;
      }
      for (var b in toSearch) {
        if (b.name.toLowerCase() == toNameLc) {
          localToID = b.id;
          findIt = true;
          break;
        }
      }
    } else {
      if (searchResp.error == -1) {
        return ForwardRes.error(success: false, error: -1, desc: networkErrorText);
      }
    }
    if (!findIt) {
      return ForwardRes(success: false, error: 1);
    }
  }
  var data = <String, String>{};
  if (from == "post" && to == "post") {
    data = {
      "from": from,
      "bid": fromID1,
      "postid": fromID2,
      "to": to,
      "tobid": localToID,
    };
  } else if (from == "post" && to == "mail") {
    data = {
      "from": from,
      "bid": fromID1,
      "postid": fromID2,
      "to": to,
      "touid": localToID,
    };
  } else if (from == "mail" && to == "mail") {
    data = {
      "from": from,
      "postid": fromID2,
      "to": to,
      "touid": localToID,
    };
  } else if (from == "mail" && to == "post") {
    data = {
      "from": from,
      "postid": fromID2,
      "to": to,
      "tobid": localToID,
    };
  }
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return ForwardRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  var forwardRes = ForwardRes(
    success: content['success'],
    error: content['error'] ?? 0,
  );
  return forwardRes;
  // return ForwardRes(success: true, error: 0);
}
