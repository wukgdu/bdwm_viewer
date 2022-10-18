import 'package:flutter/material.dart';

import '../views/user_stat.dart';

class UserStatApp extends StatelessWidget {
  const UserStatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      appBar: AppBar(
        title: const Text("统计数据"),
      ),
      body: const UserStatFuturePage(),
    );
  }
}
