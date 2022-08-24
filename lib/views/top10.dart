import 'package:flutter/material.dart';

import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/top10_parser.dart';
import "./utils.dart";

class TopHomePage extends StatefulWidget {
  const TopHomePage({Key? key}) : super(key: key);

  @override
  State<TopHomePage> createState() => _TopHomePageState();
}

class _TopHomePageState extends State<TopHomePage> {
  HomeInfo homeInfo = HomeInfo.empty();
  final _titleFont = const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.normal);

  Future<HomeInfo> getData() async {
    var resp = await bdwmClient.get("$v2Host/mobile/home.php", headers: genHeaders());
    return parseHome(resp.body);
  }

  @override
  void initState() {
    super.initState();
    // homeInfo = getExampleHomeInfo();
    getData().then((value) {
      setState(() {
        homeInfo = value;
      });
    });
  }

  Widget _oneTen(Top10Item item) {
    return Card(
      child: ListTile(
        title: Text(
          item.title,
          textAlign: TextAlign.start,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(item.board),
            const SizedBox(width: 10,),
            const Icon(Icons.comment, size: 12),
            Text(item.countComments)
          ],
        ),
        // dense: true,
        leading: Container(
          height: 20,
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: item.id <= 3 ? Colors.redAccent : Colors.grey,
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            // border: Border.all(width: 1, color: Colors.red),
            ),
          child: Text(item.id.toString(), style: const TextStyle(color: Colors.white)),
        ),
        minLeadingWidth: 20,
        onTap: () { }
      )
    );
  }

  Widget _oneBlockItem(BlockItem item) {
    return Card(
      child: ListTile(
        title: Text(
          item.title,
          textAlign: TextAlign.start,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(item.board),
            const SizedBox(width: 10,),
            const Icon(Icons.comment, size: 12),
            Text(item.countComments)
          ],
        ),
        // dense: true,
        minLeadingWidth: 20,
        onTap: () { }
      )
    );
  }

  checkData(HomeInfo homeInfo) {
    WidgetsBinding.instance.addPostFrameCallback((_){
      var title = "遇到问题";
      var content = "";
      var showIt = false;
      if (homeInfo.top10Info == null) {
        content = "不清楚什么问题";
        showIt = true;
      } else if (homeInfo.top10Info!.length == 1) {
        content = homeInfo.top10Info![0].title;
        showIt = true;
      }
      if (showIt == false) {
        return;
      }
      showAlertDialog(context, title, content,
        actions1: TextButton(
          child: Text("登录"),
          onPressed: () { Navigator.pushReplacementNamed(context, '/login', arguments: {'needBack': false}); },
        ),
        actions2: TextButton(
          child: Text("知道了"),
          onPressed: () { Navigator.pop(context, 'OK'); },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // checkData(homeInfo);
    return ListView(
      controller: ScrollController(),
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("全站十大", style: _titleFont),
              const Divider(),
              if (!(homeInfo.top10Info == null) && homeInfo.top10Info!.length > 1)
                ...homeInfo.top10Info!.map((item) {
                  return _oneTen(item);
                }).toList()
              else if (!(homeInfo.top10Info == null) && homeInfo.top10Info!.length == 1)
                ListTile(
                  // title: Text("全站十大", style: _titleFont),
                  title: Text(homeInfo.top10Info![0].title),
                  // isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.login),
                    onPressed: () { Navigator.pushReplacementNamed(context, '/login', arguments: {'needBack': false}); },
                  )
                ),
            ]
          ),
        ),
        ...homeInfo.blockInfo.map((blockOne) {
          return Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(blockOne.blockName, style: _titleFont),
                const Divider(),
                if (blockOne.blockItems.isNotEmpty)
                  ...blockOne.blockItems.map((item) {
                    return _oneBlockItem(item);
                  }).toList()
                else
                  Text("该分区暂无热门主题帖"),
              ],
            ),
          );
        },).toList(),
      ],
    );
  }
}
