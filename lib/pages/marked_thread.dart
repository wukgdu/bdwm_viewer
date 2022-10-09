import 'package:flutter/material.dart';

import '../globalvars.dart' show globalMarkedThread;
import './read_thread.dart';
import '../views/utils.dart' show showConfirmDialog;

class MarkedThreadApp extends StatefulWidget {
  const MarkedThreadApp({super.key});

  @override
  State<MarkedThreadApp> createState() => _MarkedThreadAppState();
}

class _MarkedThreadAppState extends State<MarkedThreadApp> {
  @override
  Widget build(BuildContext context) {
    var itemCount = globalMarkedThread.count;
    var items = globalMarkedThread.items.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("已收藏"),
        actions: [
          IconButton(
            onPressed: () async {
              var value = await showConfirmDialog(context, "删除所有", "rt");
              if (value == null || value != "yes") { return; }
              await globalMarkedThread.removeAll();
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
                naviGotoThreadByLink(context, items[index].link, "", needToBoard: true);
              },
              title: Text(
                items[index].title,
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
              trailing: IconButton(
                onPressed: () async {
                  var value = await showConfirmDialog(context, "删除", "rt");
                  if (value == null || value != "yes") { return; }
                  await globalMarkedThread.removeOne(items[index].link);
                  setState(() { });
                },
                icon: const Icon(Icons.delete),
              ),
            ),
          );
        },
      ),
    );
  }
}
