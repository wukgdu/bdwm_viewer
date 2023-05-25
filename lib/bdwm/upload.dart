import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import '../globalvars.dart' show v2Host, genHeadersForUpload, networkErrorText, genHeaders2;
import './req.dart';

class UploadRes {
  bool success = false;
  int error = 0;
  String? name;
  String? url;
  String? desc;

  UploadRes.empty();
  UploadRes.error({
    required this.success,
    required this.error,
    this.desc,
  });
  UploadRes.simple({
    required this.success,
    required this.error,
  });
  UploadRes({
    required this.success,
    required this.error,
    required this.name,
    required this.url,
    this.desc,
  });
}

Future<UploadRes> bdwmUpload(String dir, String path, {Duration? timeout}) async {
  var uri = Uri.parse("$v2Host/ajax/upload.php");
  var request = http.MultipartRequest('POST', uri);
  request.headers.addAll(genHeadersForUpload());
  request.fields['dir'] = dir;
  var filename = basename(path);
  filename = filename.replaceAll("\\", "_");
  filename = filename.replaceAll("/", "_");
  filename = filename.replaceAll("|", "_");
  filename = filename.replaceAll(" ", "_");
  request.files.add(await http.MultipartFile.fromPath(
    'file',
    path,
    filename: filename,
    contentType: MediaType("multipart", "form-data"),
  ),);
  var isTimeout = false;
  try {
    var resp = await request.send().timeout(timeout ?? const Duration(seconds: 60));
    if (resp.statusCode == 200) {
      var str = await resp.stream.bytesToString();
      var content = jsonDecode(str);
      if (content['success']==false) {
        var error = content['error'] ?? 0;
        if (error == 0) {
          return UploadRes.error(success: false, error: 1, desc: "连接失败");
        } else if (error == 34) {
          return UploadRes.error(success: false, error: 1, desc: "登录失效");
        } else {
          return UploadRes.error(success: false, error: 1, desc: "不知道为什么");
        }
      }
      return UploadRes(success: true, error: 0, name: content['name'] ?? "", url: content['url'] ?? "");
    } else {
      return UploadRes.error(success: false, error: 1, desc: "连接失败");
    }
  } on TimeoutException catch (_) {
    isTimeout = true;
  } on SocketException catch (_) {
    isTimeout = true;
  } on HttpException catch (_) {
    isTimeout = true;
  } on Exception catch (_) {
    isTimeout = true;
  } catch (e) {
    isTimeout = true;
  }
  if (isTimeout) {
    return UploadRes.error(success: false, error: -1, desc: networkErrorText);
  }
  return UploadRes.error(success: false, error: 1, desc: "不知道为什么");
}

Future<UploadRes> bdwmDeleteUpload(String dir, String name) async {
  var actionUrl = "$v2Host/ajax/upload.php";
  var data = {
    'action': 'delete',
    'dir': dir,
    'name': name,
  };
  var resp = await bdwmClient.post(actionUrl, headers: genHeaders2(), data: data);
  if (resp == null) {
    return UploadRes.error(success: false, error: -1, desc: networkErrorText);
  }
  var content = json.decode(resp.body);
  var uploadRes = UploadRes.simple(
    success: content['success'],
    error: content['error'] ?? 0,
  );
  return uploadRes;
}
