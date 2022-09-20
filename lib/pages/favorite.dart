import 'package:flutter/material.dart';

import '../views/favorite.dart';
import '../views/drawer.dart';

class FavoriteApp extends StatefulWidget {
  const FavoriteApp({super.key});

  @override
  State<FavoriteApp> createState() => _FavoriteAppState();
}

class _FavoriteAppState extends State<FavoriteApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 2,),
      appBar: AppBar(
        title: const Text("版面收藏夹"),
      ),
      body: const FavoriteFuturePage(),
    );
  }
}