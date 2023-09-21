import 'dart:io';

import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../html_parser/top10_parser.dart';
import '../utils.dart';
import '../html_parser/read_thread_parser.dart';
import '../globalvars.dart';
import "./utils.dart";
import "./search.dart" show PostSearchSettings;
import '../router.dart' show nv2Push;

class BigTenComponent extends StatefulWidget {
  const BigTenComponent({super.key});

  @override
  State<BigTenComponent> createState() => _BigTenComponentState();
}

class _BigTenComponentState extends State<BigTenComponent> {
  bool showBigTen = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: () {
            if (showBigTen == true) {
              setState(() {
                showBigTen = false;
              });
              return;
            }
            showConfirmDialog(context, "十大拍照", "将要读取当前十大每个帖子的首页").then((value) {
              if (value == null) { return; }
              if (value == "yes") {
                if (!mounted) { return; }
                setState(() {
                  showBigTen = true;
                });
              }
            });
          },
          title: const Text("十大拍照（term）"),
          trailing: const Icon(Icons.arrow_drop_down),
        ),
        if (showBigTen) ...[
          const Divider(),
          const BigTenDetailComponent(),
        ],
      ],
    );
  }
}

class BigTenDetailComponent extends StatefulWidget {
  const BigTenDetailComponent({super.key});

  @override
  State<BigTenDetailComponent> createState() => _BigTenDetailComponentState();
}

class _BigTenDetailComponentState extends State<BigTenDetailComponent> {
  late CancelableOperation getDataCancelable;
  static const monthTrans = {
    "01": "Jan", "02": "Feb", "03": "Mar", "04": "Apr", "05": "May", "06": "Jun",
    "07": "Jul", "08": "Aug", "09": "Sep", "10": "Oct", "11": "Nov", "12": "Dec",
  };

  @override
  void initState() {
    getDataCancelable = CancelableOperation.fromFuture(genWidget(), onCancel: () { });
    super.initState();
  }

  Future<Widget> genWidget() async {
    var resp = await bdwmClient.get("$v2Host/mobile/home.php", headers: genHeaders());
    if (resp == null) {
      return const Center(child: Text(networkErrorText),);
    }
    var top10List = parseBigTen(resp.body);
    if (top10List == null) {
      return const Center(child: Text("获取十大失败"),);
    }
    List<String> urls = [];
    for (var tl in top10List) {
      var link = tl.link;
      var bid = getQueryValue(link, "bid");
      var threadid = getQueryValue(link, "threadid");
      if (bid==null || threadid==null) {
        return const Center(child: Text("获取十大失败"),);
      }
      var url = "$v2Host/post-read.php?bid=$bid&threadid=$threadid";
      urls.add(url);
    }
    var respList = await Future.wait(urls.map((e) => bdwmClient.get(e, headers: genHeaders2())));
    if (respList.length != 10) {
      return const Center(child: Text("获取十大失败"),);
    }
    var boardEngName = <String>[];
    var titleName = <String>[];
    var authorName = <String>[];
    var timeStr = <String>[];
    for (var r in respList) {
      if (r==null) {
        return const Center(child: Text("获取十大失败"),);
      }
      var threadInfo = parseThread(r.body, simple: true);
      if (threadInfo.errorMessage != null) {
        return const Center(child: Text("获取十大失败"),);
      }
      var boardName1 = threadInfo.board.text;
      boardName1 = boardName1.split("(").last;
      boardName1 = boardName1.substring(0, boardName1.length-1); // )
      boardName1 = boardName1.padRight(20);
      boardEngName.add(boardName1);
      var authorName1 = threadInfo.posts[0].authorInfo.userName;
      authorName1 = authorName1.padLeft(19);
      authorName.add(authorName1);
      var titleName1 = threadInfo.title;
      var titleLength = termStringLength(titleName1);
      if (titleLength < 62) {
        titleName1 += " "*(62-titleLength);
      }
      titleName.add(titleName1);
      // "2022-09-16 01:41:06" -> "Sep.13 22:59:53"
      var timeStrTmp = threadInfo.posts[0].postTime;
      var timeDate = timeStrTmp.split(" ").first;
      var timeMonth = timeDate.split("-")[1];
      var timeDay = timeDate.split("-")[2];
      var timeStr1 = "${monthTrans[timeMonth] ?? "UKN"}.$timeDay ${timeStrTmp.split(" ").last}";
      timeStr.add(timeStr1);
    }
    return SelectableText('''                [1;34m-----[37m=====[41;37m 本日十大热门话题 [0;1;37m=====[34m-----[0;37m                    [m

[1;30m第 [31m 1[30m 名 信区 : [33m${boardEngName[0]}[0;37m【[1;32m${timeStr[0]}[0;37m】[1;35m${authorName[0]}[m
[1m     标题 : [44;37m${titleName[0]}[m
[1;30m第 [31m 2[30m 名 信区 : [33m${boardEngName[1]}[0;37m【[1;32m${timeStr[1]}[0;37m】[1;35m${authorName[1]}[m
[1m     标题 : [44;37m${titleName[1]}[m
[1;30m第 [31m 3[30m 名 信区 : [33m${boardEngName[2]}[0;37m【[1;32m${timeStr[2]}[0;37m】[1;35m${authorName[2]}[m
[1m     标题 : [44;37m${titleName[2]}[m
[1;30m第 [31m 4[30m 名 信区 : [33m${boardEngName[3]}[0;37m【[1;32m${timeStr[3]}[0;37m】[1;35m${authorName[3]}[m
[1m     标题 : [44;37m${titleName[3]}[m
[1;30m第 [31m 5[30m 名 信区 : [33m${boardEngName[4]}[0;37m【[1;32m${timeStr[4]}[0;37m】[1;35m${authorName[4]}[m
[1m     标题 : [44;37m${titleName[4]}[m
[1;30m第 [31m 6[30m 名 信区 : [33m${boardEngName[5]}[0;37m【[1;32m${timeStr[5]}[0;37m】[1;35m${authorName[5]}[m
[1m     标题 : [44;37m${titleName[5]}[m
[1;30m第 [31m 7[30m 名 信区 : [33m${boardEngName[6]}[0;37m【[1;32m${timeStr[6]}[0;37m】[1;35m${authorName[6]}[m
[1m     标题 : [44;37m${titleName[6]}[m
[1;30m第 [31m 8[30m 名 信区 : [33m${boardEngName[7]}[0;37m【[1;32m${timeStr[7]}[0;37m】[1;35m${authorName[7]}[m
[1m     标题 : [44;37m${titleName[7]}[m
[1;30m第 [31m 9[30m 名 信区 : [33m${boardEngName[8]}[0;37m【[1;32m${timeStr[8]}[0;37m】[1;35m${authorName[8]}[m
[1m     标题 : [44;37m${titleName[8]}[m
[1;30m第 [31m10[30m 名 信区 : [33m${boardEngName[9]}[0;37m【[1;32m${timeStr[9]}[0;37m】[1;35m${authorName[9]}[m
[1m     标题 : [44;37m${titleName[9]}[m
''');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
        return snapshot.data as Widget;
      }
    );
  }
}

