import 'package:flutter/material.dart';
import 'package:async/async.dart';

import './utils.dart' show genScrollableWidgetForPullRefresh;
import '../bdwm/req.dart';
import '../bdwm/set_read.dart';
import '../globalvars.dart';
import '../router.dart';
import './constants.dart' show bdwmPrimaryColor;
import '../html_parser/favorite_parser.dart';
import './board_bottom_info.dart' show jumpToAdminFromBoardCard;

class FavoriteFutureView extends StatefulWidget {
  const FavoriteFutureView({Key? key}) : super(key: key);

  @override
  State<FavoriteFutureView> createState() => _FavoriteFutureViewState();
}

class _FavoriteFutureViewState extends State<FavoriteFutureView> {
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
  void didUpdateWidget(covariant FavoriteFutureView oldWidget) {
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
          return FavoriteView(favoriteBoardInfo: favoriteBoardInfo);
        }
      )
    );
  }
}

class FavoriteView extends StatefulWidget {
  final FavoriteBoardInfo favoriteBoardInfo;
  const FavoriteView({super.key, required this.favoriteBoardInfo});

  @override
  State<FavoriteView> createState() => FavoriteViewState();
}

class FavoriteViewState extends State<FavoriteView> {
  late FavoriteBoardInfo favoriteBoardInfo;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    favoriteBoardInfo = widget.favoriteBoardInfo;
  }

  @override
  void didUpdateWidget(covariant FavoriteView oldWidget) {
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
      child: ListTile(
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: item.boardName),
              const TextSpan(text: "  "),
              TextSpan(
                text: item.engName,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const TextSpan(text: "  "),
              for (var _ in item.admin) ...[
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.person, size: 16),
                ),
              ]
            ],
          ),
          textAlign: TextAlign.start,
          style: _biggerFont,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            // Icon(Icons.circle, size: 10, color: item.unread ? bdwmPrimaryColor : const Color.fromRGBO(255, 255, 255, 0),),
            if (item.unread) ... [
              Icon(Icons.circle, size: 10, color: bdwmPrimaryColor),
              const SizedBox(width: 5,),
            ],
            Expanded(
              child: Text(
                "${item.lastUpdate.text}（${item.people}）",
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
        onTap: () {
          nv2Push(context, "/board", arguments: {
            'boardName': item.boardName,
            'bid': item.boardLink.split("=").last,
          });
        },
        onLongPress: () {
          jumpToAdminFromBoardCard(context, item.admin);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (favoriteBoardInfo.errorMessage != null) {
      // for RefreshIndicator
      return genScrollableWidgetForPullRefresh(
        Center(
          child: Text(favoriteBoardInfo.errorMessage!),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: favoriteBoardInfo.favoriteBoards.length,
            itemBuilder: (context, index) {
              var item = favoriteBoardInfo.favoriteBoards[index];
              return _onepost(item);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
              onPressed: () { clearUnread(); },
              child: const Text("清除未读")
            ),
            TextButton(
              onPressed: () { nv2Push(context, "/zone", arguments: { 'needBack': true, }); },
              child: const Text("版面目录")
            ),
          ],
        ),
      ],
    );
  }
}