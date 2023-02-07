import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../views/read_thread.dart';
import '../views/utils.dart';
import '../html_parser/read_thread_parser.dart';
import '../bdwm/req.dart';
import '../views/constants.dart' show bdwmPrimaryColor;
import '../globalvars.dart';
import '../utils.dart' show clearAllExtendedImageCache;
import '../router.dart' show nv2Push, nv2Replace, ForceRerefreshWidget, getForceID, forceRefresh;

class MyFloatingActionButtonMenu extends StatefulWidget {
  final bool showFAB;
  final void Function({bool far}) gotoNextPost;
  final void Function({bool far}) gotoPreviousPost;
  final void Function(bool)? toggleIgnore;
  const MyFloatingActionButtonMenu({super.key, this.showFAB=true, required this.gotoNextPost, required this.gotoPreviousPost, this.toggleIgnore});

  @override
  State<MyFloatingActionButtonMenu> createState() => _MyFloatingActionButtonMenuState();
}

class _MyFloatingActionButtonMenuState extends State<MyFloatingActionButtonMenu> {
  late final Widget nextButton;
  late final Widget prevButton;
  late final Widget removeButton;
  bool isOpen = false;
  bool showFAB = true;
  static const vSpace = SizedBox(height: 5,);

  Widget genButton({required Icon icon, Function()? onTap, Function()? onLongPress}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: bdwmPrimaryColor, width: 1.0, style: BorderStyle.solid),
        ),
        child: icon,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    showFAB = widget.showFAB;
    nextButton = genButton(icon: Icon(Icons.arrow_downward, color: bdwmPrimaryColor,),
      onTap: () {
        widget.gotoNextPost();
      },
      onLongPress: () {
        widget.gotoNextPost(far: true);
      },
    );
    prevButton = genButton(icon: Icon(Icons.arrow_upward, color: bdwmPrimaryColor,),
      onTap: () {
        widget.gotoPreviousPost();
      },
      onLongPress: () {
        widget.gotoPreviousPost(far: true);
      },
    );
    removeButton = genButton(icon: Icon(Icons.remove, color: bdwmPrimaryColor,),
      onTap: () {
        if (widget.toggleIgnore!=null) {
          widget.toggleIgnore!(true);
        }
        setState(() {
          showFAB = false;
        });
      },
    );
  }

  @override
  void didUpdateWidget(covariant MyFloatingActionButtonMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // showFAB = widget.showFAB;
    isOpen = false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !showFAB ? Container() : Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOpen) ...[
          removeButton,
          vSpace,
          prevButton,
          vSpace,
          nextButton,
          vSpace,
        ],
        FloatingActionButton(
          isExtended: true,
          heroTag: "MyFloatingActionButtonMenu",
          onPressed: () {
            if (widget.toggleIgnore!=null) {
              widget.toggleIgnore!(isOpen);
            }
            setState(() {
              isOpen = !isOpen;
            });
          },
          backgroundColor: bdwmPrimaryColor,
          child: Icon(!isOpen ? Icons.menu : Icons.close, color: Colors.white,),
        ),
      ],
    );
  }
}

class ThreadDetailApp extends StatefulWidget {
  final Function refreshCallBack;
  final Function goPage;
  final ThreadPageInfo threadPageInfo;
  final String threadLink;
  final int page;
  final String userName;
  final String bid;
  final String threadid;
  final String? postid;
  final bool? needToBoard;
  final bool tiebaForm;
  final Function toggleTiebaForm;
  final bool showFAB;
  const ThreadDetailApp({super.key,
    required this.refreshCallBack, required this.threadPageInfo, required this.threadLink,
    required this.page, required this.goPage, required this.userName,
    required this.bid, required this.threadid, this.postid, this.needToBoard,
    required this.tiebaForm, required this.toggleTiebaForm,
    required this.showFAB,
  });

  @override
  State<ThreadDetailApp> createState() => _ThreadDetailAppState();
}

double? _initScrollHeight;
// 回复帖子主题帖重新刷新后，class内state的initScrollHeight会变化，可能因为输入法占了屏幕？
// 因此一开始保留这个变量用作之后的判断
class _ThreadDetailAppState extends State<ThreadDetailApp> {
  final _titleFont = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  ValueNotifier<bool> marked = ValueNotifier<bool>(false);
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  GlobalKey scrollKey = GlobalKey();
  var newOrder = <TiebaFormItemInfo>[];
  int? _lastIndex;
  double? _lastTrailingEdge;
  bool _showBottomAppBar = true;
  bool _ignorePrevNext = true;