String formatSize(int bytes) {
  List<String> units = <String>["B", "KB", "MB", "GB"];
  double res = bytes.toDouble();
  int i = 0;
  for (; i<units.length-1; i+=1) {
    double res1 = res / 1024;
    if (res1 < 1.0) {
      break;
    }
    res = res1;
  }
  return "${res.toStringAsFixed(3)} ${units[i]}";
}

int computeMemoryImageCache() {
  var imageCache = getMemoryImageCache();
  if (imageCache == null) { return 0; }
  return imageCache.currentSizeBytes;
}

Future<int> computeDiskImageCache() async {
  final Directory cacheImagesDirectory = Directory(
    path.join((await getTemporaryDirectory()).path, cacheImageFolderName));
  if (!cacheImagesDirectory.existsSync()) {
    return 0;
  }
  var files = cacheImagesDirectory.listSync();
  int res = 0;
  for (var f in files) {
    res += (f.statSync()).size;
  }
  return res;
}

Future<List<File>> getLocalCachedImageFiles() async {
  var files = <File>[];
  final Directory cacheImagesDirectory = Directory(
    path.join((await getTemporaryDirectory()).path, cacheImageFolderName));
  if (cacheImagesDirectory.existsSync()) {
    var cachedFiles = cacheImagesDirectory.listSync();
    for (var f in cachedFiles) {
      files.add(File(f.path));
    }
  }
  return files;
}

class ImageCacheComponent extends StatefulWidget {
  const ImageCacheComponent({super.key});

  @override
  State<ImageCacheComponent> createState() => _ImageCacheComponentState();
}

class _ImageCacheComponentState extends State<ImageCacheComponent> {
  int cacheSizeBytes = 0;
  late CancelableOperation futureDiskSize;

  @override
  void initState() {
    super.initState();
    cacheSizeBytes = computeMemoryImageCache();
    futureDiskSize = CancelableOperation.fromFuture(computeDiskImageCache(), onCancel: () { });
  }

  @override
  void dispose() {
    futureDiskSize.cancel();
    super.dispose();
  }

