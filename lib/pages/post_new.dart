import 'package:flutter/material.dart';

import '../views/post_new.dart';

class PostNewPage extends StatefulWidget {
  final String bid;
  final String boardName;
  final String? postid;
  final String? parentid;
  final String? nickName;
  const PostNewPage({Key? key, required this.bid, required this.boardName, this.postid, this.parentid, this.nickName}) : super(key: key);

  @override
  State<PostNewPage> createState() => _PostNewPageState();
}

class _PostNewPageState extends State<PostNewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName),
      ),
      body: PostNewFutureView(bid: widget.bid, postid: widget.postid, parentid: widget.parentid, nickName: widget.nickName),
    );
  }
}