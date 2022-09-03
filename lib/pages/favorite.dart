import 'package:flutter/material.dart';

import '../views/favorite.dart';
import '../views/drawer.dart';

class FavoriteApp extends StatelessWidget {
  const FavoriteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 2,),
      appBar: AppBar(
        title: const Text("版面收藏夹"),
      ),
      body: const FavoritePage(),
    );
  }
}