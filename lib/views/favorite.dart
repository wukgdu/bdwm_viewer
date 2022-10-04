import 'package:bdwm_viewer/router.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../bdwm/set_read.dart';
import '../globalvars.dart';
import '../html_parser/favorite_parser.dart';

class FavoriteFuturePage extends StatefulWidget {
  const FavoriteFuturePage({Key? key}) : super(key: key);

  @override
  State<FavoriteFuturePage> createState() => _FavoriteFuturePageState();
}

class _FavoriteFuturePageState extends State<FavoriteFuturePage> {
  late CancelableOperation getDataCancelable;

  Future<FavoriteBoardInfo> getData() async {
    var resp = await bdwmClient.get("$v2Host/favorite.php", headers: genHeaders2());
    if (resp == null) {
      return FavoriteBoardInfo.error(errorMessage: networkErrorText);
    }
    return parseFavoriteBoard(resp.body);
  }

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
  }

  Future<void> updateData() async {
    if (!mounted) { return; }
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
    });
  }

  @override
  void didUpdateWidget(covariant FavoriteFuturePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("favorite rebuild");
    return RefreshIndicator(
      onRefresh: updateData,
      child: FutureBuilder(
        future: getDataCancelable.value,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("错误：${snapshot.error}"),);
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("错误：未获取数据"),);
          }
          FavoriteBoardInfo favoriteBoardInfo = snapshot.data as FavoriteBoardInfo;
          return FavoritePage(favoriteBoardInfo: favoriteBoardInfo);
        }
      )
    );
  }
}

class FavoritePage extends StatefulWidget {
  final FavoriteBoardInfo favoriteBoardInfo;
  const FavoritePage({super.key, required this.favoriteBoardInfo});

  @override
  State<FavoritePage> createState() => FavoritePageState();
}

class FavoritePageState extends State<FavoritePage> {
  late FavoriteBoardInfo favoriteBoardInfo;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    favoriteBoardInfo = widget.favoriteBoardInfo;
  }

  @override
  void didUpdateWidget(covariant FavoritePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    favoriteBoardInfo = widget.favoriteBoardInfo;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void clearUnread() {
    bdwmSetBoardRead(favoriteBoardInfo.favoriteBoards.map((e) => int.parse(e.boardLink.split("=").last)).toList())
    .then((res) {
      var txt = "清除未读成功";
      if (!res.success) {
        if (res.error == -1) {
          txt = res.desc!;
        } else {
          txt = "清除未读失败";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(txt), duration: const Duration(milliseconds: 600),),
      );
      if (res.success) {
        for (var item in favoriteBoardInfo.favoriteBoards) {
          item.unread = false;
        }
        setState(() { });
      }
    });
  }

  final _biggerFont = const TextStyle(fontSize: 16);
  Widget _onepost(FavoriteBoard item) {
    return Card(
      child: SizedBox(
        height: 40,
        child: InkWell(
          child: Row(
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // const Spacer(flex: 1),
              const SizedBox(width: 10,),
              Icon(Icons.circle, size: 10, color: item.unread ? Colors.red : const Color.fromRGBO(255, 255, 255, 0),),
              const SizedBox(width: 10,),
              // const Spacer(flex: 1),
              Text.rich(
                TextSpan(
                  text: item.boardName,
                  children: <TextSpan>[
                    const TextSpan(text: "  "),
                    TextSpan(
                      text: item.engName,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    )
                  ],
                ),
                textAlign: TextAlign.start,
                style: _biggerFont,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(flex: 50),
            ],
          ),
          onTap: () {
            nv2Push(context, "/board", arguments: {
              'boardName': item.boardName,
              'bid': item.boardLink.split("=").last,
          });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (favoriteBoardInfo.errorMessage != null) {
      return Center(
        child: Text(favoriteBoardInfo.errorMessage!),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            children: favoriteBoardInfo.favoriteBoards.map((FavoriteBoard item) {
              return _onepost(item);
            }).toList(),
          ),
        ),
        Container(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () { clearUnread(); },
            child: const Text("清除未读")
          ),
        ),
      ],
    );
  }
}