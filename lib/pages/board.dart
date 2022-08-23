import 'package:flutter/material.dart';

import '../globalvars.dart';
import '../views/board.dart';

class BoardApp extends StatefulWidget {
  String? boardName;
  BoardApp({Key? key, this.boardName}) : super(key: key);

  @override
  State<BoardApp> createState() => _BoardAppState();
}

class _BoardAppState extends State<BoardApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName ?? globalUIInfo.boardName),
      ),
      body: BoardPage(),
    );
  }
}