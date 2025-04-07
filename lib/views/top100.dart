import 'package:flutter/material.dart';
import 'package:async/async.dart';

import './utils.dart' show genScrollableWidgetForPullRefresh;
import '../bdwm/req.dart';
import '../utils.dart' show breakLongText;
import '../globalvars.dart';
import '../html_parser/top100_parser.dart';
import '../pages/read_thread.dart';
import '../router.dart' show nv2Push;
import './constants.dart' show bdwmPrimaryColor;
import './html_widget.dart' show genSimpleCachedImageProvider;

class Top100RankLabelComponent extends StatelessWidget {
  final int itemID;
  const Top100RankLabelComponent({super.key, required this.itemID});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        // border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
        color: bdwmPrimaryColor.withAlpha(200),
      ),
      child: Text("$itemID", style: const TextStyle(color: Colors.white, fontSize: 10, height: null),),
    );
  }
}

class Top100View extends StatefulWidget {
  const Top100View({super.key});

  @override
  State<Top100View> createState() => _Top100ViewState();
}

class _Top100ViewState extends State<Top100View> {
  final _scrollController = ScrollController();
  late CancelableOperation getDataCancelable;

  Future<Top100Info> getData() async {
    var resp = await bdwmClient.get("$v2Host/hot-topic.php", headers: genHeaders());
    if (resp == null) {
      return Top100Info.error(errorMessage: networkErrorText);
    }
    return parseTop100(resp.body);
  }

  Future<void> updateData() async {
    if (!mounted) { return; }
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
    });
  }

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // final _biggerFont = const TextStyle(fontSize: 16);
  Widget _onepost(Top100Item item) {
    return Card(
      child: ListTile(
        title: Text(
          breakLongText(item.title),
          // style: _biggerFont,
          textAlign: TextAlign.start,
          overflow: globalConfigInfo.getShowDetailInCard() ? null : TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("${item.author} ${item.postTime} "),
                const Spacer(),
                Top100RankLabelComponent(itemID: item.id,),
              ],
            ),
            Text(item.board),
          ],
        ),
        isThreeLine: true,
        dense: false,
        leading: GestureDetector(
          child: Container(
            alignment: Alignment.center,
            width: 30,
            height: 30,
            margin: globalConfigInfo.getUseMD3() ? const EdgeInsets.only(top: 4) : null,
            child: CircleAvatar(
              // radius: 100,
              backgroundColor: Colors.white,
              backgroundImage: genSimpleCachedImageProvider(item.avatarLink),
            ),
          ),
          onTap: () {
            if (item.uid.isEmpty) {
              return;
            }
            nv2Push(context, '/user', arguments: item.uid);
          },
        ),
        minLeadingWidth: 20,
        onTap: () { naviGotoThreadByLink(context, item.contentLink, item.board.split("(").first, needToBoard: true); }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: updateData,
      child: FutureBuilder(
        future: getDataCancelable.value,
        builder: (context, snapshot) {
          // debugPrint(snapshot.connectionState.toString());
          if (snapshot.connectionState != ConnectionState.done) {
            // return const Center(child: CircularProgressIndicator());
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("错误：${snapshot.error}"),);
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("错误：未获取数据"),);
          }
          Top100Info top100Info = snapshot.data as Top100Info;
          if (top100Info.errorMessage != null) {
            return genScrollableWidgetForPullRefresh(
              Center(
                child: Text(top100Info.errorMessage!),
              ),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            itemCount: top100Info.items.length,
            itemBuilder: (context, index) {
              var item = top100Info.items[index];
              return _onepost(item);
            },
          );
        }
      ),
    );
  }
}