  @override
  void initState() {
    super.initState();
    marked.value = globalMarkedThread.contains(widget.threadLink);
    if (widget.tiebaForm) {
      computeNewOrder();
    }
    if (globalConfigInfo.getAutoHideBottomBar()) {
      itemPositionsListener.itemPositions.addListener(listenToScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_){
      if (widget.postid != null) {
        var i = 0;
        while (i<widget.threadPageInfo.posts.length) {
          var p = widget.threadPageInfo.posts[i];
          if (p.postID == widget.postid) {
            break;
          }
          i+=1;
        }
        if ((i!=0) && (i<widget.threadPageInfo.posts.length)) {
          itemScrollController.scrollTo(index: i, duration: const Duration(milliseconds: 1500), curve: Curves.ease);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ThreadDetailApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ignorePrevNext = true;
    if (widget.tiebaForm) {
      computeNewOrder();
    } else {
      newOrder.clear();
    }
  }

  @override
  void dispose() {
    if (globalConfigInfo.getAutoHideBottomBar()) {
      itemPositionsListener.itemPositions.removeListener(listenToScroll);
    }
    marked.dispose();
    super.dispose();
  }

  Future<bool> addMarked({required String link, required String title, required String userName, required String boardName}) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    return await globalMarkedThread.addOne(link: link, title: title, userName: userName, boardName: boardName, timestamp: timestamp);
  }

  List<TiebaFormItemInfo> computeTiebaIndex() {
    var res = <TiebaFormItemInfo>[];
    List<String> firstLine = [];
    List<String> quoteID = [];
    List<String> firstQuoteLine = [];
    for (int i=0; i<widget.threadPageInfo.posts.length; i+=1) {
      var res = getShortInfoFromContent(widget.threadPageInfo.posts[i].content);
      firstLine.add(res[0]);
      quoteID.add(res[1]);
      firstQuoteLine.add(res[2]);
    }
    for (int i=0; i<widget.threadPageInfo.posts.length; i+=1) {
      var postInfo = widget.threadPageInfo.posts[i];
      var postid = int.parse(postInfo.postID);
      var parentIdx= i;
      var oriIdx = i;
      var subIdx = 0;
      if (i==0) {
        res.add(TiebaFormItemInfo(postid: postid, oriIdx: oriIdx, parentIdx: parentIdx, subIdx: subIdx));
        continue;
      }
      int j=i-1;
      for (; j>=0; j-=1) {
        if (quoteID[i] == widget.threadPageInfo.posts[j].authorInfo.userName) {
          if (firstQuoteLine[i] == firstLine[j]) {
            break;
          }
        }
      }
      if (j==-1) {
        parentIdx = oriIdx;
        subIdx = 0;
      } else {
        parentIdx = j;
        subIdx = res[j].subIdx+1;
      }
      res.add(TiebaFormItemInfo(postid: postid, oriIdx: oriIdx, parentIdx: parentIdx, subIdx: subIdx));
    }
    return res;
  }
  
  void computeNewOrder() {
    newOrder = computeTiebaIndex();
    List<List<int>> ancestorLists = [];
    for (var ele in newOrder) {
      var aPList = <int>[];
      var sIdx = ele.oriIdx;
      while (true) {
        aPList.add(sIdx);
        var nIdx = newOrder[sIdx].parentIdx;
        if (nIdx == sIdx) {
          break;
        }
        sIdx = nIdx;
      }
      ancestorLists.add(aPList.reversed.toList());
    }
    newOrder.sort((a, b) {
      var aPList = ancestorLists[a.oriIdx];
      var bPList = ancestorLists[b.oriIdx];
      int i=0;
      for (;i < aPList.length && i < bPList.length; i+=1) {
        if (aPList[i] == bPList[i]) {
          continue;
        }
        return aPList[i] - bPList[i];
      }
      if (i < aPList.length) {
        return 1;
      }
      return -1;
    },);
  }

  ItemPosition getFirstItem() {
    var itemPositions = itemPositionsListener.itemPositions.value.toList();
    var firstPosition = itemPositions.first;
    for (var ips in itemPositions) {
      if (firstPosition.index > ips.index) {
        firstPosition = ips;
      }
    }
    return firstPosition;
  }

  ItemPosition getLastItem() {
    var itemPositions = itemPositionsListener.itemPositions.value.toList();
    var lastPosition = itemPositions.last;
    for (var ips in itemPositions) {
      if (lastPosition.index < ips.index) {
        lastPosition = ips;
      }
    }
    return lastPosition;
  }

  void gotoPreviousPost({bool far=false}) {
    if (far) {
      itemScrollController.scrollTo(index: 0, duration: const Duration(milliseconds: 1500), curve: Curves.ease);
      return;
    }
    var firstPosition = getFirstItem();
    var prevIndex = firstPosition.index-1;
    if (firstPosition.itemLeadingEdge < 0) {
      prevIndex = firstPosition.index;
    }
    if (prevIndex < 0) {
      prevIndex = 0;
    }
    itemScrollController.jumpTo(index: prevIndex);
  }

  void gotoNextPost({bool far=false}) {
    if (far) {
      itemScrollController.scrollTo(index: widget.threadPageInfo.posts.length-1, duration: const Duration(milliseconds: 1500), curve: Curves.ease);
      return;
    }
    var firstPosition = getFirstItem();
    var nextIndex = firstPosition.index + 1;
    if (nextIndex > widget.threadPageInfo.posts.length-1) {
      return;
    }
    itemScrollController.jumpTo(index: nextIndex);
  }

  void showBottomAppBar() {
    if (!_ignorePrevNext) { return; }
    if (!_showBottomAppBar) {
      setState(() { _showBottomAppBar = true; });
    }
  }

  void hideBottomAppBar() {
    if (!_ignorePrevNext) { return; }
    if (_showBottomAppBar) {
      setState(() { _showBottomAppBar = false; });
    }
  }

  bool sameWithDelta(double a, double b, {double delta=0.1}) {
    if ((a-b).abs() < delta) {
      return true;
    }
    return false;
  }

  void listenToScroll() {
    const double delta = 2.0; // MD3 height of bottomAppBar is 80.0
    var scrollListHeight = scrollKey.currentContext?.size?.height ?? 1.0;
    _initScrollHeight ??= scrollListHeight;
    var lastPosition = getLastItem();
    if (_lastIndex==null) {
      _lastIndex = lastPosition.index;
      _lastTrailingEdge = lastPosition.itemTrailingEdge * scrollListHeight;
      return;
    }
    int hideIt = 0;
    double newTrailingEdge = lastPosition.itemTrailingEdge * scrollListHeight;
    if (lastPosition.index > _lastIndex!) {
      hideIt = 1;
    } else if (lastPosition.index < _lastIndex!) {
      hideIt = -1;
    } else {
      if ((newTrailingEdge < _lastTrailingEdge! - delta)) {
        hideIt = 1;
      } else if ((newTrailingEdge > _lastTrailingEdge! + delta)) {
        hideIt = -1;
      }
    }
    // debugPrint("$hideIt $_showBottomAppBar $scrollListHeight $_lastTrailingEdge $newTrailingEdge $_initScrollHeight");
    if (sameWithDelta(newTrailingEdge, scrollListHeight) && sameWithDelta(newTrailingEdge, _lastTrailingEdge!+80.0)) {
      hideIt = 0;
    }
    if (!_showBottomAppBar && (_initScrollHeight! - 0.1 < newTrailingEdge) && (newTrailingEdge <= _initScrollHeight!+80.1)) {
      // MD3 bottom app bar height < 80，用80判断也没问题
      hideIt = 0;
    }
    _lastIndex = lastPosition.index;
    _lastTrailingEdge = newTrailingEdge;
    if (hideIt == 1) {
      hideBottomAppBar();
    } else if (hideIt == -1) {
      showBottomAppBar();
    }
  }

  Widget _onepost(OnePostInfo item, {int? subIdx}) {
    var userName = item.authorInfo.userName;
    Set<String> seeNoHimHer = globalConfigInfo.getSeeNoThem();
    var hideIt = false;
    if (seeNoHimHer.contains(userName.toLowerCase())) {
      hideIt = true;
    }
    return OnePostComponent(onePostInfo: item, bid: widget.bid, refreshCallBack: widget.refreshCallBack,
      boardName: widget.threadPageInfo.board.text, threadid: widget.threadid,
      subIdx: subIdx, hideIt: hideIt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.threadPageInfo.board.text.split('(').first),
        actions: [
          ValueListenableBuilder(
            valueListenable: marked,
            builder: (context, value, child) {
              bool markedValue = value as bool;
              return IconButton(
                onPressed: () async {
                  if (markedValue) {
                    globalMarkedThread.removeOne(widget.threadLink);
                  } else {
                    var notfull = await addMarked(link: widget.threadLink, title: widget.threadPageInfo.title, userName: widget.userName, boardName: widget.threadPageInfo.board.text);
                    if (notfull == false) {
                      if (!mounted) { return; }
                      showAlertDialog(context, "收藏数量已达上限", const Text("rt"),
                        actions1: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("取消"),
                        ),
                        actions2: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            nv2Push(context, '/markedThread');
                          },
                          child: const Text("清理"),
                        ),
                      );
                      return;
                    }
                  }
                  marked.value = !markedValue;
                },
                icon: Icon(markedValue ? Icons.star : Icons.star_outline),
              );
            },
          ),
          IconButton(
            onPressed: () {
              widget.toggleTiebaForm();
            },
            icon: Icon(widget.tiebaForm ? Icons.change_circle : Icons.account_tree),
          ),
          IconButton(
            onPressed: () {
              if (!mounted) { return; }
              shareWithResultWrap(context, "$v2Host/post-read.php?bid=${widget.threadPageInfo.boardid}&threadid=${widget.threadPageInfo.threadid}", subject: "分享帖子");
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onDoubleTap: () {
              // Scrollable.ensureVisible(itemKeys[0].currentContext!, duration: const Duration(milliseconds: 1500));
              gotoPreviousPost(far: true);
            },
            onLongPress: () {
              gotoNextPost(far: true);
            },
            child: Container(
              padding: const EdgeInsets.all(10.0),
              alignment: Alignment.centerLeft,
              // height: 20,
              child: Text(
                widget.threadPageInfo.title,
                style: _titleFont,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                var dx = details.velocity.pixelsPerSecond.dx;
                if (dx < 10) {
                  // 向左滑动
                  if (widget.page < widget.threadPageInfo.pageNum) {
                    widget.goPage(widget.page+1);
                  }
                } else if (dx > 10) {
                  if (widget.page > 1) {
                    widget.goPage(widget.page-1);
                  }
                }
              },
              child: ScrollablePositionedList.builder(
                key: scrollKey,
                itemCount: widget.threadPageInfo.posts.length,
                itemBuilder: (context, index) {
                  if (widget.tiebaForm) {
                    var oriIdx = newOrder[index].oriIdx;
                    var subIdx = newOrder[index].subIdx;
                    return _onepost(widget.threadPageInfo.posts[oriIdx], subIdx: subIdx > 5 ? 5 : subIdx);
                  }
                  return _onepost(widget.threadPageInfo.posts[index]);
                },
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _showBottomAppBar ? (globalConfigInfo.useMD3 ? 80.0 : null) : 0,
        child: BottomAppBar(
          shape: null,
          // color: Colors.blue,
          // height: _showBottomAppBar ? null : 0.0,
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
                    widget.refreshCallBack();
                  },
                ),
                if (widget.needToBoard != null && widget.needToBoard == true)
                  IconButton(
                    color: bdwmPrimaryColor,
                    disabledColor: Colors.grey,
                    tooltip: '返回本版',
                    icon: const Icon(Icons.list),
                    onPressed: () {
                      nv2Push(context, '/board', arguments: {
                        'boardName': widget.threadPageInfo.board.text.split('(').first,
                        'bid': widget.threadPageInfo.boardid,
                      },);
                    },
                  ),
                IconButton(
                  color: bdwmPrimaryColor,
                  disabledColor: Colors.grey,
                  tooltip: '上一页',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.page == 1 ? null : () {
                    if (!mounted) { return; }
                    widget.goPage(widget.page-1);
                  },
                ),
                TextButton(
                  child: Text("${widget.page}/${widget.threadPageInfo.pageNum}"),
                  onPressed: () async {
                    var nPageStr = await showPageDialog(context, widget.page, widget.threadPageInfo.pageNum);
                    if (nPageStr == null) { return; }
                    if (nPageStr.isEmpty) { return; }
                    var nPage = int.parse(nPageStr);
                    widget.goPage(nPage);
                  },
                  onLongPress: () {
                    var newPage = widget.page;
                    if (widget.page == widget.threadPageInfo.pageNum) {
                      newPage = 1;
                    } else {
                      newPage = widget.threadPageInfo.pageNum;
                    }
                    if (newPage == widget.page) { return; }
                    widget.goPage(newPage);
                  },
                ),
                IconButton(
                  color: bdwmPrimaryColor,
                  disabledColor: Colors.grey,
                  tooltip: '下一页',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: widget.page == widget.threadPageInfo.pageNum ? null : () {
                    // if (page == threadPageInfo.pageNum) {
                    //   return;
                    // }
                    if (!mounted) { return; }
                    widget.goPage(widget.page+1);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: !widget.showFAB ? null : MyFloatingActionButtonMenu(
        showFAB: widget.showFAB,
        gotoNextPost: ({bool far=false}) {
          gotoNextPost(far: far);
        },
        gotoPreviousPost: ({bool far=false}) {
          gotoPreviousPost(far: far);
        },
        toggleIgnore: (bool newValue) {
          _ignorePrevNext = newValue;
        },
      ),
    );
  }
}

class ThreadApp extends StatefulWidget {
  final String bid;
  final String threadid;
  final String page;
  final String? boardName;
  final bool? needToBoard;
  final String? postid;
  const ThreadApp({Key? key, required this.bid, required this.threadid, this.boardName, required this.page, this.needToBoard, this.postid}) : super(key: key);

  @override
  State <ThreadApp> createState() =>  ThreadAppState();
}

class  ThreadAppState extends State <ThreadApp> {
  int page = 1;
  late CancelableOperation getDataCancelable;
  bool firstTime = true;
  String? postid;
  String threadLink = "";
  bool tiebaForm = false;
  bool showFAB = true;
  // Future<ThreadPageInfo>? _future;
  @override
  void initState() {
    super.initState();
    page = widget.page.isEmpty
      ? 1
      : widget.page == "a"
        ? 1
        : int.parse(widget.page);
    // _future = getData();
    postid = widget.postid;
    showFAB = globalConfigInfo.getShowFAB();
    threadLink = "$v2Host/post-read.php?bid=${widget.bid}&threadid=${widget.threadid}";
    // called in didChangeDepencies
    // getDataCancelable = CancelableOperation.fromFuture(getData(firstTime: true), onCancel: () {
    //   debugPrint("cancel it");
    // },);
  }

  void addHistory({required String link, required String title, required String userName, required String boardName}) {
    if (firstTime == false) { return; }
    firstTime = false;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    globalThreadHistory.addOne(link: link, title: title, userName: userName, boardName: boardName, timestamp: timestamp);
  }

  @override
  void dispose() {
    Future.microtask(() => getDataCancelable.cancel(),);
    clearAllExtendedImageCache(really: globalConfigInfo.getAutoClearImageCache());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    int pid = getForceID();
    postid = pid == -1 ? widget.postid : pid.toString();
    debugPrint("*************** change $pid");
    forceRefresh(-1);
    getDataCancelable = CancelableOperation.fromFuture(getData(firstTime: true), onCancel: () {
      debugPrint("cancel it");
    },);
  }

  Future<ThreadPageInfo> getData({bool firstTime=false}) async {
    var bid = widget.bid;
    var threadid = widget.threadid;
    var url = "$v2Host/post-read.php?bid=$bid&threadid=$threadid";
    if (!firstTime) {
      postid = null;
    }
    if (firstTime && postid != null) {
      url += "&page=a";
      url += "&postid=$postid";
      // postid = null;
    } else if (! (page == 0 || page == 1)) {
      url += "&page=$page";
    }
    var resp = await bdwmClient.get(url, headers: genHeaders2());
    if (resp == null) {
      return ThreadPageInfo.error(errorMessage: networkErrorText);
    }
    return parseThread(resp.body);
  }

  void refresh() {
    goPage(page);
  }

  void goPage(int newPage) {
    setState(() {
      page = newPage;
      getDataCancelable = CancelableOperation.fromFuture(getData(), onCancel: () {
        debugPrint("cancel it");
      },);
    });
  }

  @override
  Widget build(BuildContext context) {
    int needReloadID = ForceRerefreshWidget.maybeOf(context)?.reload ?? -1;
    return FutureBuilder(
      future: getDataCancelable.value,
      builder: (context, snapshot) {
        // debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState != ConnectionState.done) {
          // return const Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName ?? "看帖"),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName ?? "看帖"),
            ),
            body: Center(child: Text("错误：${snapshot.error}"),),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName ?? "看帖"),
            ),
            body: const Center(child: Text("错误：未获取数据"),),
          );
        }
        var threadPageInfo = snapshot.data as ThreadPageInfo;
        if (threadPageInfo.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.boardName ?? ""),
            ),
            body: Center(
              child: Text(threadPageInfo.errorMessage!),
            ),
          );
        }
        if (threadPageInfo.page != page) {
          page = threadPageInfo.page;
        }
        // String userName = "未知";
        String userName = "未知+$needReloadID";
        if (threadPageInfo.posts.isNotEmpty) {
          userName = threadPageInfo.posts.first.authorInfo.userName;
        }
        addHistory(link: threadLink, title: threadPageInfo.title, userName: userName, boardName: threadPageInfo.board.text);
        return ThreadDetailApp(
          threadPageInfo: threadPageInfo,
          page: page,
          userName: userName,
          bid: widget.bid,
          threadid: widget.threadid,
          threadLink: threadLink,
          goPage: (int newPage) {
            goPage(newPage);
          },
          refreshCallBack: () {
            refresh();
          },
          tiebaForm: tiebaForm,
          toggleTiebaForm: () {
            setState(() {
              tiebaForm = !tiebaForm;
            });
          },
          showFAB: showFAB,
          postid: postid,
          needToBoard: widget.needToBoard,
        );
      }
    );
  }
}

