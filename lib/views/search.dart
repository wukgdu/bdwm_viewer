import 'package:flutter/material.dart';

import './constants.dart';
import './utils.dart';
class PostSearchSettings {
  String keyWord = "";
  String owner = "";
  String board = "";
  String rated = "";
  String days = "7";
  String titleonly = "";
  String timeorder = "1";
  String? mode = "post";
  String? bid = "";

  PostSearchSettings.empty();
  PostSearchSettings({
    required this.keyWord,
    required this.owner,
    required this.board,
    required this.rated,
    required this.days,
    required this.titleonly,
    required this.timeorder,
    this.mode,
    this.bid,
  });
}

class ComplexSearchComponent extends StatefulWidget {
  const ComplexSearchComponent({super.key});

  @override
  State<ComplexSearchComponent> createState() => _ComplexSearchComponentState();
}

class _ComplexSearchComponentState extends State<ComplexSearchComponent> {
  TextEditingController titleController = TextEditingController();
  TextEditingController userController = TextEditingController();
  TextEditingController boardController = TextEditingController();
  TextEditingController daysController = TextEditingController();
  PostSearchSettings pss = PostSearchSettings.empty();

  @override
  void initState() {
    super.initState();
    daysController.text = pss.days;
  }

  Widget titleBox(text) {
    return SizedBox(
      width: 80,
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                titleBox("标题"),
                Expanded(
                  child: TextField(
                    controller: titleController,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    int? days;
                    bool daysOK = true;
                    if (daysController.text.length > 7) {
                      daysOK = false;
                    } else {
                      days = int.tryParse(daysController.text);
                      if (days == null || days <= 0 || days > 999999) {
                        daysOK = false;
                      }
                    }
                    if (daysOK == false) {
                      showAlertDialog(context, "时间错误", const Text("输入天数不合法,请输入1000以内的天数\n（onepiece：实际可以24855）"),
                        actions1: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("知道了")
                        ),
                      );
                    } else {
                      if (days == 0) { days = 1; }
                      pss.keyWord = titleController.text;
                      pss.owner = userController.text;
                      pss.board = boardController.text;
                      pss.days = days.toString();
                      Navigator.of(context).pushNamed("/complexSearchResult", arguments: {
                        "settings": pss,
                      });
                    }
                  },
                  child: const Text("搜索"),
                ),
              ],
            ),
            Row(
              children: [
                titleBox("作者用户名"),
                Expanded(
                  child: TextField(
                    controller: userController,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                titleBox("版面"),
                Expanded(
                  child: TextField(
                    controller: boardController,
                    decoration: const InputDecoration(
                      // hintText: "目前只支持通过版面英文名搜索，且需要完全匹配",
                      hintText: "版面英文名",
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                titleBox("原创分"),
                Radio(
                  value: "",
                  groupValue: pss.rated,
                  activeColor: bdwmPrimaryColor,
                  onChanged: (value) {
                    setState(() {
                      pss.rated = value as String;
                    });
                  }
                ),
                const Expanded(child: Text("全部帖子")),
                Radio(
                  value: "1",
                  groupValue: pss.rated,
                  activeColor: bdwmPrimaryColor,
                  onChanged: (value) {
                    setState(() {
                      pss.rated = value as String;
                    });
                  }
                ),
                const Expanded(child: Text("获得原创分的帖子")),
              ],
            ),
            Row(
              children: [
                titleBox("发帖时间"),
                Expanded(
                  child: TextField(
                    controller: daysController,
                    keyboardType: const TextInputType.numberWithOptions(),
                  ),
                ),
                const Text("天内"),
              ],
            ),
            Row(
              children: [
                titleBox("只搜标题"),
                Radio(
                  value: "1",
                  groupValue: pss.titleonly,
                  activeColor: bdwmPrimaryColor,
                  onChanged: (value) {
                    setState(() {
                      pss.titleonly = value as String;
                    });
                  }
                ),
                const Expanded(child: Text("是"),),
                Radio(
                  value: "",
                  groupValue: pss.titleonly,
                  activeColor: bdwmPrimaryColor,
                  onChanged: (value) {
                    setState(() {
                      pss.titleonly = value as String;
                    });
                  }
                ),
                const Expanded(child: Text("否"),),
              ],
            ),
            Row(
              children: [
                titleBox("排序"),
                Radio(
                  value: "1",
                  groupValue: pss.timeorder,
                  activeColor: bdwmPrimaryColor,
                  onChanged: (value) {
                    setState(() {
                      pss.timeorder = value as String;
                    });
                  }
                ),
                const Expanded(child: Text("按时间排序")),
                Radio(
                  value: "",
                  groupValue: pss.timeorder,
                  activeColor: bdwmPrimaryColor,
                  onChanged: (value) {
                    setState(() {
                      pss.timeorder = value as String;
                    });
                  }
                ),
                const Expanded(child: Text("关联度排序")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleSearchComponent extends StatefulWidget {
  final String mode;
  const SimpleSearchComponent({super.key, required this.mode});

  @override
  State<SimpleSearchComponent> createState() => _SimpleSearchComponentState();
}

class _SimpleSearchComponentState extends State<SimpleSearchComponent> {
  TextEditingController textController = TextEditingController();

  void startSearch() {
    if (textController.text.isEmpty) { return; }
    Navigator.of(context).pushNamed("/simpleSearchResult", arguments: {
      "mode": widget.mode,
      "keyWord": textController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                onEditingComplete: () {
                  startSearch();
                },
              ),
            ),
            TextButton(
              onPressed: () {
                startSearch();
              },
              child: const Text("搜索"),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        Center(child: Text("搜索帖子")),
        ComplexSearchComponent(),
        Divider(),
        Center(child: Text("搜索用户")),
        SimpleSearchComponent(mode: "user",),
        Divider(),
        Center(child: Text("搜索版面")),
        SimpleSearchComponent(mode: "board"),
      ],
    );
  }
}