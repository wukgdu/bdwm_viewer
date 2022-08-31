import 'package:flutter/material.dart';

import '../views/post_new.dart';

class PostNewApp extends StatefulWidget {
  final String bid;
  final String boardName;
  const PostNewApp({Key? key, required this.bid, required this.boardName}) : super(key: key);

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
      body: PostNewPage(bid: widget.bid,),
    );
  }
}