// WidgetBuilder? gotoThread(RouteSettings settings) {
WidgetBuilder? gotoThread(Object? arguments) {
  WidgetBuilder builder;
  var page = gotoThreadPage(arguments);
  if (page == null) { return null; }
  builder = (BuildContext context) => page;
  return builder;
}

Widget? gotoThreadPage(Object? arguments) {
  String bid = "";
  String threadid = "";
  String boardName = "";
  String page = "";
  String? postid;
  bool? needToBoard;
  if (arguments != null) {
    var settingsMap = arguments as Map;
    bid = settingsMap['bid'] as String;
    threadid = settingsMap['threadid'] as String;
    boardName = settingsMap['boardName'] as String;
    page = settingsMap['page'] as String;
    postid = settingsMap['postid'] as String?;
    needToBoard = settingsMap['needToBoard'] as bool?;
  } else {
    return null;
  }
  return ThreadApp(boardName: boardName, bid: bid, threadid: threadid, page: page, needToBoard: needToBoard, postid: postid);
}

void naviGotoThread(context, String bid, String threadid, String page, String boardName, {bool? needToBoard}) {
  nv2Push(context, '/thread', arguments: {
    'bid': bid,
    'threadid': threadid,
    'page': page,
    'boardName': boardName,
    'needToBoard': needToBoard,
  });
}

