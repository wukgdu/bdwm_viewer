import 'package:flutter/material.dart';

import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/favorite_parser.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<FavoriteBoard> favoriteBoards = <FavoriteBoard>[];
  Future<List<FavoriteBoard>> getData() async {
    var resp = await bdwmClient.get("$v2Host/favorite.php", headers: genHeaders2());
    return parseFavoriteBoard(resp.body);
  }

  @override
  void initState() {
    super.initState();
    // setState(() {
    //   favoriteBoards = getExampleFavoriteBoard();
    // });
    getData().then((value) {
      setState(() {
        favoriteBoards = value;
      });
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
    return ListView(
      padding: const EdgeInsets.all(8),
      children: favoriteBoards.map((FavoriteBoard item) {
        return _onepost(item);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return boardView();
  }
}
