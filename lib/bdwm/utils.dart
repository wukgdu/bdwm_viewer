import 'dart:convert';

class SimpleRes {
  bool success = false;
  int error = 0;

  SimpleRes({
    required this.success,
    required this.error,
  });
}

String rawString(String a) {
  var res = jsonEncode(a);
  return res.substring(1, res.length-1);
}
