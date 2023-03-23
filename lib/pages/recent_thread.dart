import 'package:flutter/material.dart';

import '../globalvars.dart' show globalThreadHistory;
import './read_thread.dart';
import '../views/utils.dart' show showConfirmDialog;
import '../utils.dart' show breakLongText;

class RecentThreadApp extends StatefulWidget {
  const RecentThreadApp({super.key});

  @override
  State<RecentThreadApp> createState() => _RecentThreadAppState();
}

class _RecentThreadAppState extends State<RecentThreadApp> {
  @override
  Widget build(BuildContext context) {
    var itemCount = globalThreadHistory.count;
    var items = globalThreadHistory.items.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("最近浏览"),
        actions: [
          IconButton(
            onPressed: () async {
              var value = await showConfirmDialog(context, "删除所有", "rt");
              if (value == null || value != "yes") { return; }
              await globalThreadHistory.removeAll();
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
              trailing: IconButton(
                onPressed: () async {
                  var value = await showConfirmDialog(context, "删除", "rt");
                  if (value == null || value != "yes") { return; }
                  await globalThreadHistory.removeOne(items[index].link);
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
