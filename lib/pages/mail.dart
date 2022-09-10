import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../views/mail.dart';
import '../html_parser/mail_parser.dart';
import '../globalvars.dart';
import '../views/utils.dart';

class MailListApp extends StatefulWidget {
  const MailListApp({super.key});

  @override
  State<MailListApp> createState() => _MailListAppState();
}

class _MailListAppState extends State<MailListApp> {
  static const appTitle = "站内信";
  int page = 1;
  String mode = "";
  late CancelableOperation getDataCancelable;

  Future<MailListInfo> getData() async {
    // return getExampleCollectionList();
    var url = "$v2Host/mail.php";
    if (mode.isNotEmpty) {
      if (mode=="删除") {
        url += "?type=5";
      } else if (mode=="星标") {
        url += "?type=3";
      } else if (mode=="已发送") {
        url += "?type=4";
      }
    }
    if (page != 1) {
      var prefix = mode.isEmpty ? "?" : "&";
      url += "${prefix}page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return MailListInfo.error(errorMessage: networkErrorText);
    }
    return parseMailList(resp.body);
  }

  void refresh() {
    setState(() {
      page = page;
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      },);
    });
  }

  void changeToMode(String mode_) {
    setState(() {
      page = 1;
      mode = mode_;
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      },);
    });
  }

  @override
  void initState() {
    super.initState();
    page = 1;
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    },);
  }

  @override
  void dispose() {
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
          // return const Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: const Text(appTitle),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(appTitle),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(appTitle),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var mailListInfo = snapshot.data as MailListInfo;
        if (mailListInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(appTitle),
            ),
            body: Center(
              child: Text(mailListInfo.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text(appTitle),
            actions: [
              PopupMenuButton(
                // icon: const Icon(Icons.more_horiz),
                onSelected: (value) {
                  if (value == null) { return; }
                  changeToMode(value as String);
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem(
                      value: "",
                      child: Text("收件箱"),
                    ),
                    const PopupMenuItem(
                      value: "已发送",
                      child: Text("已发送"),
                    ),
                    const PopupMenuItem(
                      value: "删除",
                      child: Text("删除"),
                    ),
                    const PopupMenuItem(
                      value: "星标",
                      child: Text("星标"),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: MailListPage(mailListInfo: mailListInfo),
          bottomNavigationBar: BottomAppBar(
            shape: null,
            // color: Colors.blue,
            child: IconTheme(
              data: const IconThemeData(color: Colors.redAccent),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    disabledColor: Colors.grey,
                    tooltip: '刷新',
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      refresh();
                    },
                  ),
                  IconButton(
                    disabledColor: Colors.grey,
                    tooltip: '上一页',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: page <= 1 ? null : () {
                      if (!mounted) { return; }
                      setState(() {
                        page = page - 1;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                        },);
                      });
                    },
                  ),
                  TextButton(
                    child: Text("$page/${mailListInfo.maxPage}"),
                    onPressed: () async {
                      var nPageStr = await showPageDialog(context, page, mailListInfo.maxPage);
                      if (nPageStr == null) { return; }
                      if (nPageStr.isEmpty) { return; }
                      var nPage = int.parse(nPageStr);
                      setState(() {
                        page = nPage;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                          debugPrint("cancel it");
                        },);
                      });
                    },
                  ),
                  IconButton(
                    disabledColor: Colors.grey,
                    tooltip: '下一页',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: page >= mailListInfo.maxPage ? null : () {
                      // if (page == threadPageInfo.pageNum) {
                      //   return;
                      // }
                      if (!mounted) { return; }
                      setState(() {
                        page = page + 1;
                        getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
                        },);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MailDetailApp extends StatefulWidget {
  final String postid;
  const MailDetailApp({super.key, required this.postid});

  @override
  State<MailDetailApp> createState() => _MailDetailAppState();
}

class _MailDetailAppState extends State<MailDetailApp> {
  static const appTitle = "站内信";
  late CancelableOperation getDataCancelable;

  Future<MailDetailInfo> getData() async {
    // return getExampleMailDetailInfo();
    var url = "$v2Host/mail-read.php?postid=${widget.postid}";
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return MailDetailInfo.error(errorMessage: networkErrorText);
    }
    return parseMailDetailInfo(resp.body);
  }

  @override
  void initState() {
    super.initState();
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    },);
  }

  @override
  void dispose() {
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
          // return const Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: const Text(appTitle),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(appTitle),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(appTitle),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var mailDetailInfo = snapshot.data as MailDetailInfo;
        if (mailDetailInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(appTitle),
            ),
            body: Center(
              child: Text(mailDetailInfo.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
              title: const Text(appTitle),
          ),
          body: MailDetailPage(mailDetailInfo: mailDetailInfo, postid: widget.postid),
        );
      },
    );
  }
}
