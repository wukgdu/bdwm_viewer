import 'package:flutter/material.dart';

import '../views/friends_posts.dart';
import '../bdwm/search.dart';

class FriendsPostsPage extends StatefulWidget {
  const FriendsPostsPage({super.key});

  @override
  State<FriendsPostsPage> createState() => _FriendsPostsPageState();
}

class _FriendsPostsPageState extends State<FriendsPostsPage> {
  final _getData = bdwmGetFriends();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getData,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: const Text("朋友动态"),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("朋友动态"),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("朋友动态"),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var friendsInfo = snapshot.data as UserInfoRes;
        return Scaffold(
          appBar: AppBar(
            title: const Text("朋友动态"),
          ),
          body: FriendsPostsView(friendsInfo: friendsInfo),
        );
      }
    );
  }
}
