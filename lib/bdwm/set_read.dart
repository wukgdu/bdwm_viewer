import 'dart:convert';

import './req.dart';
import '../globalvars.dart';

class SetReadRes {
  bool success = false;
  int error;
  String? desc;

  SetReadRes({
    required this.success,
    required this.error,
  });
  SetReadRes.error({
    required this.success,
    required this.error,
    required this.desc,
  });
}

Future<SetReadRes> bdwmSetBoardRead(List<int> bids) async {
  var actionUrl = "$v2Host/ajax/set_board_read.php";
  var data = {
    'bids': jsonEncode(bids),
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return SetReadRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  var setReadRes = SetReadRes(
    success: content['success'],
    error: content['error'] ?? 0,
  );
  return setReadRes;
}

Future<SetReadRes> bdwmSetThreadRead(String bid, List<int> threads) async {
  var actionUrl = "$v2Host/ajax/set_thread_read.php";
  var data = {
    'bid': bid,
    'list': jsonEncode(threads),
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return SetReadRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  var setReadRes = SetReadRes(
    success: content['success'],
    error: content['error'] ?? 0,
  );
  return setReadRes;
}

Future<SetReadRes> bdwmSetPostRead(String bid, List<int> threads) async {
  var actionUrl = "$v2Host/ajax/set_post_read.php";
  var data = {
    'bid': bid,
    'list': jsonEncode(threads),
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return SetReadRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  var setReadRes = SetReadRes(
    success: content['success'],
    error: content['error'] ?? 0,
  );
  return setReadRes;
}
