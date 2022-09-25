import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../bdwm/search.dart';
import '../globalvars.dart';
import '../html_parser/search_parser.dart';

class FriendsPostsPage extends StatefulWidget {
  final UserInfoRes friendsInfo;
  const FriendsPostsPage({super.key, required this.friendsInfo});

  @override
  State<FriendsPostsPage> createState() => _FriendsPostsPageState();
}

class _FriendsPostsPageState extends State<FriendsPostsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: widget.friendsInfo.users.map((e) {
        var datum = e as IDandName;
        return Text(datum.name);
      }).toList(),
    );
  }
}
