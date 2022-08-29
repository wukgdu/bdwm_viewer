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
    const double dWidth = 280;
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
                _oneItem(context, "/me", icon: const Icon(Icons.person), text: const Text('我'), idx: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
