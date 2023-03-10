import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as fquill;

import '../bdwm/settings.dart';
import '../html_parser/modify_profile_parser.dart';
import '../views/quill_utils.dart' show quill2BDWMtext;
import '../views/utils.dart' show showConfirmDialog, showInformDialog;
import '../views/constants.dart' show bdwmPrimaryColor;
import '../views/editor.dart' show FquillEditor, FquillEditorToolbar, genController;
import '../views/user.dart' show RankSelectComponent;
import '../globalvars.dart' show globalConfigInfo;
import '../router.dart' show nv2Pop;

class ModifyProfileApp extends StatefulWidget {
  final SelfProfileInfo selfProfileInfo;
  const ModifyProfileApp({super.key, required this.selfProfileInfo});

  @override
  State<ModifyProfileApp> createState() => _ModifyProfileAppState();
}

class _ModifyProfileAppState extends State<ModifyProfileApp> {
  static const hSpace = SizedBox(width: 8.0,);
  TextEditingController nickNameTextController = TextEditingController();
  late final fquill.QuillController _controller;

  late int birthYear, birthMonth, birthDay;
  late String rankSys, desc, nickName, gender;
  late bool hideGender, hideHoroScope;

  @override
  void initState() {
    super.initState();
    nickName = widget.selfProfileInfo.nickName;
    birthYear = widget.selfProfileInfo.birthYear;
    birthMonth = widget.selfProfileInfo.birthMonth;
    gender = widget.selfProfileInfo.gender;
    birthDay = widget.selfProfileInfo.birthDay;
    rankSys = widget.selfProfileInfo.selfProfileRankSysInfo.selected;
    desc = widget.selfProfileInfo.desc;
    hideGender = widget.selfProfileInfo.hideGender;
    hideHoroScope = widget.selfProfileInfo.hideHoroscope;

    nickNameTextController.text = nickName;
    _controller = genController(desc);
  }

  @override
  void dispose() {
    nickNameTextController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget genContainer(Widget child) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40.0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    var birthDate = DateTime(birthYear, birthMonth, birthDay);
    return Scaffold(
      appBar: AppBar(
        title: const Text("修改资料"),
        actions: [
          TextButton(
            onPressed: () async {
              var doIt = await showConfirmDialog(context, "确认保存？", "不保证复杂的签名档正确");
              if (doIt == null || doIt != "yes") { return; }
              var quillDelta = _controller.document.toDelta().toJson();
              try {
                desc = quill2BDWMtext(quillDelta, removeLastReturn: true);
              } catch (e) {
                if (!mounted) { return; }
                showInformDialog(context, "内容格式错误", "$e\n请返回后截图找 onepiece 报bug");
                return;
              }
              nickName = nickNameTextController.text;
              debugPrint(desc);
              var res = await bdwmSetProfile(
                nickName: nickName, rankSys: rankSys, gender: gender,
                hideGender: hideGender, hideHoroscope: hideHoroScope,
                desc: desc, birthYear: birthYear, birthMonth: birthMonth, birthDay: birthDay,
              );
              if (res.success) {
                if (!mounted) { return; }
                await showInformDialog(context, "保存成功", "rt");
                if (!mounted) { return; }
                nv2Pop(context);
              } else {
                var reason = res.errorMessage ?? "rt";
                if (!mounted) { return; }
                showInformDialog(context, "保存失败", reason);
              }
            },
            child: Text("保存", style: TextStyle(color: globalConfigInfo.getUseMD3() ? null : Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10.0),
        children: [
          genContainer(
            Row(
              children: [
                const Text("昵称", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),),
                hSpace,
                Expanded(
                  child: TextField(
                    controller: nickNameTextController,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: "昵称长度应＜15 个汉字，或＜30 个字符",
                    ),
                  ),
                ),
                const SelectableText("["),
              ],
            ),
          ),
          genContainer(
            Row(
              children: [
                const Text("生日", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),),
                TextButton(
                  onPressed: () async {
                    var newDate = await showDatePicker(context: context, initialDate: birthDate,
                      firstDate: DateTime(1901, 1, 1), lastDate: DateTime(2100, 1, 1), locale: const Locale('zh', 'CN'),
                    );
                    if (newDate == null) { return; }
                    setState(() {
                      birthYear = newDate.year;
                      birthMonth = newDate.month;
                      birthDay = newDate.day;
                    });
                  },
                  child: Text("$birthYear-$birthMonth-$birthDay"),
                ),
                Checkbox(value: hideHoroScope, activeColor: bdwmPrimaryColor, onChanged: (value) {
                  setState(() {
                    hideHoroScope = value as bool;
                  });
                },),
                const Text("不显示我的星座"),
              ],
            ),
          ),
          genContainer(
            Row(
              children: [
                const Text("性别", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),),
                Radio(value: "M", groupValue: gender, activeColor: bdwmPrimaryColor, onChanged: (value) {
                  setState(() {
                    gender = value as String;
                  });
                },),
                const Text("男"),
                Radio(value: "F", groupValue: gender, activeColor: bdwmPrimaryColor, onChanged: (value) {
                  setState(() {
                    gender = value as String;
                  });
                },),
                const Text("女"),
                Checkbox(value: hideGender, activeColor: bdwmPrimaryColor, onChanged: (value) {
                  setState(() {
                    hideGender = value as bool;
                  });
                },),
                const Text("不显示我的性别"),
              ],
            ),
          ),
          genContainer(
            Row(
              children: [
                const Text("等级", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),),
                hSpace,
                RankSelectComponent(selected: rankSys.toString(), selfProfileRankSysInfo: widget.selfProfileInfo.selfProfileRankSysInfo, updateFunc: (newSelected) {
                  setState(() {
                    rankSys = newSelected;
                  });
                },)
              ],
            )
          ),
          genContainer(
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                const Text("详情", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),),
                hSpace,
                Text(widget.selfProfileInfo.selfProfileRankSysInfo.rankSysDesc[int.parse(rankSys)].join("→")),
              ],
            )
          ),
          genContainer(
            Row(
              children: [
                const Text("说明档", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),),
                hSpace,
                FquillEditorToolbar(controller: _controller,),
              ],
            )
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.0, style: BorderStyle.solid),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            height: 200,
            child: FquillEditor(controller: _controller, autoFocus: false,),
          ),
        ],
      ),
    );
  }
}
