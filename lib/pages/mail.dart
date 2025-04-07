import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../views/mail.dart';
import '../html_parser/mail_parser.dart';
import '../globalvars.dart';
import '../views/utils.dart' show showPageDialog, showComplexInformDialog, genScrollableWidgetForPullRefresh;
import '../router.dart' show nv2Push;
import '../views/constants.dart' show bdwmPrimaryColor;

class MailListPage extends StatefulWidget {
  const MailListPage({super.key});

  @override
  State<MailListPage> createState() => _MailListPageState();
}

class _MailListPageState extends State<MailListPage> {
  String appTitle = "站内信";
  int page = 1;
  String type = "";
  late CancelableOperation getDataCancelable;

  Future<MailListInfo> getData() async {
    // return getExampleCollectionList();
    var url = "$v2Host/mail.php";
    if (type.isNotEmpty) {
      url += "?type=$type";
    }
    if (page != 1) {
      var prefix = type.isEmpty ? "?" : "&";
      url += "${prefix}page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return MailListInfo.error(errorMessage: networkErrorText);
    }
    return parseMailList(resp.body);
  }

  Future<void> updateDataAsync() async {
    refresh();
  }

  void refresh() {
    setState(() {
      page = page;
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      },);
    });
  }

  void changeToMode(String mode) {
    setState(() {
      page = 1;
      if (mode.isNotEmpty) {
        if (mode=="删除") {
          type = "5";
          appTitle = "删除";
        } else if (mode=="星标") {
          type = "3";
          appTitle = "星标";
        } else if (mode=="已发送") {
          type = "4";
          appTitle = "已发送";
        }
      } else {
        type = "";
        appTitle = "站内信";
      }
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
              title: Text(appTitle),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(appTitle),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(appTitle),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var mailListInfo = snapshot.data as MailListInfo;
        if (mailListInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(appTitle),
            ),
            body: RefreshIndicator(
              onRefresh: updateDataAsync,
              child: genScrollableWidgetForPullRefresh(
                Center(
                  child: Text(mailListInfo.errorMessage!),
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {
                  showComplexInformDialog(context, "属性", SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text("容量： "),
                            Expanded(
                              child: LinearProgressIndicator(value: mailListInfo.capacity, backgroundColor: bdwmPrimaryColor.withAlpha(75),),
                            ),
                            const Text(" "),
                            Text(mailListInfo.sizeString),
                          ],
                        )
                      ],
                    ),
                  ));
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  nv2Push(context, '/mailNew');
                },
              ),
              PopupMenuButton(
                // icon: const Icon(Icons.more_horiz),
                onSelected: (value) {
                  changeToMode(value);
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
          body: MailListView(mailListInfo: mailListInfo, type: type, refreshCallBack: () { refresh(); },),
          bottomNavigationBar: BottomAppBar(
            shape: null,
            // color: Colors.blue,
            child: IconTheme(
              data: const IconThemeData(color: Colors.redAccent),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '刷新',
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      refresh();
                    },
                  ),
                  IconButton(
                    color: bdwmPrimaryColor,
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
                    color: bdwmPrimaryColor,
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

class MailDetailPage extends StatefulWidget {
  final String postid;
  final String type;
  const MailDetailPage({super.key, required this.postid, required this.type});

  @override
  State<MailDetailPage> createState() => _MailDetailPageState();
}

class _MailDetailPageState extends State<MailDetailPage> {
  String appTitle = "站内信";
  late CancelableOperation getDataCancelable;

  Future<MailDetailInfo> getData() async {
    // return getExampleMailDetailInfo();
    var url = "$v2Host/mail-read.php?postid=${widget.postid}";
    if (widget.type.isNotEmpty) {
      url = "$v2Host/mail-read.php?type=${widget.type}&postid=${widget.postid}";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return MailDetailInfo.error(errorMessage: networkErrorText);
    }
    return parseMailDetailInfo(resp.body);
  }

  @override
  void initState() {
    super.initState();
    if (widget.type.isNotEmpty) {
      if (widget.type=="5") {
        appTitle = "删除";
      } else if (widget.type=="3") {
        appTitle = "星标";
      } else if (widget.type=="4") {
        appTitle = "已发送";
      }
    } else {
      appTitle = "站内信";
    }
    getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
    },);
  }

  @override
  void dispose() {
    Future.microtask(() => getDataCancelable.cancel(),);
    super.dispose();
  }

  void refresh() {
    if (!mounted) { return; }
    setState(() {
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
      },);
    });
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
              title: Text(appTitle),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(appTitle),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(appTitle),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var mailDetailInfo = snapshot.data as MailDetailInfo;
        if (mailDetailInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(appTitle),
            ),
            body: Center(
              child: Text(mailDetailInfo.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
              title: Text(appTitle),
          ),
          body: MailDetailView(mailDetailInfo: mailDetailInfo, postid: widget.postid, type: widget.type, refreshCallBack: () { refresh(); },),
        );
      },
    );
  }
}
