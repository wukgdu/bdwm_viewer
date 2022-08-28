import 'package:flutter/material.dart';

import '../views/board.dart';

class BoardApp extends StatefulWidget {
  final String boardName;
  final String bid;
  const BoardApp({Key? key, required this.boardName, required this.bid}) : super(key: key);

  @override
  State<BoardApp> createState() => _BoardAppState();
}

class _BoardAppState extends State<BoardApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName),
      ),
      body: BoardPage(bid: widget.bid),
    );
  }
}