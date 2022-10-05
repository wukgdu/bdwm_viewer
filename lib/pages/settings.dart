import 'package:flutter/material.dart';

import '../globalvars.dart';
import '../views/constants.dart';
import '../views/utils.dart';

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
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
              setState(() { });
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
              setState(() { });
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
              setState(() { });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("图标显示未读消息数量"),
            subtitle: const Text("部分安卓设备支持"),
            activeColor: bdwmPrimaryColor,
            value: globalConfigInfo.showBadge,
            onChanged: (value) {
              globalConfigInfo.showBadge = value;
              setState(() { });
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
              setState(() { });
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
              setState(() { });
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
              setState(() { });
            },
          ),
          const Divider(),
        ],
      )
    );
  }
}
