import 'dart:io';

import '../router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:extended_image/extended_image.dart';

import '../utils.dart';
import '../views/utils.dart' show SaveRes, genDownloadPath, showDownloadMenu;

void gotoDetailImage({
  required BuildContext context, required String link, String? name, Uint8List? imgData,
  List<String>? imgLinks, List<String>? imgNames, int? curIdx,
}) {
  nv2Push(context, '/detailImage', arguments: {
    'link': link,
    'name': name,
    'imgData': imgData,
    'imgLinks': imgLinks,
    'imgNames': imgNames,
    'curIdx': curIdx,
  });
}

class DetailImage extends StatefulWidget {
  final String imgLink;
  final String? imgName;
  final Uint8List? imgData;
  final List<String>? imgLinks;
  final List<String>? imgNames;
  final int? curIdx;
  const DetailImage({Key? key, required this.imgLink, this.imgName, this.imgData, this.imgLinks, this.imgNames, this.curIdx}) : super(key: key);

  @override
  State<DetailImage> createState() => _DetailImageState();
}

class _DetailImageState extends State<DetailImage> {
  String imgLink = "";
  String? imgName;
  Uint8List? imgData;
  CancellationToken cancelIt = CancellationToken();
  int currentIdx = 0;

  @override
  initState() {
    super.initState();
    imgLink = widget.imgLink;
    imgName = widget.imgName;
    imgData = widget.imgData;
    currentIdx = widget.curIdx ?? -1;
  }

  @override
  dispose() {
    cancelIt.cancel();
    // clearMemoryImageCache();
    // Future.microtask(clearDiskCachedImages);
    if (imgLink.isNotEmpty) {
      clearOneExtendedImageCache(imgLink);
    }
    super.dispose();
  }

  Future<SaveRes> saveImage({Uint8List? data, String imgLink="", String? imgName}) async {
    var fname = imgName ?? (imgLink.isNotEmpty ? path.basename(imgLink) : null);
    if (imgLink.contains('src=http')) {
      // link by image search
      // https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fitem%2F201808%2F05%2F20180805210613_vfkly.thumb.400_0.jpg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1669211472&t=c52b46d44ccfb31377fe526bfb29019a
      var src = getQueryValue(imgLink, 'src');
      if (src == null) {
        fname = null;
      } else {
        fname = path.basename(Uri.decodeFull(src));
      }
    }
    var saveRes = await genDownloadPath(name: fname);
    if (saveRes.success == false) {
      return saveRes;
    }
    var downloadPath = saveRes.reason;
    debugPrint(downloadPath);

    var imgData = data;
    if (imgData == null) {
      imgData = await getNetworkImageData(imgLink, useCache: true);
      if (imgData == null) {
        return SaveRes(false, "图片未缓存完成");
      }
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      default:
        try {
          File(downloadPath).writeAsBytesSync(imgData);
        } on FileSystemException catch (_) {
          var curTime = DateTime.now().toIso8601String().replaceAll(":", "_");
          curTime = curTime.split(".").first;
          var newName = "OBViewer-$curTime.jpg";
          downloadPath = path.join(path.dirname(downloadPath), newName);
          File(downloadPath).writeAsBytesSync(imgData);
        } catch (e) {
          return SaveRes(false, e.toString());
        }
        // await ImageGallerySaver.saveImage(
        //   imgData,
        //   quality: 100,
        //   name: downloadPath,
        // );
    }
    return SaveRes(true, downloadPath);
  }

