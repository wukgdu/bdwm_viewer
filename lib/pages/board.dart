import 'package:flutter/material.dart';

import '../views/board.dart';

class BoardApp extends StatefulWidget {
  final String boardName;
  const BoardApp({Key? key, required this.boardName}) : super(key: key);

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
      body: const BoardPage(),
    );
  }
}