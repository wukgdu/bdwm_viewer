import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          _oneItem(context, "/home", icon: Icon(Icons.home), text: Text('首页')),
          _oneItem(context, "/me", icon: Icon(Icons.person), text: Text('我')),
        ],
      ),
    );
  }
}
