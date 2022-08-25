import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class BdwmClient {
  final http.Client client = http.Client();

  Future<http.Response> post(String url, {Map<String, String> headers=const {}, Object data=const <String, String>{}}) {
    debugPrint("post");
    return client.post(Uri.parse(url), body: data, headers: headers);
  }

  Future<http.Response> get(String url, {Map<String, String> headers=const {}}) {
    debugPrint("get");
    return client.get(Uri.parse(url), headers: headers);
  }
}

var bdwmClient = BdwmClient();
