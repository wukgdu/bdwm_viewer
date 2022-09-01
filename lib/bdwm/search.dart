import 'dart:convert';

import './req.dart';
import '../globalvars.dart';

class IDandName {
  String id;
  String name;
  IDandName({
    required this.id,
    required this.name,
  });
}

class TopSearchRes {
  bool success = false;
  int error = 0;
  String jsonStr;
  List<IDandName> users;
  List<IDandName> boards;

  TopSearchRes({
    required this.success,
    required this.error,
    required this.jsonStr,
    required this.users,
    required this.boards,
  });
}

Future<TopSearchRes> bdwmTopSearch(String pref) async {
  var actionUrl = "$v2Host/ajax/get_topsearch.php";
  var data = {
    'pref': pref,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  var content = json.decode(resp.body);
  var users = <IDandName>[];
  var boards = <IDandName>[];
  if (content['success'] == true) {
    for (var u in content['users']) {
      users.add(IDandName(id: u['id'].toString(), name: u['username']));
    }
    for (var u in content['boards']) {
      boards.add(IDandName(id: u['id'].toString(), name: u['name']));
    }
  }
  TopSearchRes topSearchRes = TopSearchRes(
    success: content['success'],
    error: content['error'] ?? 0,
    jsonStr: resp.body,
    users: users,
    boards: boards,
  );
  return topSearchRes;
}
