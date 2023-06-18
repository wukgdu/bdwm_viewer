import 'dart:convert';

import 'package:flutter/material.dart';

import "../bdwm/search.dart";
import '../utils.dart' show isValidUserName, getQueryValueImproved;
import './read_post.dart' show getSinglePostData;
import '../views/show_ip.dart' show genIPStr, canSeeAllIP;

class UsernameAndIP {
  final String userName;
  final int ip;
  const UsernameAndIP({
    this.userName = "",
    this.ip = 0,
  });
  const UsernameAndIP.empty({
    this.userName = "",
    this.ip = 0,
  });
}

class CompareIpPage extends StatefulWidget {
  final int part;
  const CompareIpPage({super.key, this.part=2});

  @override
  State<CompareIpPage> createState() => _CompareIpPageState();
}

class _CompareIpPageState extends State<CompareIpPage> {
  UsernameAndIP uip1 = const UsernameAndIP.empty();
  UsernameAndIP uip2 = const UsernameAndIP.empty();
  TextEditingController text1Controller = TextEditingController();
  TextEditingController text2Controller = TextEditingController();

  Future<List<String>?> getBidAndNum(String link) async {
    var bid = getQueryValueImproved(link, 'bid');
    var postid = getQueryValueImproved(link, 'postid');
    if (bid == null || postid == null) { return null; }
    var res = await getSinglePostData(bid, postid);
    var item = res.postInfo;
    if (item.postNumber.startsWith('#') && int.tryParse(item.postNumber.substring(1))!=null) {
      return [bid, item.postNumber.substring(1)];
    }
    return null;
  }

  Future<UsernameAndIP> searchOne(String txt) async {
    if (txt.toLowerCase() == 'onepiece') {
      return const UsernameAndIP(userName: "不能查我");
    }
    if (isValidUserName(txt)) {
      var userRes = await bdwmUserInfoSearch([txt]);
      if (userRes.success == false) {
        return const UsernameAndIP(userName: "查询失败");
      }
      if (userRes.users.isEmpty) {
        return const UsernameAndIP(userName: "查询失败");
      }
      if (userRes.users[0] is bool) {
        return const UsernameAndIP(userName: "查询失败");
      }
      try {
        Map jsonObject = jsonDecode(userRes.jsonStr);
        Map result = jsonObject['result'][0];
        int ipInt = result['ip'];
        return UsernameAndIP(userName: txt, ip: ipInt);
      } catch (_) {
        return const UsernameAndIP(userName: "查询失败");
      }
    } else {
      var bidAndNumRes = await getBidAndNum(txt);
      if (bidAndNumRes == null) {
        return const UsernameAndIP(userName: "查询失败");
      }
      var bid = bidAndNumRes[0];
      var num = bidAndNumRes[1];
      var res = await bdwmGetPostByNum(bid: bid, num: num);
      if (res.success == false) {
        return const UsernameAndIP(userName: "查询失败");
      }
      if (res.postInfoItem.isEmpty) {
        return const UsernameAndIP(userName: "查询失败");
      }
      if (res.postInfoItem.first.owner.toLowerCase() == "onepiece") {
        return const UsernameAndIP(userName: "不能查我");
      }
      return UsernameAndIP(userName: res.postInfoItem.first.owner, ip: res.postInfoItem.first.ip);
    }
  }

  Future<void> startSearch() async {
    var txt1 = text1Controller.text.trim();
    var txt2 = text2Controller.text.trim();
    if (txt1.isEmpty || txt2.isEmpty) { return; }
    setState(() {
      uip1 = const UsernameAndIP(userName: "查询中");
      uip2 = const UsernameAndIP(userName: "查询中");
    });
    var res1 = await searchOne(txt1);
    var res2 = await searchOne(txt2);
    setState(() {
      uip1 = res1;
      uip2 = res2;
    });
  }

  @override
  void dispose() {
    text1Controller.dispose();
    text2Controller.dispose();
    super.dispose();
  }

  String judge() {
    if (uip1.ip == uip2.ip) {
      if (uip1.ip == 0) {
        return "= 0 =";
      } else {
        return "=";
      }
    } else {
      return "≠";
    }
  }

  String judge3() {
    var ip1 = uip1.ip & 0x00ffffff;
    var ip2 = uip2.ip & 0x00ffffff;
    if (ip1 == ip2) {
      if (ip1 == 0) {
        return "= 0 =";
      } else {
        return "=";
      }
    } else {
      return "≠";
    }
  }

  String judge2() {
    var ip1 = uip1.ip & 0x0000ffff;
    var ip2 = uip2.ip & 0x0000ffff;
    if (ip1 == ip2) {
      if (ip1 == 0) {
        return "= 0 =";
      } else {
        return "=";
      }
    } else {
      return "≠";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("对比IP"),
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(5.0),
            child: TextField(
                controller: text1Controller,
                decoration: const InputDecoration(
                  hintText: "用户id或单帖链接",
                ),
              ),
          ),
          Container(
            padding: const EdgeInsets.all(5.0),
            child: TextField(
                controller: text2Controller,
                decoration: const InputDecoration(
                  hintText: "用户id或单帖链接",
                ),
              ),
          ),
          const Divider(),
          Column(
            children: [
              TextButton(
                onPressed: () {
                  startSearch();
                },
                child: const Text("对比IP"),
              ),
              if (canSeeAllIP() || (widget.part==4)) ...[
                Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: "IP(${uip1.userName})"),
                        TextSpan(text: " ${judge()} "),
                        TextSpan(text: "IP(${uip2.userName})"),
                      ]
                    )
                  )
                ),
              ] else if (widget.part==3) ...[
                Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: "IP3/4(${uip1.userName})"),
                        TextSpan(text: " ${judge3()} "),
                        TextSpan(text: "IP3/4(${uip2.userName})"),
                      ]
                    )
                  )
                ),
              ] else if (widget.part==2) ...[
                Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: "IP2/4(${uip1.userName})"),
                        TextSpan(text: " ${judge2()} "),
                        TextSpan(text: "IP2/4(${uip2.userName})"),
                      ]
                    )
                  )
                ),
              ],
              Center(
                child: SelectionArea(child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: genIPStr(uip1.ip, widget.part)),
                      const TextSpan(text: "   "),
                      TextSpan(text: genIPStr(uip2.ip, widget.part)),
                    ]
                  )
                ),),
              ),
            ],
          ),
          const Divider(),
          const SelectableText('''  输入用户id或者单帖链接进行IP不完整对比。例如
  onepiece
  https://bbs.pku.edu.cn/v2/post-read-single.php?bid=338&postid=26867579
  单帖链接可从该贴的分享操作中获得。'''),
        ],
      ),
    );
  }
}
