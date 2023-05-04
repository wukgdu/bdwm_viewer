import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../bdwm/req.dart';
import '../bdwm/search.dart';
import '../globalvars.dart';
import '../views/utils.dart';
import '../views/constants.dart' show bdwmPrimaryColor;
import '../views/search.dart';
import '../html_parser/search_parser.dart';
import '../views/search_result.dart';

class SimpleSearchResultPage extends StatefulWidget {
  final String mode;
  final String keyWord;
  const SimpleSearchResultPage({super.key, required this.mode, required this.keyWord});

  @override
  State<SimpleSearchResultPage> createState() => _SimpleSearchResultPageState();
}

class _SimpleSearchResultPageState extends State<SimpleSearchResultPage> {
  int page = 1;
  late CancelableOperation getDataCancelable;

  Future<SimpleSearchRes> getData() async {
    // return getExampleCollectionList();
    var url = "$v2Host/search.php?mode=${widget.mode}&key=${widget.keyWord}";
    if (page != 1) {
      url += "&page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return SimpleSearchRes.error(errorMessage: networkErrorText);
    }
    if (widget.mode=="user") {
      return parseUserSearch(resp.body);
    } else if (widget.mode == "board") {
      return parseBoardSearch(resp.body);
    }
    return SimpleSearchRes.error(errorMessage: "未知搜索");
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
              title: const Text("搜索"),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("搜索"),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("搜索"),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var simpleSearchRes = snapshot.data as SimpleSearchRes;
        if (simpleSearchRes.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("搜索失败"),
            ),
            body: Center(
              child: Text(simpleSearchRes.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text("搜索 ${widget.keyWord} 结果"),
          ),
          body: SimpleResultView(ssRes: simpleSearchRes, mode: widget.mode),
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
                    child: Text("$page/${simpleSearchRes.maxPage}"),
                    onPressed: () async {
                      var nPageStr = await showPageDialog(context, page, simpleSearchRes.maxPage);
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
                    onPressed: page >= simpleSearchRes.maxPage ? null : () {
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
class ComplexSearchResultPage extends StatefulWidget {
  final PostSearchSettings pss;
  const ComplexSearchResultPage({super.key, required this.pss,});

  @override
  State<ComplexSearchResultPage> createState() => _ComplexSearchResultPageState();
}

class _ComplexSearchResultPageState extends State<ComplexSearchResultPage> {
  int page = 1;
  late CancelableOperation getDataCancelable;

  Future<ComplexSearchRes> getData() async {
    // return getExampleCollectionList();
    var bid = "";
    var pss = widget.pss;
    if (pss.board.isNotEmpty) {
      var searchResp = await bdwmTopSearch(pss.board);
      bool findIt = false;
      if (searchResp.success) {
        var toBoardNameLc = pss.board.toLowerCase();
        for (var b in searchResp.boards) {
          if (b.name.toLowerCase() == toBoardNameLc) {
            bid = b.id;
            findIt = true;
            break;
          }
        }
      } else {
        if (searchResp.error == -1) {
          // network error
          bid = "";
        }
      }
      if (!findIt) {
        bid = "";
      }
    }
    var url = "$v2Host/search.php?mode=post&key=${pss.keyWord}&owner=${pss.owner}&board=${pss.board}&rated=${pss.rated}&days=${pss.days}&titleonly=${pss.titleonly}&timeorder=${pss.timeorder}&bid=$bid";
    if (page != 1) {
      url += "&page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return ComplexSearchRes.error(errorMessage: networkErrorText);
    }
    return parsePostSearch(resp.body);
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
              title: const Text("搜索"),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("搜索"),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("搜索"),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var complexSearchRes = snapshot.data as ComplexSearchRes;
        if (complexSearchRes.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("搜索失败"),
            ),
            body: Center(
              child: Text(complexSearchRes.errorMessage!),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text("搜索结果"),
          ),
          body: ComplexResultView(csRes: complexSearchRes,),
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
                    child: Text("$page/${complexSearchRes.maxPage}"),
                    onPressed: () async {
                      var nPageStr = await showPageDialog(context, page, complexSearchRes.maxPage);
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
                    onPressed: page >= complexSearchRes.maxPage ? null : () {
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