import 'package:flutter/material.dart';

import '../bdwm/req.dart';
import '../bdwm/set_read.dart';
import '../globalvars.dart';
import '../html_parser/favorite_parser.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => FavoritePageState();
}

class FavoritePageState extends State<FavoritePage> {
  FavoriteBoardInfo favoriteBoardInfo = FavoriteBoardInfo.empty();
  final _scrollController = ScrollController();
  bool updateToggle = false;
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
    // setState(() {
    //   favoriteBoards = getExampleFavoriteBoard();
    // });
    getData().then((value) {
      // debugPrint("get favorite data");
      if (!mounted) { return; }
      // debugPrint("1 ${widget.clear}");
      setState(() {
        favoriteBoardInfo = value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant FavoritePage oldWidget) {
    super.didUpdateWidget(oldWidget);
      // debugPrint("2 ${widget.clear}");
    var clear = false;
    if (clear == true) {
      clearUnread();
      clear = false;
    }
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
        setState(() {
          updateToggle = !updateToggle;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            Navigator.of(context).pushNamed("/board", arguments: {
              'boardName': item.boardName,
              'bid': item.boardLink.split("=").last,
          });
          },
        ),
      ),
    );
  }

  Widget boardView() {
    if (favoriteBoardInfo.errorMessage != null) {
      return Center(
        child: Text(favoriteBoardInfo.errorMessage!),
      );
    }
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      children: favoriteBoardInfo.favoriteBoards.map((FavoriteBoard item) {
        return _onepost(item);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("favorite rebuild");
    return boardView();
  }
}
