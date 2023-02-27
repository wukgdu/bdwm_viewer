import 'package:dynamic_color/dynamic_color.dart' show ColorHarmonization;
import 'package:flutter/material.dart';

import '../globalvars.dart';
import '../utils.dart';
import '../views/constants.dart' show bdwmPrimaryColor;
// import '../services.dart';
import '../views/top100.dart';
import '../views/top10.dart';
import '../views/favorite.dart';
import '../views/drawer.dart';
import '../router.dart' show nv2Push, nv2PushAndRemoveAll;

class StackIcon extends StatelessWidget {
  final int count;
  final Icon icon;
  final Function callBack;
  const StackIcon({Key? key, required this.count, required this.icon, required this.callBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: const Alignment(0, 0),
      children: [
        IconButton(
          icon: icon,
          onPressed: () => callBack(),
        ),
        if (count > 0)
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
                count > 9
                  ? '9+' : count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class HomeApp extends StatefulWidget {
  final ValueNotifier<int> messageCount;
  final ValueNotifier<int> mailCount;
  const HomeApp({Key? key, required this.messageCount, required this.mailCount}) : super(key: key);

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Widget _oneTab(Icon icon, Text text) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [icon, const SizedBox(width: 10), text],
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    clearAllExtendedImageCache();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(selectedIdx: 0,),
      appBar: AppBar(
        title: const Text("首页"),
        actions: [
          ValueListenableBuilder(
            valueListenable: widget.mailCount,
            builder: (context, count, Widget? child) {
              return StackIcon(
                count: count as int,
                icon: const Icon(Icons.mail),
                callBack: () {
                  // quickNotify("OBViewer", "mail");
                  nv2Push(context, '/mail');
                },
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: widget.messageCount,
            builder: (context, count, Widget? child) {
              return StackIcon(
                count: count as int,
                icon: const Icon(Icons.message),
                callBack: () {
                  // quickNotify("OBViewer", "message");
                  nv2Push(context, '/message');
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              nv2Push(context, '/search');
            },
          ),
          IconButton(
            icon: Icon(globalUInfo.login ? Icons.account_circle : Icons.no_accounts_rounded),
            onPressed: () {
              if (globalUInfo.login) {
                nv2Push(context, '/user', arguments: globalUInfo.uid);
              } else {
                nv2PushAndRemoveAll(context, '/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          indicatorColor: const Color.fromARGB(159, 214, 53, 13).harmonizeWith(bdwmPrimaryColor),
          labelStyle: const TextStyle(fontSize: 12),
          controller: _tabController,
          tabs: [
            _oneTab(const Icon(Icons.whatshot), const Text("热点")),
            _oneTab(const Icon(Icons.trending_up), const Text("百大")),
            _oneTab(const Icon(Icons.star), const Text("收藏")),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TopHomePage(),
          Top100Page(),
          FavoriteFuturePage(),
        ],
      ),
    );
  }
}