import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_quill/flutter_quill.dart' as fquill;
import 'package:flutter_quill_extensions/embeds/builders.dart' show ImageEmbedBuilder;

import '../bdwm/mail.dart';
import '../views/html_widget.dart';
import '../bdwm/req.dart';
import './constants.dart';
import '../globalvars.dart';
// import '../html_parser/postnew_parser.dart';
import './utils.dart';

class MailNewPage extends StatefulWidget {
  final String? parentid;
  const MailNewPage({super.key, required this.parentid});

  @override
  State<MailNewPage> createState() => _MailNewPageState();
}

class _MailNewPageState extends State<MailNewPage> {
  final fquill.QuillController _controller = fquill.QuillController.basic();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          TextButton(
            onPressed: () {
              print(_controller.document.toDelta().toJson());
            },
            child: const Text("show deltas"),
          ),
          fquill.QuillToolbar.basic(
            controller: _controller,
            toolbarSectionSpacing: 1,
            showAlignmentButtons: false,
            showBoldButton: true,
            showUnderLineButton: true,
            showStrikeThrough: false,
            showDirection: false,
            showFontFamily: false,
            showFontSize: false,
            showHeaderStyle: false,
            showIndent: false,
            showLink: false,
            showSearchButton: false,
            showListBullets: false,
            showListNumbers: false,
            showListCheck: false,
            showDividers: false,
            showRightAlignment: false,
            showItalicButton: false,
            showCenterAlignment: false,
            showLeftAlignment: false,
            showJustifyAlignment: false,
            showSmallButton: false,
            showInlineCode: false,
            showCodeBlock: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            customButtons: [
              fquill.QuillCustomButton(
                icon: Icons.color_lens,
                onTap: () {
                  showColorDialog(context, (bdwmRichText['fc'] as Map<String, int>).keys.toList())
                  .then((value) {
                    if (value == null) { return; }
                    _controller.formatSelection(fquill.ColorAttribute(value));
                  });
                }
              ),
              fquill.QuillCustomButton(
                icon: Icons.format_color_fill,
                onTap: () {
                  showColorDialog(context, (bdwmRichText['bc'] as Map<String, int>).keys.toList())
                  .then((value) {
                    if (value == null) { return; }
                    _controller.formatSelection(fquill.BackgroundAttribute(value));
                  });
                }
              ),
              fquill.QuillCustomButton(
                icon: Icons.image,
                onTap: () {
                  showTextDialog(context, "图片链接")
                  .then((value) {
                    if (value==null) { return; }
                    if (value.isEmpty) { return; }
                    var index = _controller.selection.baseOffset;
                    var length = _controller.selection.extentOffset - index;
                    print(value);
                    _controller.replaceText(index, length, fquill.BlockEmbed.image(value), null);
                  },);
                }
              ),
            ],
          ),
          Expanded(
            child: Card(
              child: fquill.QuillEditor.basic(
                controller: _controller,
                readOnly: false, // true for view only mode
                embedBuilders: [ImageEmbedBuilder()],
                // locale: const Locale('zh', 'CN'),
              ),
            ),
          )
        ],
      )
    );
  }
}