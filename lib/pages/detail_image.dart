import 'dart:io';

import 'package:bdwm_viewer/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:extended_image/extended_image.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils.dart';
import '../views/utils.dart' show SaveRes, genDownloadPath;

void gotoDetailImage({required BuildContext context, required String link, String? name, Uint8List? imgData}) {
  nv2Push(context, '/detailImage', arguments: {
    'link': link,
    'name': name,
    'imgData': imgData,
  });
}

class DetailImage extends StatefulWidget {
  final String imgLink;
  final String? imgName;
  final Uint8List? imgData;
  const DetailImage({Key? key, required this.imgLink, this.imgName, this.imgData}) : super(key: key);

  @override
  State<DetailImage> createState() => _DetailImageState();
}

class _DetailImageState extends State<DetailImage> {
  String imgLink = "";
  String? imgName;
  Uint8List? imgData;
  CancellationToken cancelIt = CancellationToken();

  @override
  initState() {
    super.initState();
    imgLink = widget.imgLink;
    imgName = widget.imgName;
    imgData = widget.imgData;
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

  Future<SaveRes> saveImage(Uint8List? data) async {
    var couldStore = await checkAndRequestPermission(Permission.storage);
    if (couldStore == false) {
      return SaveRes(false, "没有保存文件权限");
    }
    var saveRes = await genDownloadPath(name: imgName);
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
        File(downloadPath).writeAsBytesSync(imgData);
        break;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      default:
        File(downloadPath).writeAsBytesSync(imgData);
        // await ImageGallerySaver.saveImage(
        //   imgData,
        //   quality: 100,
        //   name: downloadPath,
        // );
    }
    return SaveRes(true, downloadPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("图片"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              saveImage(imgData).then((res) {
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
      body: Center(
        // child: Image.network(imgLink),
        child: imgData == null
        ? ExtendedImage.network(
          imgLink,
          fit: BoxFit.contain,
          cache: true,
          enableMemoryCache: true,
          clearMemoryCacheWhenDispose: true,
          clearMemoryCacheIfFailed: true,
          handleLoadingProgress: true,
          filterQuality: FilterQuality.high,
          cancelToken: cancelIt,
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
              inPageView: false,
              initialAlignment: InitialAlignment.center,
            );
          },
        )
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
