import 'package:flutter/material.dart';

import '../views/user_stat.dart';
import '../views/utils.dart' show showInformDialog;

class UserStatPage extends StatelessWidget {
  const UserStatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      appBar: AppBar(
        title: const Text("统计数据"),
        actions: [
          IconButton(
            onPressed: () {
              showInformDialog(context, "数据来源", "https://bbs.pku.edu.cn/v2/userstat.php");
            },
            icon: const Icon(Icons.info),
          ),
        ],
      ),
      body: const UserStatFutureView(),
    );
  }
}
