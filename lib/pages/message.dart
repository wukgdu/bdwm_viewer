import 'package:flutter/material.dart';

import '../views/message.dart';
import '../services.dart' show MessageBriefNotifier;

class MessagelistApp extends StatelessWidget {
  final MessageBriefNotifier brief;
  const MessagelistApp({Key? key, required this.brief}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("消息"),
      ),
      body: MessageListPage(users: brief),
    );
  }
}

class MessagePersonApp extends StatelessWidget {
  final String userName;
  const MessagePersonApp({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),
      body: MessagePersonPage(withWho: userName),
    );
  }
}