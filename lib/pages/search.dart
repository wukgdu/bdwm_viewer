import 'package:flutter/material.dart';

import '../views/search.dart';
// import '../views/drawer.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      // drawer: const MyDrawer(selectedIdx: 2,),
      appBar: AppBar(
        title: const Text("搜索"),
      ),
      body: const SearchView(),
    );
  }
}