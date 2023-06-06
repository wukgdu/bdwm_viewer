import 'dart:async';

import 'package:flutter/services.dart';

class FlutterForAndroid {
  static const MethodChannel _channel = MethodChannel('wukgdu/bdwm_viewer');

  static Future<bool?> cancelToast() async {
    bool? res = await _channel.invokeMethod("cancelToast");
    return res;
  }

  static Future<bool?> showToast({
    required String message,
  }) async {
    var params = {
      'msg': message,
    };
    bool? res = await _channel.invokeMethod('showToast', params);
    return res;
  }
}
