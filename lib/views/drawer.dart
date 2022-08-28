import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  _gotoPage(String route, BuildContext context) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  Widget _oneItem(context, target, {Icon? icon, Text? text}) {
    return ListTile(
      leading: icon,
      title: text,
      onTap: () {
        // change app state...
        _gotoPage(target, context);
      },
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
                _oneItem(context, "/home", icon: const Icon(Icons.home), text: const Text('首页')),
                _oneItem(context, "/me", icon: const Icon(Icons.person), text: const Text('我')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
