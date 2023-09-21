import 'package:flutter/material.dart';

import '../globalvars.dart' show globalPostHistoryData;
import '../views/utils.dart' show showConfirmDialog, SizedIconButton;
import './read_thread.dart';
import '../utils.dart' show breakLongText;

class PostHistoryPage extends StatefulWidget {
  const PostHistoryPage({super.key});

  @override
  State<PostHistoryPage> createState() => _PostHistoryPageState();
}

class _PostHistoryPageState extends State<PostHistoryPage> {
  @override
  Widget build(BuildContext context) {
    var itemCount = globalPostHistoryData.items.length;
    var items = globalPostHistoryData.items.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("发帖历史"),
        actions: [
          IconButton(
            onPressed: () async {
              var value = await showConfirmDialog(context, "删除所有", "rt");
              if (value == null || value != "yes") { return; }
              await globalPostHistoryData.removeAll();
              setState(() { });
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          var timestamp = items[index].timestamp;
          var timeStr = "未知";
          if (timestamp != 0) {
            timeStr = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal().toString();
            timeStr = timeStr.split(".").first;
          }
          return Card(
            child: ListTile(
              onTap: () {
                naviGotoThreadByLink(context, items[index].link, "", needToBoard: true, allowSingle: true);
              },
              title: Text(
                breakLongText(items[index].title),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${items[index].userName} @${items[index].boardName}",
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text("时间：$timeStr"),
                ]
              ),
              isThreeLine: true,
              trailing: SizedIconButton(
                onPressed: () async {
                  var value = await showConfirmDialog(context, "删除", "rt");
                  if (value == null || value != "yes") { return; }
                  await globalPostHistoryData.removeOne(items[index].link);
                  setState(() { });
                },
                icon: const Icon(Icons.delete, size: 24,),
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
