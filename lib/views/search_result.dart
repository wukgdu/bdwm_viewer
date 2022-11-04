import 'package:flutter/material.dart';

import '../html_parser/search_parser.dart';
import './constants.dart';
import '../pages/read_thread.dart';
import '../router.dart' show nv2Push;

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
        title: Text("${ssri.engName} ${ssri.name}", style: serifFont),
        trailing: const Icon(Icons.arrow_right),
        onTap: () {
          if (widget.mode=="user") {
            if (ssri.id.isEmpty) { return; }
            nv2Push(context, '/user', arguments: ssri.id);
          } else if (widget.mode=="board") {
            if (ssri.id.isEmpty) { return; }
            nv2Push(context, '/board', arguments: {
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
    return ListView.builder(
      itemCount: widget.ssRes.res.length,
      itemBuilder: (context, index) {
        var e = widget.ssRes.res[index];
        return oneItem(e);
      },
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
  final _ts1 = const TextStyle(fontSize: 12, color: Colors.grey, height: 2);
  final _ts2 = const TextStyle(fontSize: 16);
  final _ts3 = const TextStyle(fontSize: 12);

  void gotoThread(ComplexSearchResItem csri) {
    nv2Push(context, '/thread', arguments: {
      'bid': csri.bid,
      'threadid': csri.threadid,
      'boardName': csri.boardName,
      'page': '1',
    },);
  }

  Widget oneItem(ComplexSearchResItem csri) {
    return Card(
      child: InkWell(
        onTap: () {
          gotoThread(csri);
        },
        child: Container(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  nv2Push(context, '/board', arguments: {
                    'boardName': csri.boardName,
                    'bid': csri.bid,
                  },);
                },
                child: Text("${csri.boardName} ${csri.boardEngName}", style: _ts1,),
              ),
              GestureDetector(
                onTap: () {
                  gotoThread(csri);
                },
                child: Text(csri.title, style: _ts2,),
              ),
              Text("楼主 ${csri.userName}", style: _ts3,),
              ...csri.shortTexts.map((st) {
                return GestureDetector(
                  onTap: () {
                    naviGotoThreadByLink(context, st.link, csri.boardName, pageDefault: "a");
                  },
                  child: Text("${st.time} - ${st.text}", style: _ts1.copyWith(height: 1.5),),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.csRes.resItems.length,
      itemBuilder: (context, index) {
        var e = widget.csRes.resItems[index];
        return oneItem(e);
      },
    );
  }
}
