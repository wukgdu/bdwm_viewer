import 'package:bdwm_viewer/globalvars.dart';
import 'package:flutter/material.dart';

import '../views/top100.dart';
import '../views/top10.dart';
import '../views/favorite.dart';
import '../views/drawer.dart';

class HomeApp extends StatefulWidget {
  const HomeApp({Key? key}) : super(key: key);

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  Widget _oneTab(Icon icon, Text text) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [icon, SizedBox(width: 10), text],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: MyDrawer(),
        appBar: AppBar(
          title: const Text("首页"),
          actions: [
            IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                if (globalUInfo.login) {
                  Navigator.of(context).pushNamed('/user', arguments: globalUInfo.uid);
                } else {
                  Navigator.of(context).pushReplacementNamed('/me');
                }
              },
            ),
          ],
          bottom: TabBar(
            labelStyle: const TextStyle(fontSize: 12),
            tabs: [
              _oneTab(Icon(Icons.whatshot), Text("热点")),
              _oneTab(Icon(Icons.trending_up), Text("百大")),
              _oneTab(Icon(Icons.star), Text("收藏")),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TopHomePage(),
            Top100Page(),
            FavoritePage(),
          ],
        ),
      ),
    );
  }
}