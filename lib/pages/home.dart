import 'package:flutter/material.dart';

import '../views/top100.dart';
import '../views/favorite.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("首页"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.trending_up), text: "百大",),
              Tab(icon: Icon(Icons.star), text: "收藏",),
            ],
          ),
        ),
        body: TabBarView(),
      ),
    );
  }
}