import 'dart:io' show File;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import './detail_image.dart' show gotoDetailImage;
import '../views/funfunfun.dart' show formatSize;
import '../views/utils.dart' show getOptOptions, SimpleTuple2;
import '../globalvars.dart' show globalConfigInfo;

class CachedImagesPage extends StatefulWidget {
  final List<File> files;
  const CachedImagesPage({super.key, required this.files});

  @override
  State<CachedImagesPage> createState() => _CachedImagesPageState();
}

class _CachedImagesPageState extends State<CachedImagesPage> {
  List<String> fileNames = [];
  List<File> files = [];
  String sortMethod = "time";
  static const thumbnailHeight = 150.0;

  @override
  void initState() {
    super.initState();
    files = widget.files;
    sortByTime();
    fileNames = files.map((e) => "${path.basename(e.path)}.jpg").toList();
  }

  void sortByTime() {
    files.sort((a, b) {
      return b.statSync().modified.compareTo(a.statSync().modified);
    },);
  }

  void sortBySize() {
    files.sort((a, b) {
      return b.statSync().size.compareTo(a.statSync().size);
    },);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("缓存图片"),
        actions: [
          IconButton(
            onPressed: () {
              if (sortMethod == "time") {
                sortMethod = "size";
                sortBySize();
              } else if (sortMethod == "size") {
                sortMethod = "time";
                sortByTime();
              } else {
                sortMethod = "time";
                sortByTime();
              }
              setState(() { });
            },
            icon: sortMethod == "time"
            ? const Icon(Icons.sort)
            : sortMethod == "size"
            ? const Icon(Icons.access_time)
            : const Icon(Icons.question_mark),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          var f = files[index];
          var fstat = f.statSync();
          return Card(
            child: ListTile(
              title: Text(fileNames[index]),
              subtitle: Text("${fstat.modified.toString().split(".")[0]} ${formatSize(fstat.size)} ${index+1}/${files.length}"),
              onTap: () {
                gotoDetailImage(context: context, link: "",
                  imgNames: fileNames,
                  imgFiles: files,
                  curIdx: index,
                );
              },
              onLongPress: () async {
                var opt = await getOptOptions(context, [
                  SimpleTuple2(name: "删除", action: "delete"),
                  SimpleTuple2(name: "取消", action: "cancel"),
                ], desc: Container(
                    constraints: const BoxConstraints(maxHeight: thumbnailHeight),
                    alignment: Alignment.center,
                    child: ExtendedImage.file(
                      f,
                      clearMemoryCacheWhenDispose: true,
                      clearMemoryCacheIfFailed: true,
                      height: globalConfigInfo.getHighQualityPreview() ? null : thumbnailHeight,
                      cacheHeight: globalConfigInfo.getHighQualityPreview() ? null : thumbnailHeight.toInt(),
                    ),
                  ),
                );
                if (opt == null) { return; }
                if (opt == "delete") {
                  files.remove(f);
                  await f.delete(recursive: true);
                  setState(() {
                    fileNames = files.map((e) => "${path.basename(e.path)}.jpg").toList();
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }
}
