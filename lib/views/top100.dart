import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/top100_parser.dart';
import '../pages/read_thread.dart';
import '../router.dart' show nv2Push;

class Top100Page extends StatefulWidget {
  const Top100Page({Key? key}) : super(key: key);

  @override
  State<Top100Page> createState() => _Top100PageState();
}

class _Top100PageState extends State<Top100Page> {
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
          item.title,
          // style: _biggerFont,
          textAlign: TextAlign.start,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "${item.author} ${item.postTime}\n${item.board}",
        ),
        isThreeLine: true,
        leading: GestureDetector(
          child: Container(
            alignment: Alignment.center,
            width: 30,
            height: 30,
            child: CircleAvatar(
              // radius: 100,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(item.avatarLink),
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
        trailing: Container(
          alignment: Alignment.center,
          width: 24,
          child: Text("${item.id}")
        ),
        // dense: true,
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
            return LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Text(top100Info.errorMessage!),
                  ),
                )
              );
            },);
          }
          return ListView(
            controller: _scrollController,
            children: top100Info.items.map((Top100Item item) {
              return _onepost(item);
            }).toList(),
          );
        }
      ),
    );
  }
}
