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
    return CollectionRes.error(success: false, error: content['error'] ?? 0, desc: null);
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

class CollectionImportRes {
  bool success = true;
  String name = "";
  int error = 0;
  String? desc;

  CollectionImportRes.empty();
  CollectionImportRes.error({
    required this.success,
    required this.error,
    required this.desc,
  });
  CollectionImportRes({
    required this.success,
    required this.error,
    this.name = "",
  });
}

Future<CollectionImportRes> bdwmCollectionImport({required String from, required String bid, required String postid, required String threadid, required String base, required String mode}) async {
  var actionUrl = "$v2Host/ajax/collection_import_thread.php";
  if (mode == "post" || from == "mail") {
    actionUrl = "$v2Host/ajax/collection_import.php";
  }
  var data = {
    'from': from,
    'bid': bid,
    'postid': postid,
    'threadid': threadid,
    'base': base,
  };
  if (from == "mail") {
    data = {
      'from': "mail",
      'postid': postid,
      'base': base,
    };
  }
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return CollectionImportRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  if (content['success']==false) {
    return CollectionImportRes.error(success: false, error: content['error'] ?? 0, desc: null);
  } else {
    var name = content['name'] ?? "";
    if (name.isEmpty) {
      return CollectionImportRes.error(success: false, error: 1, desc: ""); // i set
    }
  }
  var collectionImportRes = CollectionImportRes(
    success: content['success'],
    error: content['error'] ?? 0,
    name: content['name'] ?? "",
  );
  return collectionImportRes;
}

Future<CollectionImportRes> bdwmOperateCollection({required String path, required String action, String? tobase, String? pos}) async {
  var actionUrl = "$v2Host/ajax/operate_collection.php";
  var data = {
    "action": action,
    "path": path,
  };
  if (action=="copy") {
    assert(tobase != null);
    data['tobase'] = tobase ?? "";
  } else if (action=="move") {
    assert(tobase != null);
    data['tobase'] = tobase ?? "";
  } else if (action=="movepos") {
    assert(pos != null);
    data['pos'] = pos ?? "";
  }
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return CollectionImportRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  CollectionImportRes res = CollectionImportRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
  );
  return res;
}

class CollectionBatchRes {
  bool? success = true;
  List<dynamic> results = [];
  String? desc;

  CollectionBatchRes.empty();
  CollectionBatchRes.error({
    required this.success,
    required this.desc,
  });
  CollectionBatchRes({
    required this.success,
    required this.results,
    this.desc,
  });
}

Future<CollectionBatchRes> bdwmOperateCollectionBatched({required List<String> list, required String action, String? tobase}) async {
  var actionUrl = "$v2Host/ajax/operate_collection_batched.php";
  var data = {
    "action": action,
  };
  for (int i=0; i<list.length; i+=1) {
    data['list[$i]'] = list[i].toString();
  }
  if (action=="copy") {
    assert(tobase != null);
    data['tobase'] = tobase ?? "";
  } else if (action=="move") {
    assert(tobase != null);
    data['tobase'] = tobase ?? "";
  }
  var headers = genHeaders2();
  var resp = await bdwmClient.post(actionUrl, headers: headers, data: data);
  if (resp == null) {
    return CollectionBatchRes.error(success: false, desc: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  // List resultsTmp = respContent['results'] ?? <bool>[];
  // var results = List<bool>.from(resultsTmp.map((e) => e as bool));
  var res = CollectionBatchRes(
    success: respContent['success'],
    results: respContent['results'],
  );
  return res;
}

class CollectionCreateDirRes {
  bool success = true;
  int error = 0;
  String? desc;
  String? name;

  CollectionCreateDirRes.empty();
  CollectionCreateDirRes.error({
    required this.success,
    required this.error,
    this.desc,
  });
  CollectionCreateDirRes({
    required this.success,
    required this.name,
    required this.error,
  });
}

Future<CollectionCreateDirRes> bdwmCollectionCreateDir({required String title, required String base, String bms=""}) async {
  var actionUrl = "$v2Host/ajax/create_collection_dir.php";
  var data = {
    "base": base,
    "title": title,
    "bms": bms,
  };
  var headers = genHeaders2();
  var resp = await bdwmClient.post(actionUrl, headers: headers, data: data);
  if (resp == null) {
    return CollectionCreateDirRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  var res = CollectionCreateDirRes(
    success: respContent['success'],
    name: respContent['name'] ?? "",
    error: respContent['error'] ?? 0,
  );
  return res;
}
