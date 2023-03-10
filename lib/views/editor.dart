import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as fquill;
import 'package:flutter_quill_extensions/embeds/builders.dart' show ImageEmbedBuilder;
import 'package:async/async.dart';

import './constants.dart';
import './utils.dart' show showColorDialog, showTextDialog;
import './quill_utils.dart' show html2Quill;
import '../globalvars.dart' show globalConfigInfo;
import '../bdwm/search.dart';

fquill.QuillController genController(String? content) {
  late fquill.QuillController controller;
  if (content!=null && content.isNotEmpty) {
    var clist = html2Quill(content);
    controller = fquill.QuillController(
      document: fquill.Document.fromJson(clist),
      selection: const TextSelection.collapsed(offset: 0),
    );
  } else {
    controller = fquill.QuillController.basic();
  }
  return controller;
}

class FquillEditor extends StatefulWidget {
  final fquill.QuillController controller;
  final bool autoFocus;
  const FquillEditor({
    super.key,
    required this.controller,
    required this.autoFocus,
  });

  @override
  State<FquillEditor> createState() => _FquillEditorState();
}

class _FquillEditorState extends State<FquillEditor> {
  final editorKey = GlobalKey<fquill.QuillEditorState>();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? removeOverlayTimer;
  OverlayEntry? suggestionTagoverlayEntry;
  CancelableOperation? getUserSuggestionCancelable;

