import 'package:async/async.dart';
import 'package:flutter/material.dart';

import '../bdwm/req.dart';
import '../globalvars.dart';
import './constants.dart';
import '../html_parser/friends_parser.dart';
import './user.dart' show UserOperationComponent;
import '../router.dart' show nv2Push;

class FriendPage extends StatefulWidget {
  final String mode;
  const FriendPage({super.key, required this.mode});

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  final _scrollController = ScrollController();
  late CancelableOperation getDataCancelable;
  Future<FriendsInfo> getData() async {
    var url = "$v2Host/friend.php";
    if (widget.mode=="fan") {
      url += "?mode=fan";
    } else if (widget.mode=="reject") {
      url += "?mode=reject";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return FriendsInfo.error(errorMessage: networkErrorText);
    }
    return parseFriends(resp.body);
  }
  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    },);
  }
  @override
  void dispose() {
    _scrollController.dispose();
    Future.microtask(() => getDataCancelable.cancel(),);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
          // return const Center(child: Text("加载中"));
        }
        if (snapshot.hasError) {
          return Center(child: Text("错误：${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("错误：未获取数据"));
        }
        var friendsInfo = snapshot.data as FriendsInfo;
        if (friendsInfo.errorMessage != null) {
          return Center(child: Text(friendsInfo.errorMessage!),);
        }
        return ListView.builder(
          controller: _scrollController,
          itemCount: friendsInfo.friends.length,
          itemBuilder: ((context, index) {
            var e = friendsInfo.friends[index];
            return Card(
              child: ListTile(
                leading: GestureDetector(
                  child: Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      // radius: 100,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(e.avatar),
                    ),
                  ),
                  onTap: () {
                    if (e.uid.isEmpty) {
                      return;
                    }
                    nv2Push(context, '/user', arguments: e.uid);
                  },
                ),
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: e.userName, style: serifFont),
                      const TextSpan(text: " "),
                      TextSpan(text: e.onlineStatus),
                      if (e.bidirection)
                        const WidgetSpan(
                          child: Icon(Icons.swap_horiz,),
                          alignment: PlaceholderAlignment.middle
                        ),
                    ]
                  ),
                ),
                subtitle: Text(e.nickName),
                trailing: widget.mode == "fan"
                  ? UserOperationComponent(exist: e.bidirection, uid: e.uid, userName: e.userName, mode: "friend",)
                  : widget.mode=="reject"
                    ? UserOperationComponent(exist: true, uid: e.uid, userName: e.userName, mode: "reject",) // 拉黑
                    : UserOperationComponent(exist: true, uid: e.uid, userName: e.userName, mode: "friend",), // 关注
              ),
            );
          })
        );
      }
    );
  }
}