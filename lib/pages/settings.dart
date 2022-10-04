import 'package:bdwm_viewer/views/utils.dart';
import 'package:flutter/material.dart';

import '../globalvars.dart';
import '../views/constants.dart';

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
        ],
      )
    );
  }
}