  @override
  void initState() {
    super.initState();
    if (globalConfigInfo.getSuggestUser()==true) {
      addUserSuggest();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    removeSuggestionNow();
    if (suggestionTagoverlayEntry != null) {
      suggestionTagoverlayEntry!.dispose();
    }
    if (getUserSuggestionCancelable != null) {
      getUserSuggestionCancelable!.cancel();
    }
    super.dispose();
  }

  void addUserSuggest() {
    widget.controller.onSelectionChanged = (textSelection) async {
      var textEditingValue = widget.controller.plainTextEditingValue;
      var rawText = textEditingValue.text;
      var baseOffset = textSelection.baseOffset;
      bool waitUserList = false;
      String partUserName = "";
      int selection1 = -1;
      if (baseOffset > 0) {
        if (baseOffset >= rawText.length || rawText[baseOffset]==" " || rawText[baseOffset]=="\n") {
          int newOffset = baseOffset - 1;
          while (newOffset >= 0) {
            var curChar = rawText[newOffset];
            if (curChar == '@') {
              if (newOffset == 0 || rawText[newOffset-1]==" " || rawText[newOffset-1]=="\n") {
                partUserName = rawText.substring(newOffset+1, baseOffset);
                if (isValidUserName(partUserName)) {
                  waitUserList = true;
                  selection1 = newOffset+1;
                }
                break;
              }
            } else if (curChar == ' ') {
              break;
            }
            if (baseOffset - newOffset > 12) {
              break;
            }
            newOffset -= 1;
          }
        }
      }
      if (waitUserList == false) {
        removeSuggestionNow();
        return;
      }
      debugPrint(partUserName);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        var quillEditorState = editorKey.currentState!;
        var renderEditor = quillEditorState.editableTextKey.currentState!.renderEditor;
        // var cursorOffset = renderEditor.getEndpointsForSelection(textSelection.copyWith(baseOffset: textSelection.baseOffset-1, extentOffset: textSelection.extentOffset-1)).first.point;
        var cursorOffset = renderEditor.getEndpointsForSelection(textSelection.copyWith(baseOffset: selection1-1, extentOffset: selection1-1)).first.point;
        showOverlaidTag(context, partUserName, selection1, cursorOffset.dx, cursorOffset.dy - (renderEditor.offset?.pixels ?? 0));
      });
    };
  }

  bool isValidUserName(String userName) {
    if (userName.isEmpty) { return true; }
    var matchRes = RegExp(r"[a-zA-Z_]+").stringMatch(userName);
    if (matchRes == null) { return false; }
    return matchRes.length == userName.length;
  }

  void removeSuggestionNow() {
    if (removeOverlayTimer != null && removeOverlayTimer!.isActive) {
      removeOverlayTimer!.cancel();
      if (suggestionTagoverlayEntry != null) {
        suggestionTagoverlayEntry!.remove();
      }
    }
  }

  void showOverlaidTag(BuildContext context, String partUserName, int selection1, double dx, double dy) async {
    removeSuggestionNow();
    if (getUserSuggestionCancelable != null) {
      getUserSuggestionCancelable!.cancel();
    }
    if (!mounted) { return; }
    OverlayState overlayState = Overlay.of(context);
    if (partUserName.isEmpty) {
      getUserSuggestionCancelable = CancelableOperation.fromFuture(
        bdwmGetFriends(),
      );
    } else {
      getUserSuggestionCancelable = CancelableOperation.fromFuture(
        bdwmTopSearch(partUserName),
      );
    }

    var duration = const Duration(milliseconds: 5000);
    double overlayWidth = 160;
    var deviceSize = MediaQuery.of(context).size;
    suggestionTagoverlayEntry = OverlayEntry(builder: (context) {
      var tmpLeft = _focusNode.offset.dx + dx;
      var tmpTop = _focusNode.offset.dy + dy + 5;
      return Positioned(
        top: math.min(tmpTop, _focusNode.rect.bottom),
        left: tmpLeft + overlayWidth + 10 > deviceSize.width ? deviceSize.width - overlayWidth - 10 : tmpLeft,
        child: Material(
          elevation: 4,
          // color: Colors.white.withOpacity(1.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: bdwmPrimaryColor, width: 1.0),
              // color: Colors.white.withOpacity(0.5),
            ),
            constraints: const BoxConstraints(
              minHeight: 25,
              maxHeight: 125,
            ),
            width: overlayWidth,
            child: FutureBuilder(
              future: getUserSuggestionCancelable!.value,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Text("查询中");
                }
                if (snapshot.hasError) {
                  duration = const Duration(milliseconds: 1000);
                  return const Text("查询失败");
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  duration = const Duration(milliseconds: 1000);
                  return const Text("查询失败");
                }
                bool success = false;
                List<IDandName> users = [];
                if (partUserName.isEmpty) {
                  var searchResp = snapshot.data as UserInfoRes;
                  success = searchResp.success;
                  for (var u in searchResp.users) {
                    users.add(u as IDandName);
                  }
                } else {
                  var searchResp = snapshot.data as TopSearchRes;
                  success = searchResp.success;
                  users = searchResp.users;
                }
                if (!success) {
                  duration = const Duration(milliseconds: 1000);
                  return partUserName.length == 1 ? const Text("太短") : const Text("查询失败");
                } else if (users.isEmpty) {
                  duration = const Duration(milliseconds: 1000);
                  return const Text("查询失败");
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(0.0),
                  itemExtent: 25,
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var e = users[index];
                    return GestureDetector(
                      onTap: () {
                        String fullName = "${e.name} ";
                        widget.controller.replaceText(selection1, partUserName.length, fullName, null);
                        widget.controller.updateSelection(widget.controller.selection.copyWith(
                          baseOffset: selection1+fullName.length,
                          extentOffset: selection1+fullName.length,
                        ), fquill.ChangeSource.LOCAL);
                        removeSuggestionNow();
                      },
                      child: Text("@${e.name}", style: serifFont.copyWith(fontSize: 18)),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    });
    overlayState.insert(suggestionTagoverlayEntry!);

    removeOverlayTimer = Timer(duration, () {
      if (suggestionTagoverlayEntry != null) {
        suggestionTagoverlayEntry!.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return fquill.QuillEditor(
      key: editorKey,
      controller: widget.controller,
      scrollController: _scrollController,
      scrollable: true,
      focusNode: _focusNode,
      autoFocus: widget.autoFocus, // 回帖
      readOnly: false,
      expands: false,
      padding: const EdgeInsets.all(5.0),
      keyboardAppearance: Theme.of(context).brightness,
      locale: const Locale('zh'),
      embedBuilders: [ImageEmbedBuilder()],
    );
  }
}

class FquillEditorToolbar extends StatelessWidget {
  final fquill.QuillController controller;
  const FquillEditorToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return fquill.QuillToolbar.basic(
      controller: controller,
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
      showRedo: false,
      showUndo: false,
      showBackgroundColorButton: false,
      customButtons: [
        fquill.QuillCustomButton(
          icon: Icons.color_lens,
          onTap: () {
            showColorDialog(context, (bdwmRichText['fc'] as Map<String, int>).keys.toList())
            .then((value) {
              if (value == null) { return; }
              controller.formatSelection(fquill.ColorAttribute(value));
            });
          }
        ),
        fquill.QuillCustomButton(
          icon: Icons.format_color_fill,
          onTap: () {
            showColorDialog(context, (bdwmRichText['bc'] as Map<String, int>).keys.toList())
            .then((value) {
              if (value == null) { return; }
              controller.formatSelection(fquill.BackgroundAttribute(value));
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
              var index = controller.selection.baseOffset;
              var length = controller.selection.extentOffset - index;
              controller.replaceText(index, length, fquill.BlockEmbed.image(value), null);
              controller.formatText(index, 1, const fquill.StyleAttribute("mobileAlignment:topLeft;mobileWidth:150;mobileHeight:150"));
            },);
          }
        ),
      ]
    );
  }
}
