import 'package:flutter/material.dart';

import '../globalvars.dart';

class SimpleSearchComponent extends StatefulWidget {
  final String mode;
  const SimpleSearchComponent({super.key, required this.mode});

  @override
  State<SimpleSearchComponent> createState() => _SimpleSearchComponentState();
}

class _SimpleSearchComponentState extends State<SimpleSearchComponent> {
  TextEditingController textController = TextEditingController();

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
              ),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isEmpty) { return; }
                Navigator.of(context).pushNamed("/simpleSearchResult", arguments: {
                  "mode": widget.mode,
                  "keyWord": textController.text,
                });
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