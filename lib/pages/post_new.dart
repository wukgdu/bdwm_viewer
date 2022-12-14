import 'package:flutter/material.dart';

import '../views/post_new.dart';

class PostNewApp extends StatefulWidget {
  final String bid;
  final String boardName;
  final String? postid;
  final String? parentid;
  final String? nickName;
  const PostNewApp({Key? key, required this.bid, required this.boardName, this.postid, this.parentid, this.nickName}) : super(key: key);

  @override
  State<PostNewApp> createState() => _PostNewAppState();
}

class _PostNewAppState extends State<PostNewApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName),
      ),
      body: PostNewFuturePage(bid: widget.bid, postid: widget.postid, parentid: widget.parentid, nickName: widget.nickName),
    );
  }
}