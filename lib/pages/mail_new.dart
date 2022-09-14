import 'package:flutter/material.dart';

import '../views/mail_new.dart';

class MailNewApp extends StatefulWidget {
  final String? parentid;
  final String? receiver;
  const MailNewApp({Key? key, this.parentid, this.receiver}) : super(key: key);

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
      body: MailNewFuturePage(parentid: widget.parentid, receiver: widget.receiver),
    );
  }
}