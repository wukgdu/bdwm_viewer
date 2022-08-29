import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as path;
import 'package:extended_image/extended_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void gotoDetailImage({required BuildContext context, required String link, String? name, Uint8List? imgData}) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => DetailImage(imgLink: link, imgName: name, imgData: imgData,),
  ));
}

class SaveRes {
  bool success = false;
  String reason = "";
  SaveRes(this.success, this.reason);
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

  @override
  initState() {
    super.initState();
    imgLink = widget.imgLink;
    imgName = widget.imgName;
    imgData = widget.imgData;
  }

  @override
  dispose() {
    clearMemoryImageCache();
    // Future.delayed(Duration.zero, () => clearDiskCachedImages());
    Future.microtask(clearDiskCachedImages);
    super.dispose();
  }

  Future<SaveRes> saveImage(Uint8List? data) async {
    Directory? downloadDir;
    String? downloadPath;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        var path = await FilePicker.platform.getDirectoryPath();
        if (path != null) {
          downloadDir = Directory(path);
        }
        break;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: "选择保存路径",
          fileName: (imgName == null || imgName!.isEmpty) ? "image.png" : imgName,
        );
        if (outputFile == null) {
          return SaveRes(false, "未设置保存路径");
        } else {
          downloadPath = outputFile;
        }
        break;
      case TargetPlatform.fuchsia:
      default:
        downloadDir = await getDownloadsDirectory();
    }
    if ((downloadDir == null) && (downloadPath == null)) {
      return SaveRes(false, "未设置保存路径");
    }
    if (downloadDir != null && downloadPath == null) {
      if (!downloadDir.existsSync()) {
        return SaveRes(false, "保存目录不存在");
      }
      downloadPath ??= path.join(downloadDir.path, imgName ?? "image.jpg");
    }
    if (downloadPath == null) {
      return SaveRes(false, "未设置保存路径");
    }
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
    return SaveRes(true, '');
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
                var text = "保存成功";
                if (!res.success) {
                  text = "保存失败：${res.reason}";
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(text),),
                );
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        child: Center(
          // child: Image.network(imgLink),
          child: imgData == null
          ? ExtendedImage.network(
            imgLink,
            fit: BoxFit.fill,
            cache: true,
            enableMemoryCache: true,
            clearMemoryCacheWhenDispose: true,
            clearMemoryCacheIfFailed: true,
            handleLoadingProgress: true,
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
                  return CircularProgressIndicator(
                    value: curByte / sumByte,
                    semanticsLabel: '加载中',
                    semanticsValue: text,
                    backgroundColor: Colors.amberAccent,
                  );
                case LoadState.completed:
                  return null;
                case LoadState.failed:
                  return SelectableText("加载失败：$imgLink");
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
            fit: BoxFit.fill,
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
                  return SelectableText("加载失败：$imgLink");
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
      ),
      // onTap: () {
      //   Navigator.pop(context);
      // },
    );
  }
}
