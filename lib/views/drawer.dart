import 'dart:math' show min;

import 'package:flutter/material.dart';

import '../globalvars.dart' show globalUInfo, globalConfigInfo;
import './constants.dart' show bdwmPrimaryColor;
import '../router.dart' show nv2Replace;

class DrawerDestination {
  const DrawerDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.index,
    required this.pageName
  });

  final String label;
  final Icon icon;
  final Icon selectedIcon;
  final int index;
  final String pageName;
}

const drawerPages = [
  DrawerDestination(label: '首页', icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), index: 0, pageName: "/home"),
  DrawerDestination(label: '版面目录', icon: Icon(Icons.list_outlined), selectedIcon: Icon(Icons.list), index: 1, pageName: "/zone"),
  DrawerDestination(label: '版面收藏夹', icon: Icon(Icons.star_outline_outlined), selectedIcon: Icon(Icons.star), index: 2, pageName: "/favorite"),
  DrawerDestination(label: '我', icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), index: 3, pageName: "/me"),
  DrawerDestination(label: '关注/粉丝', icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), index: 4, pageName: "/friend"),
  DrawerDestination(label: '精华区收藏夹', icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), index: 5, pageName: "/favoriteCollection"),
  DrawerDestination(label: '小工具', icon: Icon(Icons.celebration_outlined), selectedIcon: Icon(Icons.celebration), index: 6, pageName: "/funfunfun"),
  DrawerDestination(label: '关于', icon: Icon(Icons.info_outlined), selectedIcon: Icon(Icons.info), index: 7, pageName: "/about"),
];

class MyDrawer extends StatelessWidget {
  final int selectedIdx;
  const MyDrawer({super.key, required this.selectedIdx});

  _gotoPage(String route, BuildContext context) {
    nv2Replace(context, route);
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

  Widget genBGI(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Image.asset(Theme.of(context).brightness == Brightness.dark ? 'assets/image/wei_grey.jpg' : 'assets/image/wei.jpg'),
        Container(
          margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: globalUInfo.login ? bdwmPrimaryColor : Colors.grey,
            child: Text(globalUInfo.username[0].toUpperCase(), style: const TextStyle(fontSize: 30, height: null, color: Colors.white),),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var deviceWidth = size.width;
    double dWidth = min(280, deviceWidth*0.7);
    if (globalConfigInfo.useMD3) {
      return NavigationDrawer(
        indicatorColor: bdwmPrimaryColor.withOpacity(0.8),
        onDestinationSelected: (idx) {
          _gotoPage(drawerPages[idx].pageName, context);
        },
        selectedIndex: selectedIdx,
        children: <Widget>[
          genBGI(context),
          for (int i=0; i<drawerPages.length; i+=1) ...[
            NavigationDrawerDestination(
              // backgroundColor: bdwmPrimaryColor,
              label: Text(drawerPages[i].label),
              icon: drawerPages[i].icon,
              selectedIcon: drawerPages[i].selectedIcon,
            ),
          ],
        ],
      );
    }
    return Drawer(
      width: dWidth,
      child: Column(
        children: [
          genBGI(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0.0),
              children: drawerPages.map((e) {
                return _oneItem(context, e.pageName, icon: e.selectedIcon, text: Text(e.label), idx: e.index);
              }).toList()
            ),
          ),
        ],
      ),
    );
  }
}
