import 'package:flutter/material.dart';

import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/top100_parser.dart';

class Top100Page extends StatefulWidget {
  Top100Page({Key? key}) : super(key: key);

  @override
  State<Top100Page> createState() => _Top100PageState();
}

class _Top100PageState extends State<Top100Page> {
  List<Top100Item> top100items = <Top100Item>[];
  Future<List<Top100Item>> getData() async {
    var resp = await bdwmClient.get("$v2Host/hot-topic.php", headers: genHeaders());
    return parseTop100(resp.body);
  }

  @override
  void initState() {
    super.initState();
    getData().then((value) {
      // getExampleTop100();
      setState(() {
        top100items = value;
      });
    });
  }

  // @override
  // void didUpdateWidget(oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   getData().then((value) {
  //     setState(() {
  //       top100items = value;
  //     });
  //   });
  // }

  final _biggerFont = const TextStyle(fontSize: 16);
  Widget _onepost(Top100Item item) {
    return Card(
      child: ListTile(
        title: Text(
          item.title,
          style: _biggerFont,
          textAlign: TextAlign.start,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "${item.author} ${item.postTime}\n${item.board}",
        ),
        isThreeLine: true,
        leading: GestureDetector(
          child: Container(
            alignment: Alignment.center,
            width: 30,
            height: 30,
            child: CircleAvatar(
              // radius: 100,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(item.avatarLink),
            ),
          ),
          onTap: () {
            if (item.uid.isEmpty) {
              return;
            }
            Navigator.of(context).pushNamed('/user', arguments: item.uid);
          },
        ),
        minLeadingWidth: 20,
        trailing: Container(
          alignment: Alignment.center,
          width: 24,
          child: Text("${item.id}")
        ),
        dense: false,
        onTap: () { }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(top100items.length.toString());
    return ListView(
      controller: ScrollController(),
      padding: const EdgeInsets.all(8),
      children: top100items.map((Top100Item item) {
        return _onepost(item);
      }).toList(),
    );
  }
}
