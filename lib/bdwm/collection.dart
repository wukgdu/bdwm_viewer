import 'dart:convert';

import './req.dart';
import '../globalvars.dart' show v2Host, genHeaders2, networkErrorText;

class CollectionInfo {
  String path = "";
  String title = "";
  String bms = "";
  bool hasattach = false;
  bool islink = false;
  bool isdir = false;
  int time = 0;

  CollectionInfo.empty();
  CollectionInfo({
    required path,
    required title,
    required bms,
    required hasattach,
    required islink,
    required isdir,
    required time,
  });
  CollectionInfo.fromMap(Map<String, dynamic> r) {
    path = r['path'] as String;
    title = r['title'] as String;
    bms = r['bms'] as String;
    hasattach = r['hasattach'] as bool;
    islink = r['islink'] as bool;
    isdir = r['isdir'] as bool;
    time = r['time'] as int;
  }
}

class CollectionRes {
  bool success;
  int error;
  String? desc;
  List<CollectionInfo> collections = [];
  CollectionRes({
    required this.success,
    required this.error,
    this.desc,
    required this.collections,
  });
  CollectionRes.error({
    required this.success,
    required this.error,
    required this.desc,
  });
}

Future<CollectionRes> bdwmGetCollections({String? path=""}) async {
  var actionUrl = "$v2Host/ajax/get_managed_collections.php";
  var data = {};
  if (path!=null && path.isNotEmpty) {
    actionUrl = "$v2Host/ajax/get_collection_items.php";
    data = {
      'path': path,
    };
  }
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return CollectionRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  if (content['success']==false) {
    return CollectionRes.error(success: false, error: content['error'], desc: null);
  }
  List<CollectionInfo> collections = [];
  for (var r in content['result']) {
    collections.add(CollectionInfo.fromMap(r));
  }
  var collectionRes = CollectionRes(
    success: content['success'],
    error: content['error'] ?? 0,
    collections: collections,
  );
  return collectionRes;
}