  void clearAllImages() {
    clearAllExtendedImageCache(really: true);
    setState(() {
      cacheSizeBytes = computeMemoryImageCache();
      futureDiskSize.cancel().then((_) {
        futureDiskSize = CancelableOperation.fromFuture(computeDiskImageCache(), onCancel: () { });
      });
    });
  }

  void clearImagesInMemory() {
    clearMemoryImageCache();
    setState(() {
      cacheSizeBytes = computeMemoryImageCache();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        var opt = await getOptOptions(context, [
          SimpleTuple2(name: "清除所有图片缓存", action: "clearAll"),
          SimpleTuple2(name: "清除内存中的图片缓存", action: "clearMemory"),
          SimpleTuple2(name: "查看缓存图片", action: "see"),
        ]);
        if (opt == null) { return; }
        if (opt == "clearAll") {
          clearAllImages();
        } else if (opt == "clearMemory") {
          clearImagesInMemory();
        } else if (opt == "see") {
          var imageFiles = await getLocalCachedImageFiles();
          if (!mounted) { return; }
          nv2Push(context, '/cachedImages', arguments: {
            'files': imageFiles,
          });
        }
      },
      onLongPress: () {
        showInformDialog(context, "提示", "短按弹出选项，长按弹出此提示；短按右侧图标清除所有图片缓存，长按清除内存中的图片缓存");
      },
      isThreeLine: false,
      title: const Text("图片缓存"),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: "内存：${formatSize(cacheSizeBytes)}"),
            const TextSpan(text: "；"),
            WidgetSpan(
              child: FutureBuilder(
                future: futureDiskSize.value,
                builder:(context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Text("硬盘：计算中");
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text("硬盘：计算失败");
                  }
                  int diskSize = snapshot.data as int;
                  return Text("硬盘：${diskSize==0?"":">"}${formatSize(diskSize)}");
                },
              ),
            ),
          ]
        ),
      ),
      trailing: GestureDetector(
        onTap: () {
          clearAllImages();
        },
        onLongPress: () {
          clearImagesInMemory();
        },
        child: const Icon(Icons.cleaning_services, color: null,),
      )
    );
  }
}

class FunFunFunView extends StatelessWidget {
  const FunFunFunView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Card(
          child: BigTenComponent(),
        ),
        Card(
          child: ListTile(
            onTap: () {
              nv2Push(context, '/seeNoThem');
            },
            title: const Text("不看ta"),
            trailing: const Icon(Icons.arrow_right),
          )
        ),
        Card(
          child: ListTile(
            onTap: () {
              nv2Push(context, '/friendsPosts');
            },
            title: const Text("朋友动态"),
            trailing: const Icon(Icons.arrow_right),
          )
        ),
        Card(
          child: ListTile(
            onTap: () {
              nv2Push(context, '/userStat');
            },
            title: const Text("个人统计数据"),
            trailing: const Icon(Icons.arrow_right),
          )
        ),
        Card(
          child: ListTile(
            title: const Text("我的发帖"),
            subtitle: const Text("使用高级搜索"),
            trailing: const Icon(Icons.arrow_right),
            onTap: () {
              PostSearchSettings pss = PostSearchSettings.empty();
              pss.days = "99999";
              pss.owner = globalUInfo.username;
              nv2Push(context, "/complexSearchResult", arguments: {
                "settings": pss,
              });
            }
          ),
        ),
        Card(
          child: ListTile(
            onTap: () {
              nv2Push(context, '/postHistory');
            },
            title: const Text("我的发帖"),
            subtitle: Text("本地记录 ${globalPostHistoryData.items.length}条"),
            trailing: const Icon(Icons.arrow_right),
          ),
        ),
        Card(
          child: ListTile(
            onTap: () {
              nv2Push(context, '/recentThread');
            },
            title: const Text("最近浏览"),
            subtitle: Text("${globalThreadHistory.count}/${globalThreadHistory.maxCount}"),
            trailing: const Icon(Icons.arrow_right),
          )
        ),
        Card(
          child: ListTile(
            onTap: () {
              nv2Push(context, '/markedThread');
            },
            title: const Text("已收藏"),
            subtitle: Text("${globalMarkedThread.count}/${globalMarkedThread.maxCount}"),
            trailing: const Icon(Icons.arrow_right),
          )
        ),
        Card(
          child: ListTile(
            onTap: () {
              nv2Push(context, '/compareIP');
            },
            title: const Text("对比IP"),
            trailing: const Icon(Icons.arrow_right),
          )
        ),
        const Card(
          child: ImageCacheComponent(),
        ),
        Card(
          child: ListTile(
            onTap: () {
              nv2Push(context, '/settings');
            },
            title: const Text("设置"),
            trailing: const Icon(Icons.arrow_right),
          )
        ),
      ],
    );
  }
}
