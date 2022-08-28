import 'package:flutter/material.dart';

import '../html_parser/board_parser.dart';
import './constants.dart';
import '../bdwm/req.dart';
import '../globalvars.dart';

class OneThreadInBoard extends StatelessWidget {
  final BoardPostInfo boardPostInfo;
  final String bid;
  final String boardName;
  const OneThreadInBoard({Key? key, required this.boardPostInfo, required this.bid, required this.boardName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool pinned = boardPostInfo.bpID == "置顶";
    return Card(
        child: ListTile(
          title: Text.rich(
            textAlign: TextAlign.left,
            TextSpan(
              children: <InlineSpan>[
                if (pinned)
                  const WidgetSpan(child: Icon(Icons.pin_drop, color: bdwmPrimaryColor, size: 16))
                else if (boardPostInfo.isNew)
                  const WidgetSpan(
                    child: Icon(Icons.circle, color: bdwmPrimaryColor, size: 7),
                    alignment: PlaceholderAlignment.middle,
                  ),
                TextSpan(
                  text: boardPostInfo.title,
                ),
              ],
            )
          ),
          subtitle: pinned ? null
            : Text.rich(
              TextSpan(
                text: "${boardPostInfo.userName} 发表于 ${boardPostInfo.pTime}",
                children: [
                  const TextSpan(text: "   "),
                  const WidgetSpan(
                    child: Icon(Icons.comment, size: 12),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  const TextSpan(text: " "),
                  TextSpan(text: boardPostInfo.commentCount),
                  const TextSpan(text: "\n"),
                  TextSpan(text: "${boardPostInfo.lastUser} 最后回复于 ${boardPostInfo.lastTime}"),
                ],
              )
            ),
          isThreeLine: pinned ? false : true,
          onTap: () {
            if (pinned) {
              bdwmClient.get(boardPostInfo.link, headers: genHeaders2()).then((value) {
                var threadid = directToThread(value.body);
                if (threadid.isEmpty) { return; }
                Navigator.of(context).pushNamed('/thread', arguments: {
                  'bid': bid,
                  'threadid': threadid,
                  'boardName': boardName,
                  'page': '1',
                });
              });
            } else {
              Navigator.of(context).pushNamed('/thread', arguments: {
                'bid': bid,
                'threadid': boardPostInfo.threadID,
                'boardName': boardName,
                'page': '1',
              });
            }
          },
        ),
    );
  }
}
class BoardPage extends StatefulWidget {
  final String bid;
  const BoardPage({Key? key, required this.bid}) : super(key: key);

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  BoardInfo boardInfo = BoardInfo.empty();
  int page = 1;
  final _titleFont = const TextStyle(fontWeight: FontWeight.bold, fontSize: 18);
  final _titleFont2 = const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey);
  static const _boldFont = TextStyle(fontWeight: FontWeight.bold);
  static const double _padding1 = 10;
  static const double _padding2 = 20;

  Future<BoardInfo> getData() async {
    var resp = await bdwmClient.get("$v2Host/thread.php?bid=${widget.bid}", headers: genHeaders2());
    return parseBoardInfo(resp.body);
  }

  @override
  void initState() {
    super.initState();
    // boardInfo = getExampleBoard();
    getData().then((value) {
      setState(() {
        boardInfo = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          margin: const EdgeInsets.only(top: _padding1, left: _padding2, right: _padding2, bottom: _padding1),
          child: Row(
            children: [
              Text(boardInfo.boardName, style: _titleFont),
              const SizedBox(width: 10,),
              Text(boardInfo.engName, style: _titleFont2),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: _padding1, left: _padding2, right: _padding2),
          child: Text(boardInfo.intro),
        ),
        Container(
          margin: const EdgeInsets.only(left: _padding2, right: _padding2, bottom: _padding1),
          child: Wrap(
            children: [
              // const Text("版务：", style: _boldFont),
              for (var admin in boardInfo.admins)
                ...[
                  Text(admin.userName, style: textLinkStyle),
                  const SizedBox(width: 5,),
                ],
            ],
          ),
        ),
        Divider(),
        ListView.builder(
          primary: false,
          shrinkWrap: true,
          itemCount: boardInfo.boardPostInfo.length,
          itemBuilder: (context, index) {
            return OneThreadInBoard(boardPostInfo: boardInfo.boardPostInfo[index], boardName: boardInfo.boardName, bid: boardInfo.bid);
          },
        ),
      ],
    );
  }
}
