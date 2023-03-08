import 'package:flutter/material.dart';

import '../views/drawer.dart';
import '../views/funfunfun.dart';
import '../views/constants.dart';
import '../router.dart' show nv2PushAndRemoveAll;

class FunFunFunApp extends StatelessWidget {
  const FunFunFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 6,),
      appBar: AppBar(
        title: const Text("玩"),
      ),
      body: const FunFunFunPage(),
      floatingActionButton: IconButton(
        icon: Icon(Icons.home, color: bdwmPrimaryColor),
        onPressed: () {
          nv2PushAndRemoveAll(context, '/home');
        },
      ),
    );
  }
}