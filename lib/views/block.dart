import 'package:flutter/material.dart';

import './constants.dart';
import '../html_parser/block_parser.dart';

class BlockPage extends StatefulWidget {
  final String bid;
  final String name;
  final BlockInfo blockInfo;
  const BlockPage({super.key, required this.bid, required this.name, required this.blockInfo});

  @override
  State<BlockPage> createState() => _BlockPageState();
}

class _BlockPageState extends State<BlockPage> {
  Widget oneItem(BlockBoardSet bbsItem) {
    return Card(
      child: ListView(
        primary: false,
        shrinkWrap: true,
        children: [
          ListTile(title: Text(bbsItem.title),),
          ...bbsItem.blockBoardItems.map((item) {
            return Card(
              child: ListTile(
                onTap: () {
                  Navigator.of(context).pushNamed('/board', arguments: {
                    'boardName': item.boardName,
                    'bid': item.bid,
                  },);
                },
                title: Text.rich(
                  TextSpan(
                    children: [
                      if (item.isSub)
                        const WidgetSpan(child: SizedBox(width: 16,)),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(item.likeIt ? Icons.star : Icons.star_outline, size: 20, color: bdwmPrimaryColor),
                      ),
                      TextSpan(text: item.boardName, style: TextStyle(color: item.readOnly ? Colors.grey : null)),
                      const TextSpan(text: "  "),
                      TextSpan(text: item.engName, style: TextStyle(color: item.readOnly ? Colors.grey : null)),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.person, size: 20, color: item.thereIsAdmin ? bdwmPrimaryColor : const Color(0x00ffffff)),
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.arrow_right),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.blockInfo.blockBoardSets.length,
      itemBuilder: (context, index) {
        return oneItem(widget.blockInfo.blockBoardSets[index]);
      },
    );
  }
}