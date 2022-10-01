import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/top10_parser.dart';
import '../pages/read_thread.dart';
import './utils.dart';
import '../pages/detail_image.dart';

class TopHomePage extends StatefulWidget {
  const TopHomePage({Key? key}) : super(key: key);

  @override
  State<TopHomePage> createState() => _TopHomePageState();
}

class _TopHomePageState extends State<TopHomePage> {
  final _titleFont = const TextStyle(fontSize: 20, fontWeight: FontWeight.normal);
  final _scrollController = ScrollController();
  late CancelableOperation getDataCancelable;

  Future<WelcomeInfo> getWelcomeData() async {
    var resp = await bdwmClient.get("$v2Host/home.php", headers: genHeaders());
    if (resp == null) {
      return WelcomeInfo.error(errorMessage: networkErrorText);
    }
    return parseWelcomeFromHtml(resp.body);
  }

  Future<HomeInfo> getData() async {
    var resp = await bdwmClient.get("$v2Host/mobile/home.php", headers: genHeaders());
    if (resp == null) {
      return HomeInfo.error(errorMessage: networkErrorText);
    }
    return parseHome(resp.body);
  }

  @override
  void initState() {
    super.initState();
    // homeInfo = getExampleHomeInfo();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
    // _scrollController.addListener(() {
    //   debugPrint(_scrollController.offset);
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String lastLoginTimeStr = globalConfigInfo.getLastLoginTime();
      var ld = DateTime.tryParse(lastLoginTimeStr);
      var curDT = DateTime.now();
      // ld = null;
      if (ld==null || "${curDT.year}-${curDT.month}-${curDT.day}" != "${ld.year}-${ld.month}-${ld.day}") {
        if (!mounted) { return; }
        var welcomeInfo = await getWelcomeData();
        if (welcomeInfo.errorMessage != null) { return; }
        if (welcomeInfo.imgLink.isEmpty) { return; }
        if (!mounted) { return; }
        var saveUpdate = globalConfigInfo.setLastLoginTime(curDT.toIso8601String());
        showAlertDialog(context, "今日进站",
          GestureDetector(
            onTap: () {
              gotoDetailImage(context: context, link: welcomeInfo.imgLink);
            },
            child: Image.network(welcomeInfo.imgLink),
          ),
          actions1: TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("进入未名BBS"),
          ),
        );
        await saveUpdate;
      }
    });
  }

  Future<void> updateData() async {
    if (!mounted) { return; }
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {});
    });
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _oneTen(Top10Item item) {
    return Card(
      child: ListTile(
        title: Text(
          item.title,
          textAlign: TextAlign.start,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(item.board),
            const SizedBox(width: 10,),
            const Icon(Icons.comment, size: 12),
            Text(item.countComments)
          ],
        ),
        // dense: true,
        leading: Container(
          height: 20,
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: item.id <= 3 ? Colors.redAccent : Colors.grey,
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            // border: Border.all(width: 1, color: Colors.red),
          ),
          child: Text(item.id.toString(), style: const TextStyle(color: Colors.white)),
        ),
        minLeadingWidth: 20,
        onTap: () { naviGotoThreadByLink(context, item.link, item.board, needToBoard: true); }
      )
    );
  }

  Widget _oneBlockItem(BlockItem item) {
    return Card(
      child: ListTile(
        title: Text(
          item.title,
          textAlign: TextAlign.start,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(item.board),
            const SizedBox(width: 10,),
            const Icon(Icons.comment, size: 12),
            Text(item.countComments)
          ],
        ),
        // dense: true,
        minLeadingWidth: 20,
        onTap: () { naviGotoThreadByLink(context, item.link, item.board, needToBoard: true); }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("** top10 rebuild");
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
          HomeInfo homeInfo = snapshot.data as HomeInfo;
          if (homeInfo.errorMessage != null) {
            return Center(
              child: Text(homeInfo.errorMessage!),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            // padding: const EdgeInsets.all(8),
            itemCount: homeInfo.blockInfo.length+1,
            itemBuilder: (context, index) {
              if (index==0) {
                return Card(
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("全站十大", style: _titleFont),
                      const Divider(),
                      if (!(homeInfo.top10Info == null) && homeInfo.top10Info!.length > 1)
                        ...homeInfo.top10Info!.map((item) {
                          return _oneTen(item);
                        }).toList()
                      else if (!(homeInfo.top10Info == null) && homeInfo.top10Info!.length == 1)
                        ListTile(
                          // title: Text("全站十大", style: _titleFont),
                          title: Text(homeInfo.top10Info![0].title),
                          // isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.login),
                            onPressed: () { Navigator.pushReplacementNamed(context, '/login', arguments: {'needBack': false}); },
                          )
                        ),
                    ]
                  ),
                );
              } else {
                var blockOne = homeInfo.blockInfo[index-1];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(blockOne.blockName, style: _titleFont),
                      const Divider(),
                      if (blockOne.blockItems.isNotEmpty)
                        ...blockOne.blockItems.map((item) {
                          return _oneBlockItem(item);
                        }).toList()
                      else
                        const Text("该分区暂无热门主题帖"),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
