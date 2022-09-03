import 'package:flutter/material.dart';

class PostSearchSettings {
  String keyWord = "";
  String owner = "";
  String board = "";
  String rated = "";
  String days = "";
  String titleonly = "";
  String timeorder = "";
  String? mode = "post";
  String? bid = "";

  PostSearchSettings.empty();
  PostSearchSettings({
    required this.keyWord,
    required this.owner,
    required this.board,
    required this.rated,
    required this.days,
    required this.titleonly,
    required this.timeorder,
    this.mode,
    this.bid,
  });
}

class SimpleSearchComponent extends StatefulWidget {
  final String mode;
  const SimpleSearchComponent({super.key, required this.mode});

  @override
  State<SimpleSearchComponent> createState() => _SimpleSearchComponentState();
}

class _SimpleSearchComponentState extends State<SimpleSearchComponent> {
  TextEditingController textController = TextEditingController();

  void startSearch() {
    if (textController.text.isEmpty) { return; }
    Navigator.of(context).pushNamed("/simpleSearchResult", arguments: {
      "mode": widget.mode,
      "keyWord": textController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                onEditingComplete: () {
                  startSearch();
                },
              ),
            ),
            TextButton(
              onPressed: () {
                startSearch();
              },
              child: const Text("搜索"),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        Center(child: Text("搜索用户")),
        SimpleSearchComponent(mode: "user",),
        Center(child: Text("搜索版面")),
        SimpleSearchComponent(mode: "board"),
      ],
    );
  }
}