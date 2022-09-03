import 'package:flutter/material.dart';

import '../html_parser/search_parser.dart';

class SimpleResultPage extends StatefulWidget {
  final SimpleSearchRes ssRes;
  final String mode;
  const SimpleResultPage({super.key, required this.ssRes, required this.mode});

  @override
  State<SimpleResultPage> createState() => _SimpleResultPageState();
}

class _SimpleResultPageState extends State<SimpleResultPage> {
  Widget oneItem(SimpleSearchResItem ssri) {
    return Card(
      child: ListTile(
        title: Text("${ssri.engName} ${ssri.name}"),
        trailing: const Icon(Icons.arrow_right),
        onTap: () {
          if (widget.mode=="user") {
            if (ssri.id.isEmpty) { return; }
            Navigator.of(context).pushNamed('/user', arguments: ssri.id);
          } else if (widget.mode=="board") {
            if (ssri.id.isEmpty) { return; }
            Navigator.of(context).pushNamed('/board', arguments: {
              'boardName': ssri.name,
              'bid': ssri.id,
            },);
          }
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
        children: widget.ssRes.res.map((e) {
          return oneItem(e);
        }).toList(),
      ),
    );
  }
}
