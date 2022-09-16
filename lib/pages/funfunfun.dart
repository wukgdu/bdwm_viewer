import 'package:flutter/material.dart';

import '../views/drawer.dart';
import '../views/funfunfun.dart';

class FunFunFunApp extends StatelessWidget {
  const FunFunFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 5,),
      appBar: AppBar(
        title: const Text("玩"),
      ),
      body: const FunFunFunPage(),
    );
  }
}