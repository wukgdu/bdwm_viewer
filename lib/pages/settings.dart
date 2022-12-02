import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../globalvars.dart';
import '../views/constants.dart';
import '../views/utils.dart';
import '../main.dart' show MainPage;
import './board_note.dart' show showFontDialog;

class ColorPickerComponent extends StatefulWidget {
  final Color primaryColor;
  const ColorPickerComponent({super.key, required this.primaryColor});

  @override
  State<ColorPickerComponent> createState() => _ColorPickerComponentState();
}

class _ColorPickerComponentState extends State<ColorPickerComponent> {
  late Color pickColor;
  @override
  void initState() {
    super.initState();
    pickColor = widget.primaryColor;
  }
  @override
  void didUpdateWidget(covariant ColorPickerComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    pickColor = widget.primaryColor;
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("选择主题颜色"),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: pickColor,
          onColorChanged: (newColor) {
            setState(() {
              pickColor = newColor;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(pickColor);
          },
          child: const Text("确认"),
        ),
      ],
    );
  }
}

class PrimaryColorComponent extends StatefulWidget {
  // Settings is const, so refresh
  final Function? parentRefresh;
  const PrimaryColorComponent({super.key, this.parentRefresh});

  @override
  State<PrimaryColorComponent> createState() => _PrimaryColorComponentState();
}

class _PrimaryColorComponentState extends State<PrimaryColorComponent> {
  void setNewColor(Color newColor) {
    bdwmPrimaryColor = newColor;
    globalConfigInfo.primaryColorString = newColor.value.toString();
    var mainState = MainPage.maybeOf(context);
    if (mainState == null) {
      if (widget.parentRefresh != null) {
        widget.parentRefresh!();
      } else {
        setState(() { });
      }
    } else {
      mainState.refresh();
      if (widget.parentRefresh != null) {
        widget.parentRefresh!();
      } else {
        setState(() { });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        var newColor = await showDialog<Color>(context: context, builder:(context) {
          return ColorPickerComponent(primaryColor: bdwmPrimaryColor,);
        },);
        if (newColor != null) {
          setNewColor(newColor);
        }
      },
      onLongPress: () {
        setNewColor(bdwmSurfaceColor);
      },
      title: const Text("主题颜色"),
      subtitle: const Text("选择主题颜色。长按恢复默认颜色"),
      trailing: Container(
        color: bdwmPrimaryColor,
        margin: const EdgeInsets.only(right: 10),
        width: 40,
      ),
    );
  }
}

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  void refresh() {
    setState(() { });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("设置"),
        actions: [
          IconButton(
            onPressed: () async {
              await globalConfigInfo.update();
              if (!mounted) { return; }
              showInformDialog(context, "已保存", "rt");
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        children: [
          const Divider(),
          SwitchListTile(
            title: const Text("消息中使用 BBS 的图片表情"),
            subtitle: const Text("需要联网下载。否则使用 Unicode 的 Emoji（不完整）"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.useImgInMessage,
            onChanged: (value) {
              globalConfigInfo.useImgInMessage = value;
              refresh();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("展示进站图片"),
            subtitle: const Text("每天第一次进入'首页->热点'时展示进站图片"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.showWelcome,
            onChanged: (value) {
              globalConfigInfo.lastLoginTime = "";
              globalConfigInfo.showWelcome = value;
              refresh();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("预览图片质量"),
            subtitle: const Text("高（仅限正文和签名档中嵌入的预览图片）"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.highQualityPreview,
            onChanged: (value) {
              globalConfigInfo.highQualityPreview = value;
              refresh();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("自动清理图片缓存"),
            subtitle: const Text("退出主题帖页面时清理"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.autoClearImageCache,
            onChanged: (value) {
              globalConfigInfo.autoClearImageCache = value;
              refresh();
            },
          ),
          const Divider(),
          ListTile(
            onTap: () async {
              var vStr = await showTextDialog(context, "[8, 24]的数字", inputNumber: true);
              if (vStr==null) { return; }
              var v = double.tryParse(vStr);
              if (v==null) { return; }
              if (8.0 <= v  && v <= 24.0) {
                globalConfigInfo.contentFontSize = v;
              } else {
                return;
              }
              refresh();
            },
            title: const Text("正文字体大小"),
            subtitle: Text("主题帖和文集的正文字体大小：${globalConfigInfo.contentFontSize}"),
            trailing: Container(
              margin: const EdgeInsets.only(right: 10),
              alignment: Alignment.center,
              width: 40,
              child: Text("字", style: TextStyle(fontSize: globalConfigInfo.contentFontSize)),
            ),
          ),
          const Divider(),
          PrimaryColorComponent(parentRefresh: () { refresh(); },),
          const Divider(),
          ListTile(
            onTap: () async {
              var f = await showFontDialog(context, avaiFonts, defaultFont: globalConfigInfo.getBoardNoteFont());
              if (f==null) { return; }
              globalConfigInfo.boardNoteFont = f;
              refresh();
            },
            title: const Text("备忘录字体"),
            subtitle: Text(globalConfigInfo.boardNoteFont),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("发帖@ID自动提示"),
            subtitle: const Text("联网查询"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.suggestUser,
            onChanged: (value) {
              globalConfigInfo.suggestUser = value;
              refresh();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("主题帖显示悬浮按钮"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.showFAB,
            onChanged: (value) {
              globalConfigInfo.showFAB = value;
              refresh();
            },
          ),
          const Divider(),
          ListTile(
            onTap: () async {
              var vStr = await showTextDialog(context, "输入数字，否则无穷");
              if (vStr==null) { return; }
              var v = int.tryParse(vStr);
              if (v==null) {
                globalConfigInfo.maxPageNum = "无穷";
              } else {
                if (v < 2) {
                  if (mounted) {
                    showInformDialog(context, "请输入>=2的数字", "rt");
                  }
                } else {
                  globalConfigInfo.maxPageNum = v.toString();
                }
              }
              refresh();
            },
            title: const Text("只加载最新的页面"),
            subtitle: Text("最新的 ${int.tryParse(globalConfigInfo.getMaxPageNum()) ?? '无穷'} 个"),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("使用额外线程查询未读消息"),
            subtitle: const Text("可能会更流畅。保存后重启生效"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.extraThread,
            onChanged: (value) {
              globalConfigInfo.extraThread = value;
              refresh();
            },
          ),
          const Divider(),
        ],
      )
    );
  }
}
