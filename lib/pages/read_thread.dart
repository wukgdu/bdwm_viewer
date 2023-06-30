import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter/rendering.dart';
// import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../views/read_thread.dart';
import '../views/utils.dart' show genScrollableWidgetForPullRefresh, showAlertDialog, showPageDialog, LongPressIconButton, shareWithResultWrap, showInformDialog;
import '../html_parser/read_thread_parser.dart';
import '../bdwm/req.dart';
import '../views/constants.dart' show bdwmPrimaryColor;
import '../globalvars.dart';
import '../utils.dart' show clearAllExtendedImageCache, breakLongText, getQueryValueImproved;
import '../router.dart' show nv2Push, nv2Replace, ForceRerefreshWidget, getForceID, forceRefresh;

const double md3BottomAppBarHeight = 80.0;

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

class DragToPrevNextPageOverlay2 {
  // simple arrow icon
  OverlayEntry? _overlayEntry;
  double threshold;
  Offset initOffset = const Offset(0, 0);
  ValueNotifier<double> dx = ValueNotifier<double>(0.0);
  int direction=0;

  DragToPrevNextPageOverlay2({
    required this.threshold,
  });

  void dispose() {
    dx.dispose();
  }

  void insert(BuildContext context, {required Offset initOffset}) {
    direction = 0;
    dx.value = 0.0;
    final deviceSize = MediaQuery.of(context).size;
    this.initOffset = initOffset;
    _overlayEntry = create(deviceSize);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void update(Offset newOffset) {
    dx.value = newOffset.dx - initOffset.dx;
    // _overlayEntry?.markNeedsBuild();
  }

  void remove() {
    direction = 0;
    initOffset = const Offset(0, 0);
    _overlayEntry?.remove();
  }

  OverlayEntry create(Size deviceSize) {
    return OverlayEntry(
      builder: (context) {
        var backgroundColor = ElevationOverlay.applySurfaceTint(Theme.of(context).canvasColor, bdwmPrimaryColor, BottomAppBarTheme.of(context).elevation ?? 20.0);
        return ValueListenableBuilder(
          valueListenable: dx,
          builder: (context, value, child) {
            var ndx = value as double;
            var rdx = ndx.abs();
            if (ndx == 0.0) {
              return Container();
            }
            if (rdx >= threshold) {
              rdx = threshold;
              direction = ndx < 0 ? 1 : -1;
            } else {
              direction = 0;
            }
            double borderDistance = 12.0 + 12.0 * rdx / threshold;
            double entrySize = 20.0 + 32.0 * rdx / threshold;
            if (entrySize > 36.0) { entrySize = 36.0; }
            double arrowSize = entrySize * 0.6;
            return Positioned(
              top: deviceSize.height / 2 - entrySize / 2,
              left: ndx < 0.0 ?  deviceSize.width-entrySize-borderDistance : borderDistance,
              child: Container(
                width: entrySize,
                height: entrySize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                ),
                child: Icon(
                  ndx < 0.0 ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  color: direction == 0 ? Colors.grey : bdwmPrimaryColor,
                  size: arrowSize,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  // final Animation<double> percentage;
  final Color color;

  _ArrowPainter({
    // required this.percentage,
    required this.color,
  });
  // : super(repaint: percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    var path = Path();
    path.moveTo(0, size.height/2);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height/2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return false;
    // return percentage.value != oldDelegate.percentage.value;
  }
}

class DragToPrevNextPageOverlay {
  // progress arrow
  OverlayEntry? _overlayEntry;
  double threshold;
  Offset initOffset = const Offset(0, 0);
  ValueNotifier<double> dx = ValueNotifier<double>(0.0);
  int direction=0;

  DragToPrevNextPageOverlay({
    required this.threshold,
  });

  void dispose() {
    dx.dispose();
  }

  void insert(BuildContext context, {required Offset initOffset}) {
    direction = 0;
    dx.value = 0.0;
    final deviceSize = MediaQuery.of(context).size;
    this.initOffset = initOffset;
    _overlayEntry = create(deviceSize);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void update(Offset newOffset) {
    dx.value = newOffset.dx - initOffset.dx;
    // _overlayEntry?.markNeedsBuild();
  }

  void remove() {
    direction = 0;
    initOffset = const Offset(0, 0);
    _overlayEntry?.remove();
  }

  OverlayEntry create(Size deviceSize) {
    double entryWidth = deviceSize.width / 4;
    double entryHeight = entryWidth * 0.3;
    double barWidth = entryWidth * 0.8;
    double barHeight = entryHeight * 0.5;
    return OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: dx,
          builder: (context, value, child) {
            var ndx = value as double;
            var rdx = ndx.abs();
            if (ndx == 0.0) {
              return Container();
            }
            if (rdx >= threshold) {
              rdx = threshold;
              direction = ndx < 0 ? 1 : -1;
            } else {
              direction = 0;
            }
            return Positioned(
              top: deviceSize.height / 2 - entryHeight / 2,
              left: ndx < 0.0 ?  deviceSize.width-entryWidth-10 : 10,
              child: Transform.scale(
                scaleX: ndx < 0.0 ? -1 : 1,
                child: SizedBox(
                  width: entryWidth,
                  height: entryHeight,
                  child: Row(
                    children: [
                      SizedBox(
                        width: entryWidth - barWidth,
                        height: entryHeight,
                        child: child,
                      ),
                      SizedBox(
                        width: barWidth,
                        height: barHeight,
                        child: LinearProgressIndicator(
                          value: rdx/threshold, color: bdwmPrimaryColor, backgroundColor: bdwmPrimaryColor.withOpacity(0.5),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
          child: CustomPaint(
            size: Size(entryWidth-barWidth, entryWidth),
            painter: _ArrowPainter(color: bdwmPrimaryColor),
          ),
        );
      },
    );
  }
}

class ThreadDetailPage extends StatefulWidget {
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
  const ThreadDetailPage({super.key,
    required this.refreshCallBack, required this.threadPageInfo, required this.threadLink,
    required this.page, required this.goPage, required this.userName,
    required this.bid, required this.threadid, this.postid, this.needToBoard,
    required this.tiebaForm, required this.toggleTiebaForm,
    required this.showFAB,
  });

  @override
  State<ThreadDetailPage> createState() => _ThreadDetailPageState();
}

// double? _initScrollHeight;
// void resetInitScrollHeight() {
//   _initScrollHeight = null;
// }
// 回复帖子主题帖重新刷新后，class内state的initScrollHeight会变化，可能因为输入法占了屏幕？
// 因此一开始保留这个变量用作之后的判断
class _ThreadDetailPageState extends State<ThreadDetailPage> {
  final _titleFont = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> marked = ValueNotifier<bool>(false);
  // final ItemScrollController itemScrollController = ItemScrollController();
  // final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  GlobalKey scrollKey = GlobalKey();
  var newOrder = <TiebaFormItemInfo>[];
  // int? _lastIndex;
  // double? _lastTrailingEdge;
  final ValueNotifier<bool> _showBottomAppBar = ValueNotifier<bool>(true);
  bool _ignorePrevNext = true;
  late final DragToPrevNextPageOverlay2 overlayController;

  @override
  void initState() {
    super.initState();
    marked.value = globalMarkedThread.contains(widget.threadLink);
    if (widget.tiebaForm) {
      computeNewOrder();
    }
    if (globalConfigInfo.getAutoHideBottomBar()) {
      // itemPositionsListener.itemPositions.addListener(listenToScroll);
      _scrollController.addListener(listenToScrollRaw);
    }
    WidgetsBinding.instance.addPostFrameCallback((_){
      // _initScrollHeight = scrollKey.currentContext?.size?.height;
      var threshold = MediaQuery.of(context).size.width / 4.0;
      if (threshold > 108.0) { threshold = 108.0; }
      overlayController = DragToPrevNextPageOverlay2(threshold: threshold);
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
          // itemScrollController.scrollTo(index: i, duration: const Duration(milliseconds: 1500), curve: Curves.ease);
          var kStr = widget.threadPageInfo.posts[i].postNumber;
          var k = GlobalObjectKey(kStr);
          if (k.currentContext==null) { return; }
          Scrollable.ensureVisible(k.currentContext!, duration: const Duration(milliseconds: 1500), curve: Curves.ease)
          .then((_) {
            Scrollable.ensureVisible(k.currentContext!, duration: const Duration(milliseconds: 500), curve: Curves.ease);
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ThreadDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ignorePrevNext = true;
    if (globalConfigInfo.getAutoHideBottomBar()) {
      // itemPositionsListener.itemPositions.removeListener(listenToScroll);
      // itemPositionsListener.itemPositions.addListener(listenToScroll);
      _scrollController.removeListener(listenToScrollRaw);
      _scrollController.addListener(listenToScrollRaw);
    }
    if (widget.tiebaForm) {
      computeNewOrder();
    } else {
      newOrder.clear();
    }
  }

  @override
  void dispose() {
    if (globalConfigInfo.getAutoHideBottomBar()) {
      // itemPositionsListener.itemPositions.removeListener(listenToScroll);
      _scrollController.removeListener(listenToScrollRaw);
    }
    marked.dispose();
    _showBottomAppBar.dispose();
    _scrollController.dispose();
    overlayController.dispose();
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

  // ItemPosition getFirstItem() {
  //   var itemPositions = itemPositionsListener.itemPositions.value.toList();
  //   var firstPosition = itemPositions.first;
  //   for (var ips in itemPositions) {
  //     if (firstPosition.index > ips.index) {
  //       firstPosition = ips;
  //     }
  //   }
  //   return firstPosition;
  // }

  // ItemPosition getLastItem() {
  //   var itemPositions = itemPositionsListener.itemPositions.value.toList();
  //   var lastPosition = itemPositions.last;
  //   for (var ips in itemPositions) {
  //     if (lastPosition.index < ips.index) {
  //       lastPosition = ips;
  //     }
  //   }
  //   return lastPosition;
  // }

  // void gotoPreviousPost({bool far=false}) {
  //   if (far) {
  //     itemScrollController.scrollTo(index: 0, duration: const Duration(milliseconds: 1500), curve: Curves.ease);
  //     return;
  //   }
  //   var firstPosition = getFirstItem();
  //   var prevIndex = firstPosition.index-1;
  //   if (firstPosition.itemLeadingEdge < 0) {
  //     prevIndex = firstPosition.index;
  //   }
  //   if (prevIndex < 0) {
  //     prevIndex = 0;
  //   }
  //   itemScrollController.jumpTo(index: prevIndex);
  // }

  // void gotoNextPost({bool far=false}) {
  //   if (far) {
  //     itemScrollController.scrollTo(index: widget.threadPageInfo.posts.length-1, duration: const Duration(milliseconds: 1500), curve: Curves.ease);
  //     return;
  //   }
  //   var firstPosition = getFirstItem();
  //   var nextIndex = firstPosition.index + 1;
  //   if (nextIndex > widget.threadPageInfo.posts.length-1) {
  //     return;
  //   }
  //   itemScrollController.jumpTo(index: nextIndex);
  // }

  void gotoPreviousPostRaw({bool far=false}) {
    if (far) {
      _scrollController.animateTo(_scrollController.position.minScrollExtent, duration: const Duration(milliseconds: 1500), curve: Curves.ease);
      return;
    }
    var scrollListBox = scrollKey.currentContext?.findRenderObject() as RenderBox?;
    if (scrollListBox == null) { return; }
    var validContext = <BuildContext>[];
    var validY = <double>[];
    for (var item in widget.threadPageInfo.posts) {
      var kStr = item.postNumber;
      var k = GlobalObjectKey(kStr);
      if (k.currentContext != null) {
        validContext.add(k.currentContext!);
        var box = k.currentContext!.findRenderObject() as RenderBox?;
        if (box == null) { return; }
        validY.add(box.localToGlobal(Offset.zero).dy);
      }
    }
    var leadingEdge = scrollListBox.localToGlobal(Offset.zero).dy;
    for (var i=validY.length-1; i>=0; i-=1) {
      if (validY[i] < leadingEdge) {
        Scrollable.ensureVisible(validContext[i]);
        break;
      }
    }
  }

  void gotoNextPostRaw({bool far=false}) {
    if (far) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 1500), curve: Curves.ease);
      return;
    }
    var scrollListBox = scrollKey.currentContext?.findRenderObject() as RenderBox?;
    if (scrollListBox == null) { return; }
    var validContext = <BuildContext>[];
    var validY = <double>[];
    for (var item in widget.threadPageInfo.posts) {
      var kStr = item.postNumber;
      var k = GlobalObjectKey(kStr);
      if (k.currentContext != null) {
        validContext.add(k.currentContext!);
        var box = k.currentContext!.findRenderObject() as RenderBox?;
        if (box == null) { return; }
        validY.add(box.localToGlobal(Offset.zero).dy);
      }
    }
    var leadingEdge = scrollListBox.localToGlobal(Offset.zero).dy;
    for (var i=0; i<validY.length; i+=1) {
      if (validY[i] > leadingEdge) {
        Scrollable.ensureVisible(validContext[i]);
        break;
      }
    }
  }

  void showBottomAppBar() {
    if (!_ignorePrevNext) { return; }
    if (!_showBottomAppBar.value) {
      // setState(() { _showBottomAppBar = true; });
      _showBottomAppBar.value = true;
    }
  }

  void hideBottomAppBar() {
    if (!_ignorePrevNext) { return; }
    if (_showBottomAppBar.value) {
      // setState(() { _showBottomAppBar = false; });
      _showBottomAppBar.value = false;
    }
  }

  bool sameWithDelta(double a, double b, {double delta=0.1}) {
    if ((a-b).abs() < delta) {
      return true;
    }
    return false;
  }

  void listenToScrollRaw() {
    ScrollDirection scrollDirection = _scrollController.position.userScrollDirection;
    if (scrollDirection == ScrollDirection.forward) {
      showBottomAppBar();
    } else if (scrollDirection == ScrollDirection.reverse) {
      hideBottomAppBar();
    }
  }

  // void listenToScroll() {
  //   const double delta = 2.0; // MD3 height of bottomAppBar is 80.0
  //   var scrollListHeight = scrollKey.currentContext?.size?.height ?? 1.0;
  //   _initScrollHeight ??= scrollListHeight;
  //   var lastPosition = getLastItem();
  //   // debugPrint("height: $_initScrollHeight");
  //   if (_lastIndex==null) {
  //     _lastIndex = lastPosition.index;
  //     _lastTrailingEdge = lastPosition.itemTrailingEdge * scrollListHeight;
  //     if (lastPosition.index == widget.threadPageInfo.posts.length-1) {
  //       if (_initScrollHeight!-0.1 < _lastTrailingEdge! && _lastTrailingEdge! <= _initScrollHeight! + md3BottomAppBarHeight + 0.1) {
  //         itemPositionsListener.itemPositions.removeListener(listenToScroll);
  //       }
  //     }
  //     return;
  //   }
  //   int hideIt = 0;
  //   double newTrailingEdge = lastPosition.itemTrailingEdge * scrollListHeight;
  //   if (lastPosition.index > _lastIndex!) {
  //     hideIt = 1;
  //   } else if (lastPosition.index < _lastIndex!) {
  //     hideIt = -1;
  //   } else {
  //     if ((newTrailingEdge < _lastTrailingEdge! - delta)) {
  //       hideIt = 1;
  //     } else if ((newTrailingEdge > _lastTrailingEdge! + delta)) {
  //       hideIt = -1;
  //     }
  //   }
  //   // debugPrint("$hideIt $_showBottomAppBar $scrollListHeight $_lastTrailingEdge $newTrailingEdge $_initScrollHeight");
  //   if (sameWithDelta(newTrailingEdge, scrollListHeight) && sameWithDelta(newTrailingEdge, _lastTrailingEdge!+md3BottomAppBarHeight)) {
  //     hideIt = 0;
  //   }
  //   if (!_showBottomAppBar.value && (_initScrollHeight! - 0.1 < newTrailingEdge) && (newTrailingEdge <= _initScrollHeight!+md3BottomAppBarHeight+0.1)) {
  //     // MD3 bottom app bar height < 80，用80判断也没问题
  //     hideIt = 0;
  //   }
  //   if ((_initScrollHeight! < newTrailingEdge) && (newTrailingEdge <= _initScrollHeight!+md3BottomAppBarHeight+0.1)) {
  //     hideIt = 0;
  //   }
  //   _lastIndex = lastPosition.index;
  //   _lastTrailingEdge = newTrailingEdge;
  //   if (hideIt == 1) {
  //     hideBottomAppBar();
  //   } else if (hideIt == -1) {
  //     showBottomAppBar();
  //   }
  // }

  Widget _onepost(OnePostInfo item, {int? subIdx}) {
    var userName = item.authorInfo.userName;
    Set<String> seeNoHimHer = globalImmConfigInfo.getSeeNoThem();
    var hideIt = false;
    if (seeNoHimHer.contains(userName.toLowerCase())) {
      hideIt = true;
    }
    var kStr = item.postNumber;
    int? newSubIdx = subIdx;
    if (newSubIdx != null) {
      // if ((widget.page <= 1) && (newSubIdx >= 1)) { newSubIdx -= 1; }
      if (newSubIdx > 5) { newSubIdx = 5; }
    }
    return RepaintBoundary(
      child: OnePostComponent(onePostInfo: item, bid: widget.bid, refreshCallBack: widget.refreshCallBack,
        boardName: widget.threadPageInfo.board.text, threadid: widget.threadid, title: widget.threadPageInfo.title,
        subIdx: newSubIdx, hideIt: hideIt, key: GlobalObjectKey(kStr),
      ),
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
              if (!mounted) { return; }
              var sharedText = "";
              sharedText += "$v2Host/post-read.php?bid=${widget.threadPageInfo.boardid}&threadid=${widget.threadPageInfo.threadid} \n";
              sharedText += "${widget.threadPageInfo.title} - ${widget.threadPageInfo.board.text}";
              shareWithResultWrap(context, sharedText, subject: "分享帖子");
            },
            icon: const Icon(Icons.share),
          ),
          PopupMenuButton(
            // icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              if (value == null) { return; }
              if (value == "tiebaForm") {
                widget.toggleTiebaForm();
              } else if (value == "saveContent") {
                showInformDialog(context, "暂未实现", "rt");
              }
            },
            itemBuilder: (context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: "tiebaForm",
                  child: Row(
                    children: [
                      Icon(widget.tiebaForm ? Icons.change_circle : Icons.account_tree),
                      const SizedBox(width: 5,),
                      const Text("切换回复形式"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "saveContent",
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 5,),
                      Text("保存本页内容"),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onDoubleTap: () {
              // Scrollable.ensureVisible(itemKeys[0].currentContext!, duration: const Duration(milliseconds: 1500));
              gotoPreviousPostRaw(far: true);
            },
            onLongPress: () {
              gotoNextPostRaw(far: true);
            },
            child: Container(
              padding: const EdgeInsets.all(10.0),
              alignment: Alignment.centerLeft,
              // height: 20,
              child: Text(
                breakLongText(widget.threadPageInfo.title),
                style: _titleFont,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                overlayController.insert(context, initOffset: details.globalPosition);
              },
              onHorizontalDragUpdate: (details) {
                overlayController.update(details.globalPosition);
              },
              onHorizontalDragEnd: (details) {
                var direction = overlayController.direction;
                overlayController.remove();
                if (direction == 1) {
                  // 向左滑动
                  if (widget.page < widget.threadPageInfo.pageNum) {
                    widget.goPage(widget.page+1);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("已是最后一页"), duration: Duration(milliseconds: 600),),
                    );
                  }
                } else if (direction == -1) {
                  if (widget.page > 1) {
                    widget.goPage(widget.page-1);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("已是第一页"), duration: Duration(milliseconds: 600),),
                    );
                  }
                }
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                key: scrollKey,
                child: Column(
                  children: widget.threadPageInfo.posts.asMap().entries.map((elem) {
                    var index = elem.key;
                    if (widget.tiebaForm) {
                      var oriIdx = newOrder[index].oriIdx;
                      var subIdx = newOrder[index].subIdx;
                      return _onepost(widget.threadPageInfo.posts[oriIdx], subIdx: subIdx);
                    }
                    return _onepost(widget.threadPageInfo.posts[index]);
                  }).toList(),
                ),
              ),
              // child: ListView.builder(
              //   controller: _scrollController,
              //   key: scrollKey,
              //   itemCount: widget.threadPageInfo.posts.length,
              //   itemBuilder: (context, index) {
              //     if (widget.tiebaForm) {
              //       var oriIdx = newOrder[index].oriIdx;
              //       var subIdx = newOrder[index].subIdx;
              //       return _onepost(widget.threadPageInfo.posts[oriIdx], subIdx: subIdx > 5 ? 5 : subIdx);
              //     }
              //     return _onepost(widget.threadPageInfo.posts[index]);
              //   },
              // ),
              // child: ScrollablePositionedList.builder(
              //   key: scrollKey,
              //   itemCount: widget.threadPageInfo.posts.length,
              //   itemBuilder: (context, index) {
              //     if (widget.tiebaForm) {
              //       var oriIdx = newOrder[index].oriIdx;
              //       var subIdx = newOrder[index].subIdx;
              //       return _onepost(widget.threadPageInfo.posts[oriIdx], subIdx: subIdx > 5 ? 5 : subIdx);
              //     }
              //     return _onepost(widget.threadPageInfo.posts[index]);
              //   },
              //   itemScrollController: itemScrollController,
              //   itemPositionsListener: itemPositionsListener,
              // ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: _showBottomAppBar,
        child: BottomAppBar(
          shape: null,
          // color: Colors.blue,
          // height: _showBottomAppBar ? null : 0.0,
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
              LongPressIconButton(
                primaryColor: bdwmPrimaryColor,
                iconData: Icons.arrow_back,
                enabled: widget.page > 1,
                disabledColor: Colors.grey,
                onTap: () {
                  widget.goPage(widget.page-1);
                },
                onLongPress: () {
                  widget.goPage(1);
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
              LongPressIconButton(
                primaryColor: bdwmPrimaryColor,
                iconData: Icons.arrow_forward,
                enabled: widget.page < widget.threadPageInfo.pageNum,
                disabledColor: Colors.grey,
                onTap: () {
                  widget.goPage(widget.page+1);
                },
                onLongPress: () {
                  widget.goPage(widget.threadPageInfo.pageNum);
                },
              ),
            ],
          ),
        ),
        builder: (context, value, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _showBottomAppBar.value ? (globalConfigInfo.useMD3 ? md3BottomAppBarHeight : globalConfigInfo.autoHideBottomBar ? 40 : null) : 0,
            child: child,
          );
        },
      ),
      floatingActionButton: !widget.showFAB ? null : MyFloatingActionButtonMenu(
        showFAB: widget.showFAB,
        gotoNextPost: ({bool far=false}) {
          gotoNextPostRaw(far: far);
        },
        gotoPreviousPost: ({bool far=false}) {
          gotoPreviousPostRaw(far: far);
        },
        toggleIgnore: (bool newValue) {
          _ignorePrevNext = newValue;
        },
      ),
    );
  }
}

class ThreadPage extends StatefulWidget {
  final String bid;
  final String threadid;
  final String page;
  final String? boardName;
  final bool? needToBoard;
  final String? postid;
  const ThreadPage({Key? key, required this.bid, required this.threadid, this.boardName, required this.page, this.needToBoard, this.postid}) : super(key: key);

  @override
  State <ThreadPage> createState() =>  ThreadPageState();
}

class  ThreadPageState extends State <ThreadPage> {
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
    // resetInitScrollHeight();
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

  Future<void> updateDataAsync() async {
    refresh();
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
            body: RefreshIndicator(
              onRefresh: updateDataAsync,
              child: genScrollableWidgetForPullRefresh(
                Center(
                  child: Text(threadPageInfo.errorMessage!),
                ),
              ),
            ),
          );
        }
        if (threadPageInfo.page != page) {
          page = threadPageInfo.page;
        }
        // String userName = "未知";
        String userName = "未知+$needReloadID"; // 为了 changedependencies 能刷新
        if (threadPageInfo.posts.isNotEmpty) {
          userName = threadPageInfo.posts.first.authorInfo.userName;
        }
        addHistory(link: threadLink, title: threadPageInfo.title, userName: userName, boardName: threadPageInfo.board.text);
        return ThreadDetailPage(
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
    boardName = (settingsMap['boardName'] as String?) ?? boardName;
    page = settingsMap['page'] as String;
    postid = settingsMap['postid'] as String?;
    needToBoard = settingsMap['needToBoard'] as bool?;
  } else {
    return null;
  }
  return ThreadPage(boardName: boardName, bid: bid, threadid: threadid, page: page, needToBoard: needToBoard, postid: postid);
}

void naviGotoThread(context, String bid, String threadid, String page, String boardName, {bool? needToBoard, String? postid}) {
  nv2Push(context, '/thread', arguments: {
    'bid': bid,
    'threadid': threadid,
    'page': page,
    'boardName': boardName,
    'needToBoard': needToBoard,
    'postid': postid,
  });
}

Map<String, Object?>? naviGotoThreadByLink(BuildContext? context, String link, String boardName, {bool? needToBoard, String? pageDefault, bool replaceIt=false, bool getArguments=false}) {
  var bid = getQueryValueImproved(link, 'bid');
  if (bid == null) { return null; }
  var page = pageDefault ?? "1";
  String? postid;
  if (pageDefault != null) {
    postid = getQueryValueImproved(link, 'postid');
  } else {
    postid = getQueryValueImproved(link, 'postid');
    page = getQueryValueImproved(link, 'page') ?? page;
  }
  var threadid = getQueryValueImproved(link, 'threadid');
  if (threadid == null) { return null; }
  Map<String, Object?> arguments = {
    'bid': bid,
    'threadid': threadid,
    'page': page,
    'boardName': boardName,
    'needToBoard': needToBoard,
    'postid': postid,
  };
  if (getArguments == true) {
    return arguments;
  }
  if (context==null) { return null; }
  var nv2Do = replaceIt ? nv2Replace : nv2Push;
  nv2Do(context, '/thread', arguments: arguments);
  return null;
}
