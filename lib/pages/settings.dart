import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart' show FlutterDisplayMode, DisplayMode;

import '../globalvars.dart';
import '../views/constants.dart';
import '../views/utils.dart';
import '../utils.dart' show isAndroid;
import '../main.dart' show MainPage, initPrimaryColor, setHighRefreshRate;
import '../notification.dart' show sendToast;
// import './read_thread.dart' show resetInitScrollHeight;

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
        child: HueRingPicker(
          enableAlpha: true,
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

class UseMD3Component extends StatefulWidget {
  const UseMD3Component({super.key});

  @override
  State<UseMD3Component> createState() => _UseMD3ComponentState();
}

class _UseMD3ComponentState extends State<UseMD3Component> {
  void setMD(bool useMD3) {
    // resetInitScrollHeight();
    globalConfigInfo.useMD3 = useMD3;
    var mainState = MainPage.maybeOf(context);
    mainState?.refresh();
    setState(() { });
  }
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text("使用 Material Design 3"),
      subtitle: const Text("否则使用 Material Design 2"),
      activeColor: bdwmPrimaryColor,
      value: globalConfigInfo.useMD3,
      onChanged: (value) {
        setMD(value);
      },
    );
  }
}

class DynamicColorComponent extends StatefulWidget {
  final Function? parentRefresh;
  const DynamicColorComponent({super.key, this.parentRefresh});

  @override
  State<DynamicColorComponent> createState() => _DynamicColorComponentState();
}

class _DynamicColorComponentState extends State<DynamicColorComponent> {
  void toggleUseDynamicColor(bool useIt) {
    globalConfigInfo.useDynamicColor = useIt;
    if (!useIt) {
      initPrimaryColor();
    }
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
    return SwitchListTile(
      title: const Text("使用动态颜色"),
      subtitle: const Text("自动从壁纸提取主题颜色（dynamic color）。低版本安卓不一定支持"),
      activeColor: bdwmPrimaryColor,
      value: globalConfigInfo.useDynamicColor,
      onChanged: (value) {
        toggleUseDynamicColor(value);
      },
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
    globalConfigInfo.primaryColorString = newColor.toARGB32().toString();
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
      enabled: !globalConfigInfo.useDynamicColor,
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

Future<String?> showRefreshRateDialog(BuildContext context, List<DisplayMode> modes) {
  modes.removeWhere((element) => element.width==0);
  List<SimpleDialogOption> children = modes.map((c) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context, "${c.id},${c.width},${c.height},${c.refreshRate}");
      },
      child: Text(c.toString()),
    );
  }).toList();
  children.insert(0, SimpleDialogOption(
    onPressed: () {
      Navigator.pop(context, "no");
    },
    child: const Text("不设置（保存后重启生效）"),
  ));
  children.insert(0, SimpleDialogOption(
    onPressed: () {
      Navigator.pop(context, "low");
    },
    child: const Text("低"),
  ));
  children.insert(0, SimpleDialogOption(
    onPressed: () {
      Navigator.pop(context, "high");
    },
    child: const Text("高"),
  ));
  var dialog = SimpleDialog(
    title: const Text("选择刷新率"),
    children: children,
  );

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return dialog;
    },
  );
}

class RefreshRateComponent extends StatefulWidget {
  const RefreshRateComponent({super.key});

  @override
  State<RefreshRateComponent> createState() => _RefreshRateComponentState();
}

class _RefreshRateComponentState extends State<RefreshRateComponent> {
  DisplayMode? m;
  String genDescription(String refreshRate) {
    if (refreshRate == "no") return "未设置";
    if (refreshRate == "high") return "高";
    if (refreshRate == "low") return "低";
    var values = refreshRate.split(",");
    return "${values[1]}x${values[2]} @ ${double.parse(values[3]).round()}Hz";
  }

  @override
  void initState() {
    super.initState();
    FlutterDisplayMode.active.then((value) {
      setState(() {
        m = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        List<DisplayMode> modes = [];
        try {
          modes = await FlutterDisplayMode.supported;
        } on PlatformException catch (e) {
          String errorMessage = "${e.code}: ${e.message}";
          if (!context.mounted) { return; }
          showInformDialog(context, "遇到问题", errorMessage);
          return;
        } on Exception catch (e) {
          if (!context.mounted) { return; }
          showInformDialog(context, "遇到问题", e.toString());
          return;
        }
        if (!context.mounted) { return; }
        var newRate = await showRefreshRateDialog(context, modes);
        if (newRate == null) { return; }
        globalConfigInfo.refreshRate = newRate;
        await setHighRefreshRate(newRate);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        m = await FlutterDisplayMode.active;
        setState(() { });
      },
      title: const Text("刷新率"),
      isThreeLine: true,
      subtitle: Text.rich(TextSpan(
        children: [
          TextSpan(text: genDescription(globalConfigInfo.getRefreshRate())),
          const TextSpan(text: "\n"),
          TextSpan(text: "当前实际：${m.toString()}"),
        ],
      ),),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void dispose() {
    if (globalConfigInfo.getAutoSaveConfig()) {
      debugPrint("设置已保存");
      globalConfigInfo.update().then((_) {
        sendToast("设置已保存");
      });
    }
    super.dispose();
  }
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
              await sendToast("设置已保存");
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        children: [
          const UseMD3Component(),
          const Divider(),
          DynamicColorComponent(parentRefresh: () { refresh(); },),
          const Divider(),
          PrimaryColorComponent(parentRefresh: () { refresh(); },),
          const Divider(),
          if (isAndroid()) ...[
            const RefreshRateComponent(),
            const Divider(),
          ],
          SwitchListTile(
            title: const Text("预览图片质量：高"),
            subtitle: const Text("仅限正文和签名档中嵌入的预览图片"),
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
          SwitchListTile(
            title: const Text("打开应用时选择$accountChinese"),
            subtitle: const Text("默认为游客（guest）。如果出现登录无故失效的情况，就把这个关掉"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.guestFirst,
            onChanged: (value) {
              globalConfigInfo.guestFirst = value;
              refresh();
            },
          ),
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
              globalNotConfigInfo.setLastLoginTime("").then((saved) {
                if (saved == false) { return; }
                globalConfigInfo.showWelcome = value;
                refresh();
              });
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
            title: const Text("卡片显示详细信息"),
            subtitle: const Text("完整标题"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.showDetailInCard,
            onChanged: (value) {
              globalConfigInfo.showDetailInCard = value;
              refresh();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("保存发帖历史"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.savePostHistory,
            onChanged: (value) {
              globalConfigInfo.savePostHistory = value;
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
          SwitchListTile(
            title: const Text("看帖时自动隐藏底部栏"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.autoHideBottomBar,
            onChanged: (value) {
              globalConfigInfo.autoHideBottomBar = value;
              refresh();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("自动保存设置"),
            subtitle: const Text("退出此页面后自动保存设置"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.autoSaveConfig,
            onChanged: (value) {
              globalConfigInfo.autoSaveConfig = value;
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
                  if (context.mounted) {
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
        ],
      )
    );
  }
}
