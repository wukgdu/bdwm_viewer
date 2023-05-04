import 'package:flutter/material.dart';

import '../views/favorite.dart';
import '../views/drawer.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 2,),
      appBar: AppBar(
        title: const Text("版面收藏夹"),
      ),
      body: const FavoriteFutureView(),
    );
  }
}