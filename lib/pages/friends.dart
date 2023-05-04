import 'package:flutter/material.dart';

import '../views/drawer.dart';
// import '../services.dart';
import '../views/friends.dart';
import '../router.dart' show nv2Push;

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

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
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                nv2Push(context, '/search');
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            FriendView(mode: ""),
            FriendView(mode: "fan"),
            FriendView(mode: "reject"),
          ],
        ),
      ),
    );
  }
}