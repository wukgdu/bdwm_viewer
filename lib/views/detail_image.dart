import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';

void gotoDetailImage(BuildContext context, String link) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => DetailImage(imgLink: link),
  ));
}
class DetailImage extends StatelessWidget {
  final String imgLink;
  const DetailImage({Key? key, required this.imgLink}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("图片"),
      ),
      body: GestureDetector(
        child: Center(
          child: Hero(
            tag: 'imageHero',
            // child: Image.network(imgLink),
            child: ExtendedImage.network(
              imgLink,
              fit: BoxFit.fill,
              cache: false,
              // clearMemoryCacheWhenDispose: true,
              clearMemoryCacheIfFailed: true,
              handleLoadingProgress: true,
              loadStateChanged: (ExtendedImageState state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    var curByte = state.loadingProgress?.cumulativeBytesLoaded ?? 0;
                    var sumByte = state.loadingProgress?.expectedTotalBytes ?? -1;
                    if (sumByte == -1) {
                      return const Text("加载中");
                    }
                    return Text("${(curByte * 100 / sumByte).toStringAsFixed(0)}%");
                    break;
                  case LoadState.completed:
                    break;
                  case LoadState.failed:
                    return SelectableText("加载失败：$imgLink");
                    break;
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
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