void naviGotoThreadByLink(context, String link, String boardName, {bool? needToBoard, String? pageDefault, bool replaceIt=false}) {
  var pb1 = link.indexOf('bid');
  if (pb1 == -1) {
    return;
  }
  var pb2 = link.indexOf('&', pb1);
  var bid = link.substring(pb1+4, pb2 == -1 ? null : pb2);
  var page = pageDefault ?? "1";
  String? postid;
  if (pageDefault != null) {
    var pp1 = link.indexOf('postid');
    if (pp1 != -1) {
      var pp2 = link.indexOf('&', pp1);
      postid = link.substring(pp1+7, pp2 == -1 ? null : pp2);
      postid = postid.split("#").first;
    }
  } else {
    var pp1 = link.indexOf('postid');
    if (pp1 != -1) {
      var pp2 = link.indexOf('&', pp1);
      postid = link.substring(pp1+7, pp2 == -1 ? null : pp2);
      postid = postid.split("#").first;
    }
    var pg1 = link.indexOf("page");
    if (pg1 != -1) {
      var pg2 = link.indexOf('&', pg1);
      page = link.substring(pg1+5, pg2 == -1 ? null : pg2);
    }
  }
  var pt1 = link.indexOf('threadid');
  if (pt1 == -1) {
    return;
  }
  var pt2 = link.indexOf('&', pt1);
  var threadid = link.substring(pt1+9, pt2 == -1 ? null : pt2);
  var nv2Do = replaceIt ? nv2Replace : nv2Push;
  nv2Do(context, '/thread', arguments: {
    'bid': bid,
    'threadid': threadid,
    'page': page,
    'boardName': boardName,
    'needToBoard': needToBoard,
    'postid': postid,
  });
}
