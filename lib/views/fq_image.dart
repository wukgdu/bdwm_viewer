// https://github.com/singerdmx/flutter-quill/blob/master/flutter_quill_extensions/
/*
MIT License

Copyright (c) 2020 Xin Yao

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/extensions.dart' as base;
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill/translations.dart';
import 'package:string_validator/string_validator.dart' show isBase64;

import 'package:flutter/scheduler.dart';

class _SimpleDialogItem extends StatelessWidget {
  const _SimpleDialogItem(
      {required this.icon,
      required this.color,
      required this.text,
      required this.onPressed,
      Key? key})
      : super(key: key);

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 36, color: color),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child:
                Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class ImageResizer extends StatefulWidget {
  const ImageResizer(
      {required this.imageWidth,
      required this.imageHeight,
      required this.maxWidth,
      required this.maxHeight,
      required this.onImageResize,
      Key? key})
      : super(key: key);

  final double? imageWidth;
  final double? imageHeight;
  final double maxWidth;
  final double maxHeight;
  final Function(double, double) onImageResize;

  @override
  State<ImageResizer> createState() => _ImageResizerState();
}

class _ImageResizerState extends State<ImageResizer> {
  late double _width;
  late double _height;

  @override
  void initState() {
    super.initState();
    _width = widget.imageWidth ?? widget.maxWidth;
    _height = widget.imageHeight ?? widget.maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _showCupertinoMenu();
      case TargetPlatform.android:
        return _showMaterialMenu();
      default:
        throw 'Not supposed to be invoked for $defaultTargetPlatform';
    }
  }

  Widget _showMaterialMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_widthSlider(), _heightSlider()],
    );
  }

  Widget _showCupertinoMenu() {
    return CupertinoActionSheet(actions: [
      CupertinoActionSheetAction(
        onPressed: () {},
        child: _widthSlider(),
      ),
      CupertinoActionSheetAction(
        onPressed: () {},
        child: _heightSlider(),
      )
    ]);
  }

  Widget _slider(
      double value, double max, String label, ValueChanged<double> onChanged) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: Slider(
            value: value,
            max: max,
            divisions: 1000,
            label: label.i18n,
            onChanged: (val) {
              setState(() {
                onChanged(val);
                _resizeImage();
              });
            },
          ),
        ));
  }

  Widget _heightSlider() {
    return _slider(_height, widget.maxHeight, 'Height', (value) {
      _height = value;
    });
  }

  Widget _widthSlider() {
    return _slider(_width, widget.maxWidth, 'Width', (value) {
      _width = value;
    });
  }

  bool _scheduled = false;

  void _resizeImage() {
    if (_scheduled) {
      return;
    }

    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onImageResize(_width, _height);
      _scheduled = false;
    });
  }
}

String getImageStyleString(QuillController controller) {
  final String? s = controller
      .getAllSelectionStyles()
      .firstWhere((s) => s.attributes.containsKey(Attribute.style.key),
          orElse: Style.new)
      .attributes[Attribute.style.key]
      ?.value;
  return s ?? '';
}

bool isImageBase64(String imageUrl) {
  return !imageUrl.startsWith('http') && isBase64(imageUrl);
}

String standardizeImageUrl(String url) {
  if (url.contains('base64')) {
    return url.split(',')[1];
  }
  return url;
}

Image imageByUrl(String imageUrl,
    {double? width,
    double? height,
    AlignmentGeometry alignment = Alignment.center}) {
  if (isImageBase64(imageUrl)) {
    return Image.memory(base64.decode(imageUrl),
        width: width, height: height, alignment: alignment);
  }

  if (imageUrl.startsWith('http')) {
    return Image.network(imageUrl,
        width: width, height: height, alignment: alignment);
  }
  return Image.file(io.File(imageUrl),
      width: width, height: height, alignment: alignment);
}

class ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    base.Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    assert(!kIsWeb, 'Please provide image EmbedBuilder for Web');

    late Widget image;
    final imageUrl = standardizeImageUrl(node.value.data);
    OptionalSize? imageSize;
    final style = node.style.attributes['style'];
    if (base.isMobile() && style != null) {
      final attrs = base.parseKeyValuePairs(style.value.toString(), {
        Attribute.mobileWidth,
        Attribute.mobileHeight,
        Attribute.mobileMargin,
        Attribute.mobileAlignment
      });
      if (attrs.isNotEmpty) {
        assert(
            attrs[Attribute.mobileWidth] != null &&
                attrs[Attribute.mobileHeight] != null,
            'mobileWidth and mobileHeight must be specified');
        final w = double.parse(attrs[Attribute.mobileWidth]!);
        final h = double.parse(attrs[Attribute.mobileHeight]!);
        imageSize = OptionalSize(w, h);
        final m = attrs[Attribute.mobileMargin] == null
            ? 0.0
            : double.parse(attrs[Attribute.mobileMargin]!);
        final a = base.getAlignment(attrs[Attribute.mobileAlignment]);
        image = Padding(
            padding: EdgeInsets.all(m),
            child: imageByUrl(imageUrl, width: w, height: h, alignment: a));
      }
    }

    if (imageSize == null) {
      image = imageByUrl(imageUrl);
      imageSize = OptionalSize((image as Image).width, image.height);
    }

    if (!readOnly && base.isMobile()) {
      return GestureDetector(
          onTap: () {
            showDialog(
                context: context,
                builder: (context) {
                  final resizeOption = _SimpleDialogItem(
                    icon: Icons.settings_outlined,
                    color: Colors.lightBlueAccent,
                    text: 'Resize'.i18n,
                    onPressed: () {
                      Navigator.pop(context);
                      showCupertinoModalPopup<void>(
                          context: context,
                          builder: (context) {
                            final screenSize = MediaQuery.of(context).size;
                            return ImageResizer(
                                onImageResize: (w, h) {
                                  final res = getEmbedNode(
                                      controller, controller.selection.start);
                                  final attr = base.replaceStyleString(
                                      getImageStyleString(controller), w, h);
                                  controller
                                    ..skipRequestKeyboard = true
                                    ..formatText(
                                        res.offset, 1, StyleAttribute(attr));
                                },
                                imageWidth: imageSize?.width,
                                imageHeight: imageSize?.height,
                                maxWidth: screenSize.width,
                                maxHeight: screenSize.height);
                          });
                    },
                  );
                  final copyOption = _SimpleDialogItem(
                    icon: Icons.copy_all_outlined,
                    color: Colors.cyanAccent,
                    text: 'Copy'.i18n,
                    onPressed: () {
                      final imageNode =
                          getEmbedNode(controller, controller.selection.start)
                              .value;
                      final imageUrl = imageNode.value.data;
                      controller.copiedImageUrl =
                          ImageUrl(imageUrl, getImageStyleString(controller));
                      Navigator.pop(context);
                    },
                  );
                  final removeOption = _SimpleDialogItem(
                    icon: Icons.delete_forever_outlined,
                    color: Colors.red.shade200,
                    text: 'Remove'.i18n,
                    onPressed: () {
                      final offset =
                          getEmbedNode(controller, controller.selection.start)
                              .offset;
                      controller.replaceText(offset, 1, '',
                          TextSelection.collapsed(offset: offset));
                      Navigator.pop(context);
                    },
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                    child: SimpleDialog(
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        children: [resizeOption, copyOption, removeOption]),
                  );
                });
          },
          child: image);
    }

    // if (!readOnly || !base.isMobile() || isImageBase64(imageUrl)) {
      return image;
    // }

    // We provide option menu for mobile platform excluding base64 image
    // return _menuOptionsForReadonlyImage(context, imageUrl, image);
  }
}
