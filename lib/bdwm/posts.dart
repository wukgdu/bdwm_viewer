import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../globalvars.dart';
import './req.dart';
import '../views/html_widget.dart' show BDWMAnsiText;
import './utils.dart' show rawString;

String genMD5(String s) {
  var content = const Utf8Encoder().convert(s);
  return md5.convert(content).toString();
}

class PostRes {
  bool success = false;
  int error = 0;
  String? result;
  int? postid;
  bool? rawSuccess;
  int? threadid;

  PostRes({
    required this.success,
    this.rawSuccess,
    required this.error,
    this.postid,
    this.threadid,
    this.result,
  });
  PostRes.error({
    required this.success,
    required this.error,
    this.result,
  });
}

Future<PostRes> bdwmSimplePost({required String bid, required String title, required String content, required String signature, required Map<String, bool> config, bool? modify=false, String? postid, bool? useBDWM=false, String? parentid, String? attachpath}) async {
  var actionUrl = "$v2Host/ajax/create_post.php";
  if (modify == true) {
    actionUrl = "$v2Host/ajax/edit_post.php";
  }
  var contentStr = content;
  String lastConent = (useBDWM!=null&&useBDWM==true)
  ? contentStr
  : "[${BDWMAnsiText.raw(content.endsWith("\n") ? rawString(content) : rawString("$content\n"))}]";
  var data = {
    'title': title,
    'content': lastConent,
    'bid': bid,
    'postinfo': <String, dynamic>{},
    'actionid': "",
    "attachpath": attachpath ?? "",
  };
  if (modify == true) {
    data['postid'] = postid!;
  }
  if (config['mail_re']!=null && config['mail_re'] == true) {
    (data['postinfo'] as Map<String, dynamic>)['mail_re'] = true;
  }
  if (config['no_reply']!=null && config['no_reply'] == true) {
    (data['postinfo'] as Map<String, dynamic>)['no_reply'] = true;
  }
  if (config['anony']!=null && config['anony'] == true) {
    (data['postinfo'] as Map<String, dynamic>)['anony'] = true;
  }
  if (parentid != null) {
    (data['postinfo'] as Map<String, dynamic>)['parentid'] = int.parse(parentid);
  }
  data['postinfo'] = jsonEncode(data['postinfo']);
  var now = DateTime.now();
  var timestamp = now.millisecondsSinceEpoch ~/ 1000;
  data['actionid'] = (timestamp % 100000000).toString() + genMD5(jsonEncode(data)+signature).substring(0, 16);
  if (signature.isNotEmpty) {
    data['signature'] = signature;
  }
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return PostRes.error(success: false, error: -1, result: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  PostRes postRes = PostRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
    postid: respContent['result']['postid'] ?? -1,
    threadid: respContent['result']['threadid'] ?? -1,
  );
  return postRes;
}

Future<PostRes> bdwmDeletePost({required String bid, required String postid}) async {
  var actionUrl = "$v2Host/ajax/operate_post.php";
  var data = {
    "bid": bid,
    "list": '[$postid]',
    "action": 'delete',
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return PostRes.error(success: false, error: -1, result: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  PostRes postRes = PostRes(
    success: respContent['results'][0]==false,
    error: respContent['error'] ?? 0,
  );
  return postRes;
}

Future<PostRes> bdwmGetPostQuote({required String bid, required String postid, String mode="simple"}) async {
  var actionUrl = "$v2Host/ajax/get_post_quote.php";
  var data = {
    "bid": bid,
    "postid": postid,
    "mode": mode,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return PostRes.error(success: false, error: -1, result: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  PostRes postRes = PostRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
    result: respContent['quote'],
  );
  return postRes;
}

Future<PostRes> bdwmOperatePost({required String bid, required String postid, required String action, int? rating}) async {
  var actionUrl = "$v2Host/ajax/operate_post.php";
  var data = {
    "bid": bid,
    "list": '[$postid]',
    "action": action,
  };
  if ((rating != null) && (action == "rate")) {
    data['rating'] = rating.toString();
  }
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return PostRes.error(success: false, error: -1, result: networkErrorText);
  }
  var respContent = json.decode(resp.body);
  PostRes postRes = PostRes(
    success: respContent['results'][0]==false,
    rawSuccess: respContent['success'],
    error: respContent['error'] ?? 0,
  );
  return postRes;
}
