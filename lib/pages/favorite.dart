import 'package:flutter/material.dart';

import '../views/favorite.dart';
import '../views/drawer.dart';
import '../views/constants.dart';

class FavoriteApp extends StatefulWidget {
  const FavoriteApp({super.key});

  @override
  State<FavoriteApp> createState() => _FavoriteAppState();
}

class _FavoriteAppState extends State<FavoriteApp> {
  bool? clearUnread;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // needBack should always be false/null
      drawer: const MyDrawer(selectedIdx: 2,),
      appBar: AppBar(
        title: const Text("版面收藏夹"),
      ),
      floatingActionButton: IconButton(
        onPressed: () {
          setState(() {
            clearUnread = true;
          });
        },
        icon: const Icon(Icons.cleaning_services, color: bdwmPrimaryColor,),
      ),
      body: FavoritePage(clear: clearUnread,),
    );
  }
}