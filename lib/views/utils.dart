import 'package:flutter/material.dart';

Future<String?> showAlertDialog(BuildContext context, String title, String content, {Widget? actions1, Widget? actions2}) {

  // set up the buttons
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      if (actions1 != null) ...[actions1],
      if (actions2 != null) ...[actions2],
    ],
  );

  // show the dialog
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
