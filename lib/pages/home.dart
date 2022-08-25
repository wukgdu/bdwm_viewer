import 'package:flutter/material.dart';

import '../globalvars.dart';
import '../utils.dart';
import '../services.dart';
import '../views/top100.dart';
import '../views/top10.dart';
import '../views/favorite.dart';
import '../views/drawer.dart';

class HomeApp extends StatefulWidget {
  NotifyMessageInfo unreadMessageInfo;
  HomeApp({Key? key, required this.unreadMessageInfo}) : super(key: key);

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
            Stack(
              alignment: const Alignment(0, 0),
              children: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    quickNotify("OBViewer", "OK");
                  },
                ),
                if (widget.unreadMessageInfo.count > 0)
                  Positioned(
                    top: 10,
                    right: 0,
                    child: Container(
                      width: 20,
                      // height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: Text(
                        widget.unreadMessageInfo.count > 9
                          ? '9+' : widget.unreadMessageInfo.count.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
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