  ExtendedImage genNetworkImage(String imgLink, {bool inPageView=false}) {
    return ExtendedImage.network(
      imgLink,
      fit: BoxFit.contain,
      cache: true,
      enableMemoryCache: true,
      clearMemoryCacheWhenDispose: true,
      clearMemoryCacheIfFailed: true,
      handleLoadingProgress: true,
      filterQuality: FilterQuality.high,
      cancelToken: currentIdx >= 0 ? null : cancelIt,
      // timeLimit: const Duration(seconds: 60),
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            var curByte = state.loadingProgress?.cumulativeBytesLoaded ?? 0;
            var sumByte = state.loadingProgress?.expectedTotalBytes ?? -1;
            if (sumByte == -1) {
              return const Text("加载中");
            }
            var text = "${(curByte * 100 / sumByte).toStringAsFixed(0)}%";
            // return Text(text);
            return CircularProgressIndicator(
              value: curByte / sumByte,
              semanticsLabel: '加载中',
              semanticsValue: text,
              backgroundColor: Colors.amberAccent,
            );
          case LoadState.completed:
            return null;
          case LoadState.failed:
            return Center(child: SelectableText("加载失败：$imgLink"));
          default:
            return null;
        }
      },
      mode: ExtendedImageMode.gesture,
      initGestureConfigHandler: (state) {
        return GestureConfig(
          minScale: 1.0,
          animationMinScale: 0.7,
          maxScale: 3.0,
          animationMaxScale: 3.5,
          speed: 1.0,
          inertialSpeed: 100.0,
          initialScale: 1.0,
          inPageView: inPageView,
          initialAlignment: InitialAlignment.center,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.imgLinks == null
        ? const Text("图片")
        : Text("图片：↤${currentIdx+1}/${widget.imgLinks!.length}↦"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              saveImage(data: imgData,
                imgLink: currentIdx >= 0 ? widget.imgLinks![currentIdx] : imgLink,
                imgName: currentIdx >= 0 ? widget.imgNames![currentIdx] : imgName,
              ).then((res) {
                var text = "保存成功：${res.reason}";
                if (!res.success) {
                  text = "保存失败：${res.reason}";
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(text), duration: const Duration(milliseconds: 2000),),
                );
              });
            },
          ),
        ],
      ),
      body: widget.imgLinks != null
      ? ExtendedImageGesturePageView.builder(
        itemCount: widget.imgLinks!.length,
        scrollDirection: Axis.horizontal,
        controller: ExtendedPageController(initialPage: currentIdx),
        itemBuilder:(context, index) {
          return Center(
            child: GestureDetector(
              onLongPress: () async {
                var doIt = await showDownloadMenu(context, widget.imgLinks![index]);
                if (doIt == null || doIt != "yes") { return; }
                saveImage(imgLink: widget.imgLinks![currentIdx], imgName: widget.imgNames![currentIdx],).then((res) {
                  var text = "保存成功：${res.reason}";
                  if (!res.success) {
                    text = "保存失败：${res.reason}";
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(text), duration: const Duration(milliseconds: 2000),),
                  );
                });
              },
              child: genNetworkImage(widget.imgLinks![index], inPageView: true),
            ),
          );
        },
        onPageChanged: (int newIndex) {
          setState(() {
            currentIdx = newIndex;
          });
        },
      )
      : Center(
        // child: Image.network(imgLink),
        child: imgData == null
        ? genNetworkImage(imgLink)
        : ExtendedImage.memory(
          imgData!,
          fit: BoxFit.contain,
          enableMemoryCache: true,
          clearMemoryCacheWhenDispose: true,
          clearMemoryCacheIfFailed: true,
          filterQuality: FilterQuality.high,
          loadStateChanged: (ExtendedImageState state) {
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                var curByte = state.loadingProgress?.cumulativeBytesLoaded ?? 0;
                var sumByte = state.loadingProgress?.expectedTotalBytes ?? -1;
                if (sumByte == -1) {
                  return const Text("加载中");
                }
                var text = "${(curByte * 100 / sumByte).toStringAsFixed(0)}%";
                // return Text(text);
                return LinearProgressIndicator(
                  value: curByte / sumByte,
                  semanticsLabel: '加载中',
                  semanticsValue: text,
                  backgroundColor: Colors.amberAccent,
                );
              case LoadState.completed:
                return null;
              case LoadState.failed:
                return Center(child: SelectableText("加载失败：$imgLink"));
              default:
                return null;
            }
          },
          mode: ExtendedImageMode.gesture,
          initGestureConfigHandler: (state) {
            return GestureConfig(
              minScale: 1.0,
              animationMinScale: 0.7,
              maxScale: 3.0,
              animationMaxScale: 3.5,
              speed: 1.0,
              inertialSpeed: 100.0,
              initialScale: 1.0,
              inPageView: false,
              initialAlignment: InitialAlignment.center,
            );
          },
        ),
      ),
    );
  }
}
