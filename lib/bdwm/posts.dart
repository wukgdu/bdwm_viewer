import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../globalvars.dart';
import './req.dart';

String genMD5(String s) {
  var content = const Utf8Encoder().convert(s);
  return md5.convert(content).toString();
}

class PostRes {
  bool success = false;
  int error = 0;

  PostRes({
    required this.success,
    required this.error,
  });
}

Future<PostRes> bdwmSimplePost({required String bid, required String title, required String content, required String signature, required Map<String, bool> config}) async {
  // TODO: random signature, noreplay, anony
  var actionUrl = "$v2Host/ajax/create_post.php";
  var contentData = [
    {
      "type": "ansi",
      "bold": false,
      "underline": false,
      "fore_color": 9,
      "back_color": 9,
      "content": content.endsWith("\n") ? content : "$content\n",
    },
  ];
  var data = {
    'title': title,
    'content': jsonEncode(contentData),
    'bid': bid,
    'postinfo': <String, dynamic>{},
    'actionid': ""
  };
  if (config['mail_re']!=null && config['mail_re'] == true) {
    (data['postinfo'] as Map<String, dynamic>)['mail_re'] = true;
  }
  if (config['no_reply']!=null && config['no_reply'] == true) {
    (data['postinfo'] as Map<String, dynamic>)['no_reply'] = true;
  }
  if (config['anony']!=null && config['anony'] == true) {
    (data['postinfo'] as Map<String, dynamic>)['anony'] = true;
  }
  data['postinfo'] = jsonEncode(data['postinfo']);
  var now = DateTime.now();
  var timestamp = now.millisecondsSinceEpoch ~/ 1000;
  data['actionid'] = (timestamp % 100000000).toString() + genMD5(jsonEncode(data)+signature).substring(0, 16);
  if (signature.isNotEmpty) {
    data['signature'] = signature;
  }
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  var respContent = json.decode(resp.body);
  PostRes postRes = PostRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
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
  var respContent = json.decode(resp.body);
  PostRes postRes = PostRes(
    success: respContent['success'],
    error: respContent['error'] ?? 0,
  );
  return postRes;
}
