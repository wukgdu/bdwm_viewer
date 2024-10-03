import 'package:flutter/material.dart';
import 'package:async/async.dart';

import './utils.dart' show showConfirmDialog, showAlertDialog2, genScrollableWidgetForPullRefresh;
import './html_widget.dart' show WrapImageNetwork, innerLinkJump;
import '../bdwm/req.dart';
import '../globalvars.dart';
import '../html_parser/top10_parser.dart';
import '../views/constants.dart' show bdwmPrimaryColor;
import '../pages/read_thread.dart';
import '../utils.dart' show getQueryValue, breakLongText;
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
                  if (!context.mounted) { return; }
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

class OneTenComponent extends StatelessWidget {
  final Top10Item item;
  const OneTenComponent({super.key, required this.item});

  Color genTenColor(int itemID) {
    if (itemID == 1) { return const Color(0xffea6242); }
    else if (itemID == 2) { return const Color(0xfff7a95e); }
    else if (itemID == 3) { return const Color(0xfff8d0ab); }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          breakLongText(item.title),
          textAlign: TextAlign.start,
          overflow: globalConfigInfo.getShowDetailInCard() ? null : TextOverflow.ellipsis,
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
            color: genTenColor(item.id),
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
}

class OneBlockComponent extends StatelessWidget {
  final BlockItem item;
  const OneBlockComponent({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          breakLongText(item.title),
          textAlign: TextAlign.start,
          overflow: globalConfigInfo.getShowDetailInCard() ? null : TextOverflow.ellipsis,
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
}

class BlocksComponent extends StatelessWidget {
  final BlockOne blockOne;
  final TextStyle? titleFont;
  const BlocksComponent({super.key, required this.blockOne, this.titleFont});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // const Divider(),
        const SizedBox(height: 5,),
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
              Text(blockOne.blockName, style: titleFont),
              const Icon(Icons.arrow_right),
            ],
          ),
        ),
        if (blockOne.blockItems.isNotEmpty)
          ...blockOne.blockItems.map((item) {
            return RepaintBoundary(
              child: OneBlockComponent(item: item),
            );
          })
        else ...[
          const Card(child: Center(child: Text("该分区暂无热门主题帖"),),),
        ],
      ],
    );
  }
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

class TensComponent extends StatelessWidget {
  final HomeInfo homeInfo;
  final TextStyle? titleFont;
  const TensComponent({super.key, required this.homeInfo, this.titleFont});

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("全站十大", style: titleFont),
        // const Divider(),
        if (gotTop10(homeInfo.top10Info) && isTop10Valid(homeInfo.top10Info!))
          ...homeInfo.top10Info!.map((item) {
            return RepaintBoundary(
              child: OneTenComponent(item: item),
            );
          })
        else if (gotTop10(homeInfo.top10Info) && !isTop10Valid(homeInfo.top10Info!)) ...[
          Card(
            child: ListTile(
              onTap: () {
                nv2Replace(context, '/login', arguments: {'needBack': false});
              },
              // title: Text("全站十大", style: _titleFont),
              title: Text(homeInfo.top10Info![0].title),
              // isThreeLine: true,
              trailing: const Icon(Icons.login),
            ),
          ),
        ],
      ]
    );
  }
}

class TopHomeView extends StatefulWidget {
  const TopHomeView({super.key});

  @override
  State<TopHomeView> createState() => _TopHomeViewState();
}

Future<HomeInfo> getDataTop10() async {
  var resp = await bdwmClient.get("$v2Host/mobile/home.php", headers: genHeaders());
  if (resp == null) {
    return HomeInfo.error(errorMessage: networkErrorText);
  }
  return parseHome(resp.body);
}

class _TopHomeViewState extends State<TopHomeView> {
  final _titleFont = const TextStyle(fontSize: 20, fontWeight: FontWeight.normal);
  final _scrollController = ScrollController();
  late CancelableOperation getDataCancelable;

  @override
  void initState() {
    super.initState();
    // homeInfo = getExampleHomeInfo();
    getDataCancelable = CancelableOperation.fromFuture(getDataTop10(), onCancel: () {});
    // _scrollController.addListener(() {
    //   debugPrint(_scrollController.offset);
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (globalConfigInfo.getShowWelcome()) {
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
      }
    });
  }

  Future<void> updateData() async {
    if (!mounted) { return; }
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getDataTop10(), onCancel: () {});
    });
  }

  @override
  void dispose() {
    getDataCancelable.cancel();
    _scrollController.dispose();
    super.dispose();
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
            return genScrollableWidgetForPullRefresh(
              Center(
                child: Text(homeInfo.errorMessage!),
              ),
            );
          }
          // return ListView.builder(
          //   controller: _scrollController,
          //   // padding: const EdgeInsets.all(8),
          //   itemCount: homeInfo.blockInfo.length+1,
          //   itemBuilder: (context, index) {
          //     if (index==0) {
          //       return TensComponent(homeInfo: homeInfo, titleFont: _titleFont,);
          //     } else {
          //       var blockOne = homeInfo.blockInfo[index-1];
          //       return BlocksComponent(blockOne: blockOne, titleFont: _titleFont,);
          //     }
          //   },
          // );
          // return ListView(
          //   controller: _scrollController,
          //   // padding: const EdgeInsets.all(8),
          //   children: [
          //     TensComponent(homeInfo: homeInfo, titleFont: _titleFont,),
          //     ...homeInfo.blockInfo.map((blockOne) {
          //       return BlocksComponent(blockOne: blockOne, titleFont: _titleFont,);
          //     }),
          //   ],
          // );
          return SingleChildScrollView(
            controller: _scrollController,
            // padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TensComponent(homeInfo: homeInfo, titleFont: _titleFont,),
                ...homeInfo.blockInfo.map((blockOne) {
                  return BlocksComponent(blockOne: blockOne, titleFont: _titleFont,);
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
