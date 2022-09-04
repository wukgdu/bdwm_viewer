import 'package:flutter/material.dart';

import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/top100_parser.dart';
import '../pages/read_thread.dart';

class Top100Page extends StatefulWidget {
  const Top100Page({Key? key}) : super(key: key);

  @override
  State<Top100Page> createState() => _Top100PageState();
}

class _Top100PageState extends State<Top100Page> {
  Top100Info top100info = Top100Info.empty();
  Future<Top100Info> getData() async {
    var resp = await bdwmClient.get("$v2Host/hot-topic.php", headers: genHeaders());
    if (resp == null) {
      return Top100Info.error(errorMessage: networkErrorText);
    }
    return parseTop100(resp.body);
  }

  @override
  void initState() {
    super.initState();
    getData().then((value) {
      // getExampleTop100();
      if (!mounted) { return; }
      setState(() {
        top100info = value;
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

  // final _biggerFont = const TextStyle(fontSize: 16);
  Widget _onepost(Top100Item item) {
    return Card(
      child: ListTile(
        title: Text(
          item.title,
          // style: _biggerFont,
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
        // dense: true,
        onTap: () { naviGotoThreadByLink(context, item.contentLink, item.board, needToBoard: true); }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(top100info.items.length.toString());
    if (top100info.errorMessage != null) {
      return Center(
        child: Text(top100info.errorMessage!),
      );
    }
    return ListView(
      controller: ScrollController(),
      padding: const EdgeInsets.all(8),
      children: top100info.items.map((Top100Item item) {
        return _onepost(item);
      }).toList(),
    );
  }
}
