import 'dart:math' show min;

import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  final int selectedIdx;
  const MyDrawer({Key? key, required this.selectedIdx}) : super(key: key);

  _gotoPage(String route, BuildContext context) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  Widget _oneItem(context, target, {Icon? icon, Text? text, required int idx}) {
    return Card(
      child: ListTile(
        selected: idx==selectedIdx,
        horizontalTitleGap: 0,
        leading: icon,
        title: text,
        onTap: () {
          // change app state...
          _gotoPage(target, context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var deviceWidth = size.width;
    double dWidth = min(280, deviceWidth*0.7);
    return Drawer(
      width: dWidth,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 10.0, left: 10, right: 10, bottom: 10),
            constraints: const BoxConstraints(
              // maxHeight: 300,
              // maxWidth: dWidth,
            ),
            child: Image.asset('assets/image/wei.jpg'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 0, left: 10, right: 10),
              children: <Widget>[
                _oneItem(context, "/home", icon: const Icon(Icons.home), text: const Text('首页'), idx: 0),
                _oneItem(context, "/zone", icon: const Icon(Icons.list), text: const Text('版面目录'), idx: 1),
                _oneItem(context, "/favorite", icon: const Icon(Icons.star), text: const Text('版面收藏夹'), idx: 2),
                _oneItem(context, "/me", icon: const Icon(Icons.person), text: const Text('我'), idx: 3),
                _oneItem(context, "/friend", icon: const Icon(Icons.people), text: const Text('关注/粉丝'), idx: 4),
                _oneItem(context, "/about", icon: const Icon(Icons.info), text: const Text('关于'), idx: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
