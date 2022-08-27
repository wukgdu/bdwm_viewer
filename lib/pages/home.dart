import 'package:flutter/material.dart';

import '../globalvars.dart';
import '../utils.dart';
import '../services.dart';
import '../views/top100.dart';
import '../views/top10.dart';
import '../views/favorite.dart';
import '../views/drawer.dart';

class HomeApp extends StatefulWidget {
  final NotifyMessageInfo unreadMessageInfo;
  const HomeApp({Key? key, required this.unreadMessageInfo}) : super(key: key);

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  Widget _oneTab(Icon icon, Text text) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [icon, const SizedBox(width: 10), text],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const MyDrawer(),
        appBar: AppBar(
          title: const Text("首页"),
          actions: [
            IconButton(
              icon: const Icon(Icons.mail),
              onPressed: () {
                quickNotify("OBViewer", "mail");
              },
            ),
            Stack(
              alignment: const Alignment(0, 0),
              children: [
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    quickNotify("OBViewer", "message");
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
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                if (globalUInfo.login) {
                  Navigator.of(context).pushNamed('/user', arguments: globalUInfo.uid);
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil('/me', (Route a) => false);
                }
              },
            ),
          ],
          bottom: TabBar(
            labelStyle: const TextStyle(fontSize: 12),
            tabs: [
              _oneTab(const Icon(Icons.whatshot), const Text("热点")),
              _oneTab(const Icon(Icons.trending_up), const Text("百大")),
              _oneTab(const Icon(Icons.star), const Text("收藏")),
            ],
          ),
        ),
        body: const TabBarView(
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