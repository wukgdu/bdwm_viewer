import 'dart:convert';

import './req.dart';
import '../globalvars.dart';

class StarBoardRes {
  bool success = false;
  int error = 0;

  StarBoardRes({
    required this.success,
    required this.error,
  });
}

Future<StarBoardRes> bdwmStarBoard(int bid, String action) async {
  var actionUrl = "$v2Host/ajax/set_good_boards.php";
  var data = {
    'action': action,
    'bids': "[$bid]",
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  var content = json.decode(resp.body);
  StarBoardRes starBoardRes = StarBoardRes(
    success: content['success'],
    error: content['error'] ?? 0,
  );
  return starBoardRes;
}
