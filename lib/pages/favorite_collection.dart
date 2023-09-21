import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../globalvars.dart';
import '../views/utils.dart';
import '../router.dart' show nv2Push;
import '../views/drawer.dart';
import '../html_parser/favorite_collection_parser.dart';
import '../bdwm/req.dart' show bdwmClient;
import '../utils.dart' show breakLongText;
import '../bdwm/collection.dart' show bdwmCollectionSetGood;

class FavoriteCollectionPage extends StatefulWidget {
  const FavoriteCollectionPage({super.key});

  @override
  State<FavoriteCollectionPage> createState() => _FavoriteCollectionPageState();
}

class _FavoriteCollectionPageState extends State<FavoriteCollectionPage> {
  late CancelableOperation getDataCancelable;
  static const String title = "精华区收藏夹";
  static const drawer = MyDrawer(selectedIdx: 5);

  Future<FavoriteCollectionInfo> getData() async {
    var url = "$v2Host/favorite-collection.php";
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return FavoriteCollectionInfo.error(errorMessage: networkErrorText);
    }
    return parseFavoriteCollection(resp.body);
  }

  void refresh() {
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {},);
    });
  }

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {},);
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: const Text(title),
            ),
            drawer: drawer,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(title),
            ),
            drawer: drawer,
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(title),
            ),
            drawer: drawer,
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var favoriteCollectionInfo = snapshot.data as FavoriteCollectionInfo;
        if (favoriteCollectionInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(title),
            ),
            drawer: drawer,
            body: Center(
              child: Text(favoriteCollectionInfo.errorMessage!),
            ),
          );
        }
        var count = favoriteCollectionInfo.items.length;
        var fontSize = Theme.of(context).appBarTheme.titleTextStyle?.fontSize ?? 14.0;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(title, style: TextStyle(height: 1.0)),
                const Spacer(),
                Text("$count/40", style: TextStyle(fontSize: fontSize-2.0)),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  refresh();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          drawer: drawer,
          body: ListView.builder(
            itemCount: count,
            itemBuilder:(context, index) {
              var item = favoriteCollectionInfo.items[index];
              return Card(
                child: ListTile(
                  title: Text(breakLongText(item.name)),
                  subtitle: Text("${item.collectionName}\n${item.lastTime}"),
                  isThreeLine: true,
                  onTap: () {
                    nv2Push(context, '/collection', arguments: {
                      'link': item.link,
                      'title': item.name,
                    });
                  },
                  trailing: IconButton(
                    onPressed: () async {
                      var removeIt = await showConfirmDialog(context, "取消收藏", item.name);
                      if (removeIt == null || removeIt != "yes") { return; }
                      var res = await bdwmCollectionSetGood(action: 'delete', paths: [item.dataPath]);
                      var txt = "取消收藏成功";
                      if (res.success == false) {
                        txt = res.errorMessage ?? "取消收藏失败";
                      }
                      if (!mounted) { return; }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(txt), duration: const Duration(milliseconds: 600),),
                      );
                      if (res.success) {
                        favoriteCollectionInfo.items.remove(item);
                        setState(() { });
                        // refresh();
                      }
                    },
                    icon: const Icon(Icons.remove),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
