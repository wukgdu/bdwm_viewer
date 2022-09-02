import 'package:flutter/material.dart';

import './constants.dart';
import '../html_parser/zone_parser.dart';

class ZonePage extends StatefulWidget {
  final ZoneInfo zoneInfo;
  const ZonePage({super.key, required this.zoneInfo});

  @override
  State<ZonePage> createState() => _ZonePageState();
}

class _ZonePageState extends State<ZonePage> {
  Widget oneItem(ZoneItemInfo ziInfo) {
    var size = MediaQuery.of(context).size;
    var itemWidth = size.width / 2;
    var itemHeight = 20;
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/block', arguments: {
                  'bid': ziInfo.bid,
                  'title': ziInfo.name,
                },);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${ziInfo.number} ${ziInfo.name}"),
                  const Icon(Icons.arrow_right),
                ],
              ),
            ),
            const Divider(),
            Wrap(
              // alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text("区务："),
                ...ziInfo.admins.map((e) {
                  return TextButton(
                    onPressed: () {
                      if (e.link == null || e.link!.isEmpty) {
                        return;
                      }
                      Navigator.of(context).pushNamed('/user', arguments: e.link);
                    },
                    style: ButtonStyle(textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.normal))),
                    child: Text(e.text, style: textLinkStyle),
                  );
                }).toList(),
              ],
            ),
            const Divider(),
            GridView.count(
              crossAxisCount: 2,
              primary: false,
              shrinkWrap: true,
              childAspectRatio: itemWidth / itemHeight,
              children: ziInfo.boards.map((e) {
                return GestureDetector(
                  onTap: () {
                    var boardName = e.text.substring(1, e.text.length-1); // [name]
                    Navigator.of(context).pushNamed('/board', arguments: {
                      'boardName': boardName,
                      'bid': e.link,
                    },);
                  },
                  child: Center(
                    child: Text(e.text, style: textLinkStyle),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: widget.zoneInfo.zoneItems.map((e) {
        return oneItem(e);
      }).toList(),
    );
  }
}
