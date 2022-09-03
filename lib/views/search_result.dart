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

class ComplexResultPage extends StatefulWidget {
  final ComplexSearchRes csRes;
  const ComplexResultPage({super.key, required this.csRes});

  @override
  State<ComplexResultPage> createState() => _ComplexResultPageState();
}

class _ComplexResultPageState extends State<ComplexResultPage> {
  final _ts1 = const TextStyle(fontSize: 12, color: Colors.grey);
  final _ts2 = const TextStyle(fontSize: 16, color: Colors.black);
  final _ts3 = const TextStyle(fontSize: 12, color: Colors.black);

  Widget oneItem(ComplexSearchResItem csri) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/board', arguments: {
                  'boardName': csri.boardName,
                  'bid': csri.bid,
                },);
              },
              child: Text("${csri.boardName} ${csri.boardEngName}", style: _ts1,),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/thread', arguments: {
                  'bid': csri.bid,
                  'threadid': csri.threadid,
                  'boardName': csri.boardName,
                  'page': '1',
                },);
              },
              child: Text(csri.title, style: _ts2,),
            ),
            Text("楼主 ${csri.userName}", style: _ts3,),
            ...csri.shortTexts.map((st) {
              return GestureDetector(
                onTap: () {},
                child: Text(st.text, style: _ts1,),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
        children: widget.csRes.resItems.map((e) {
          return oneItem(e);
        }).toList(),
      ),
    );
  }
}