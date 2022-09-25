import 'package:flutter/material.dart';

import '../views/drawer.dart';
import '../views/funfunfun.dart';
import '../views/constants.dart';

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
      floatingActionButton: IconButton(
        icon: const Icon(Icons.home, color: bdwmPrimaryColor),
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        },
      ),
    );
  }
}