import 'package:flutter/material.dart';
import 'package:async/async.dart';

import './utils.dart';
import './html_widget.dart' show WrapImageNetwork, innerLinkJump;
import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/top10_parser.dart';
import '../views/constants.dart' show bdwmPrimaryColor;
import '../pages/read_thread.dart';
import '../utils.dart' show getQueryValue;
import '../pages/detail_image.dart';
import '../router.dart' show nv2Replace, nv2Push;

class EntryHomeComponent extends StatefulWidget {
  const EntryHomeComponent({super.key});

  @override
  State<EntryHomeComponent> createState() => _EntryHomeComponentState();
}

class _EntryHomeComponentState extends State<EntryHomeComponent> {
  late CancelableOperation getDataCancelable;
  final textButtonStyle = TextButton.styleFrom(
    minimumSize: const Size(20, 36),
  );

  Future<WelcomeInfo> getWelcomeData() async {
    var resp = await bdwmClient.get("$v2Host/home.php", headers: genHeaders());
    if (resp == null) {
      return WelcomeInfo.error(errorMessage: networkErrorText);
    }
    return parseWelcomeFromHtml(resp.body);
  }

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getWelcomeData());
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    super.dispose();
  }

  AlertDialog genDialog(Widget content) {
    return AlertDialog(
      title: const Text("今日进站"),
      content: content,
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              getDataCancelable.cancel();
              getDataCancelable = CancelableOperation.fromFuture(getWelcomeData());
            });
          },
          style: textButtonStyle,
          child: const Text("刷新"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: textButtonStyle,
          child: const Text("进入未名BBS"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return genDialog(
            const LinearProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return genDialog(
            Text("错误：${snapshot.error}"),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return genDialog(
            const Text("错误：未获取数据"),
          );
        }
        WelcomeInfo welcomeInfo = snapshot.data as WelcomeInfo;
        if (welcomeInfo.errorMessage != null) {
          return genDialog(
            Text(welcomeInfo.errorMessage!),
          );
        }
        if (welcomeInfo.imgLink.isEmpty) {
          return genDialog(
            const Text("错误：未获取图片链接"),
          );
        }
        return AlertDialog(
          title: const Text("今日进站"),
          content: GestureDetector(
            onTap: () {
              gotoDetailImage(context: context, link: welcomeInfo.imgLink);
            },
            child: ColoredBox(
              color: bdwmPrimaryColor,
              child: WrapImageNetwork(imgLink: welcomeInfo.imgLink, useLinearProgress: true, mustClear: true, highQuality: true,),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  getDataCancelable.cancel();
                  getDataCancelable = CancelableOperation.fromFuture(getWelcomeData());
                });
              },
              style: textButtonStyle,
              child: const Text("刷新"),
            ),
            if (welcomeInfo.actionLink.isNotEmpty)
              TextButton(
                onPressed: () async {
                  var value = await showConfirmDialog(context, "打开", welcomeInfo.actionLink);
                  if (value == null || value != "yes") { return; }
                  if (!mounted) { return; }
                  Navigator.of(context).pop();
                  innerLinkJump(welcomeInfo.actionLink, context);
                },
                style: textButtonStyle,
                child: const Text("详情"),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: textButtonStyle,
              child: const Text("进入未名BBS"),
            ),
          ],
        );
      },
    );
  }
}

class TopHomePage extends StatefulWidget {
  const TopHomePage({Key? key}) : super(key: key);

  @override
  State<TopHomePage> createState() => _TopHomePageState();
}

class _TopHomePageState extends State<TopHomePage> {
  final _titleFont = const TextStyle(fontSize: 20, fontWeight: FontWeight.normal);
  final _scrollController = ScrollController();
  late CancelableOperation getDataCancelable;

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
      if (globalConfigInfo.getShowWelcome()==false) { return; }
      String lastLoginTimeStr = globalNotConfigInfo.getLastLoginTime();
      var ld = DateTime.tryParse(lastLoginTimeStr);
      var curDT = DateTime.now();
      // ld = null;
      if (ld==null || "${curDT.year}-${curDT.month}-${curDT.day}" != "${ld.year}-${ld.month}-${ld.day}") {
        if (!mounted) { return; }
        var saveUpdate = globalNotConfigInfo.setLastLoginTime(curDT.toIso8601String());
        showAlertDialog2(context, const EntryHomeComponent(),);
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

  bool gotTop10(List<Top10Item>? top10Info) {
    return top10Info != null && top10Info.isNotEmpty;
  }

  bool isTop10Valid(List<Top10Item> top10Info) {
    if (top10Info.length > 1) {
      return true;
    }
    if (top10Info.length == 1) {
      if (top10Info[0].id == -1) {
        return false;
      }
      return true;
    }
    // wont reach here after gotTop10
    return true;
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
            return LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Text(homeInfo.errorMessage!),
                  ),
                )
              );
            },);
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
                      if (gotTop10(homeInfo.top10Info) && isTop10Valid(homeInfo.top10Info!))
                        ...homeInfo.top10Info!.map((item) {
                          return _oneTen(item);
                        }).toList()
                      else if (gotTop10(homeInfo.top10Info) && !isTop10Valid(homeInfo.top10Info!)) ...[
                        ListTile(
                          // title: Text("全站十大", style: _titleFont),
                          title: Text(homeInfo.top10Info![0].title),
                          // isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.login),
                            onPressed: () { nv2Replace(context, '/login', arguments: {'needBack': false}); },
                          )
                        ),
                      ],
                    ]
                  ),
                );
              } else {
                var blockOne = homeInfo.blockInfo[index-1];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          var bid = getQueryValue(blockOne.blockLink, 'bid');
                          if (bid == null) { return; }
                          nv2Push(context, '/block', arguments: {
                            'bid': bid,
                            'title': blockOne.blockName,
                          },);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(blockOne.blockName, style: _titleFont),
                            const Icon(Icons.arrow_right),
                          ],
                        ),
                      ),
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
