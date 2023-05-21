import 'dart:convert';

import 'package:flutter/material.dart';

import "../bdwm/search.dart";
import '../globalvars.dart' show globalUInfo;

List<int> parseIP(int ipInt) {
  String ipHexStr = ipInt.toRadixString(16).padLeft(8, '0');
  int ip1 = int.parse("0x${ipHexStr.substring(0, 2)}");
  int ip2 = int.parse("0x${ipHexStr.substring(2, 4)}");
  int ip3 = int.parse("0x${ipHexStr.substring(4, 6)}");
  int ip4 = int.parse("0x${ipHexStr.substring(6, 8)}");
  return [ip1, ip2, ip3, ip4];
}

String genIPStr(int ipInt, int part) {
  String ipStr = "";
  var ipArray = parseIP(ipInt);
  int ip1 = ipArray[0], ip2 = ipArray[1], ip3 = ipArray[2], ip4 = ipArray[3];
  if (canSeeAllIP()) {
    ipStr = "$ip4.$ip3.$ip2.$ip1";
  } else if (part == 4) {
    ipStr = "$ip4.$ip3.$ip2.$ip1";
  } else if (part == 3) {
    ipStr = "$ip4.$ip3.$ip2.*";
  } else if (part == 2) {
    ipStr = "$ip4.$ip3.*.*";
  } else if (part == 1) {
    ipStr = "$ip4.*.*.*";
  } else {
    ipStr = "*.*.*.*";
  }
  return ipStr;
}

bool canSeeAllIP() {
  return (globalUInfo.uid == "22776") && (globalUInfo.login == true) && (globalUInfo.username.toLowerCase() == "onepiece");
}

class ShowIpComponent extends StatefulWidget {
  final String userName;
  final String uid;
  final int part;
  const ShowIpComponent({required this.userName, required this.uid, this.part=2, super.key});

  @override
  State<ShowIpComponent> createState() => _ShowIpComponentState();
}

class _ShowIpComponentState extends State<ShowIpComponent> {
  bool showIp = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: [
          const Text("IP："),
          if (showIp) ...[
            widget.userName.toLowerCase() == "onepiece"
            ? const Text("当然不能查我啦")
            : FutureBuilder(
              future: bdwmUserInfoSearch([widget.userName]),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  // return const Center(child: CircularProgressIndicator());
                  return const Text("查询中");
                }
                if (snapshot.hasError) {
                  return Text("错误：${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("错误：未获取数据");
                }
                var userRes = snapshot.data as UserInfoRes;
                if (userRes.success == false) {
                  return const Text("查询失败");
                }
                if (userRes.users.isEmpty) {
                  return const Text("查询失败");
                }
                if (userRes.users[0] is bool) {
                  return const Text("查询失败");
                }
                String ipStr = "";
                try {
                  Map jsonObject = jsonDecode(userRes.jsonStr);
                  Map result = jsonObject['result'][0];
                  int ipInt = result['ip'];
                  ipStr = genIPStr(ipInt, widget.part);
                } catch (_) {
                  ipStr = "查询失败";
                }
                return SelectionArea(child: Text(ipStr));
              },
            ),
          ],
          TextButton(
            onPressed: () {
              setState(() {
                showIp = !showIp;
              });
            },
            child: Text(showIp ? "隐藏" : "点击查看"),
          ),
        ],
      ),
    );
  }
}

class ShowPostIpComponent extends StatefulWidget {
  final String userName;
  final String uid;
  final int part;
  final String bid;
  final String num;
  const ShowPostIpComponent({required this.userName, required this.uid, required this.bid, required this.num, this.part=2, super.key});

  @override
  State<ShowPostIpComponent> createState() => _ShowPostIpComponentState();
}

class _ShowPostIpComponentState extends State<ShowPostIpComponent> {
  bool showIp = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          const Text("IP：", style: TextStyle(fontSize: 14)),
          if (showIp) ...[
            widget.userName.toLowerCase() == "onepiece"
            ? const Text("当然不能查我啦", style: TextStyle(fontSize: 14))
            : FutureBuilder(
              future: bdwmGetPostByNum(bid: widget.bid, num: widget.num),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  // return const Center(child: CircularProgressIndicator());
                  return const Text("查询中", style: TextStyle(fontSize: 14));
                }
                if (snapshot.hasError) {
                  return Text("错误：${snapshot.error}", style: const TextStyle(fontSize: 14));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("错误：未获取数据", style: TextStyle(fontSize: 14));
                }
                var res = snapshot.data as NumToPostInfoRes;
                if (res.success == false) {
                  return const Text("查询失败", style: TextStyle(fontSize: 14));
                }
                if (res.postInfoItem.isEmpty) {
                  return const Text("查询失败", style: TextStyle(fontSize: 14));
                }
                String ipStr = "";
                try {
                  ipStr = genIPStr(res.postInfoItem.first.ip, widget.part);
                } catch (_) {
                  ipStr = "查询失败";
                }
                return SelectionArea(child: Text(ipStr, style: const TextStyle(fontSize: 14)));
              },
            ),
          ],
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(20, 20),
              padding: const EdgeInsets.all(0.0),
              // textStyle: MaterialStatePropertyAll(TextStyle(fontSize: 12)),
            ),
            onPressed: () {
              setState(() {
                showIp = !showIp;
              });
            },
            child: Text(showIp ? "隐藏" : "点击查看", style: const TextStyle(fontSize: 14),),
          ),
        ],
      ),
    );
  }
}
