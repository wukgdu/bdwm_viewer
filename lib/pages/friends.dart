import 'package:flutter/material.dart';

import '../views/drawer.dart';
// import '../services.dart';
import '../views/friends.dart';

class FriendsApp extends StatefulWidget {
  const FriendsApp({super.key});

  @override
  State<FriendsApp> createState() => _FriendsAppState();
}

class _FriendsAppState extends State<FriendsApp> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const MyDrawer(selectedIdx: 4,),
        appBar: AppBar(
          title: const Text("关注/粉丝"),
          bottom: const TabBar(
            indicatorColor: Color.fromARGB(159, 214, 53, 13),
            labelStyle: TextStyle(fontSize: 12),
            tabs: [
              Tab(child: Text("关注"),),
              Tab(child: Text("粉丝"),),
              Tab(child: Text("黑名单"),),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FriendPage(mode: ""),
            FriendPage(mode: "fan"),
            FriendPage(mode: "reject"),
          ],
        ),
      ),
    );
  }
}