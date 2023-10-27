import 'package:flutter/material.dart';

import '../views/mail_new.dart';

class MailNewPage extends StatelessWidget {
  final String? bid;
  final String? parentid;
  final String? receiver;
  const MailNewPage({super.key, this.bid, this.parentid, this.receiver});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("站内信/新建"),
      ),
      body: MailNewFutureView(bid: bid, parentid: parentid, receiver: receiver),
    );
  }
}