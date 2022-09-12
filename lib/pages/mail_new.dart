import 'package:flutter/material.dart';

import '../views/mail_new.dart';

class MailNewApp extends StatefulWidget {
  final String? parentid;
  const MailNewApp({Key? key, this.parentid}) : super(key: key);

  @override
  State<MailNewApp> createState() => _MailNewAppState();
}

class _MailNewAppState extends State<MailNewApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("站内信/新建"),
      ),
      body: MailNewFuturePage(parentid: "24705760",),
      // body: MailNewFuturePage(parentid: widget.parentid,),
    );
  }
}