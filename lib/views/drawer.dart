import 'dart:math' show min;

import 'package:flutter/material.dart';

import '../globalvars.dart' show globalUInfo;
import './constants.dart' show bdwmPrimaryColor;

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
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.asset(Theme.of(context).brightness == Brightness.dark ? 'assets/image/wei_grey.jpg' : 'assets/image/wei.jpg'),
              Container(
                margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: globalUInfo.login ? bdwmPrimaryColor : Colors.grey,
                  child: Text(globalUInfo.username[0].toUpperCase(), style: const TextStyle(fontSize: 30, height: 1.05, color: Colors.white),),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0.0),
              children: <Widget>[
                _oneItem(context, "/home", icon: const Icon(Icons.home), text: const Text('首页'), idx: 0),
                _oneItem(context, "/zone", icon: const Icon(Icons.list), text: const Text('版面目录'), idx: 1),
                _oneItem(context, "/favorite", icon: const Icon(Icons.star), text: const Text('版面收藏夹'), idx: 2),
                _oneItem(context, "/me", icon: const Icon(Icons.person), text: const Text('我'), idx: 3),
                _oneItem(context, "/friend", icon: const Icon(Icons.people), text: const Text('关注/粉丝'), idx: 4),
                _oneItem(context, "/funfunfun", icon: const Icon(Icons.celebration), text: const Text('小工具'), idx: 5),
                _oneItem(context, "/about", icon: const Icon(Icons.info), text: const Text('关于'), idx: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
