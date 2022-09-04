import 'dart:convert';

import './req.dart';
import '../globalvars.dart' show v2Host, networkErrorText, genHeaders2;

class VoteRes {
  bool success = false;
  int error = 0;
  int upCount = 0;
  int downCount = 0;
  String? desc;

  VoteRes({
    required this.success,
    required this.error,
    required this.upCount,
    required this.downCount,
  });
  VoteRes.error({
    required this.error,
    required this.success,
    required this.desc,
  });
}

Future<VoteRes> bdwmVote(String bid, String postid, String action) async {
  var actionUrl = "$v2Host/ajax/post_up_down_vote.php";
  var data = {
    'bid': bid,
    'postid': postid,
    'action': action,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return VoteRes.error(
      success: false,
      error: -1,
      desc: networkErrorText,
    );
  }
  var content = json.decode(resp.body);
  VoteRes voteRes = VoteRes(
    success: content['success'],
    error: content['error'] ?? 0,
    upCount: content['counts']['up'],
    downCount: content['counts']['down'],
  );
  return voteRes;
}
