import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';

import './pages/home.dart';
import './pages/board.dart';
import './pages/login.dart';
import './pages/user.dart';
import './pages/about.dart';
import './pages/read_thread.dart';
import './pages/post_new.dart';
import './pages/collection_new.dart' show CollectionNewApp;
import './pages/collection.dart';
import './pages/block.dart';
import './pages/zone.dart';
import './pages/favorite.dart';
import './pages/search.dart';
import './pages/search_result.dart';
import './pages/message.dart';
import './pages/friends.dart';
import './pages/mail.dart';
import './pages/mail_new.dart';
import './pages/funfunfun.dart';
import './pages/see_no_them.dart';
import './pages/friends_posts.dart';
import './pages/settings.dart';
import './pages/detail_image.dart';
import './pages/recent_thread.dart';
import './pages/marked_thread.dart';
import './pages/user_stat.dart';
import './pages/board_note.dart';
import './pages/read_post.dart';
import './pages/favorite_collection.dart';
import './pages/modify_profile.dart';
import './html_parser/modify_profile_parser.dart' show SelfProfileInfo;
import './views/search.dart' show PostSearchSettings;
import './services.dart';
import './globalvars.dart';
import './views/utils.dart' show showConfirmDialog;

class MyRouteConfig {
  static int configIdx = 0;

  String name = "";
  Object? arguments;
  bool delete = false;
  int localIdx = 0;

  void incIdx() {
    localIdx = configIdx;
    configIdx += 1;
  }
  MyRouteConfig.empty() {
    incIdx();
  }
  MyRouteConfig({
    required this.name,
    this.arguments,
  }) {
    incIdx();
  }
  MyRouteConfig.home() {
    name = "/home";
    arguments = null;
    incIdx();
  }

  Map toJson() {
    return {
      'name': name,
      'arguments': jsonEncode(arguments),
    };
  }
}

// https://github.com/flutter/flutter/issues/72487
class MainPageBuilder {
  ValueNotifier<int>? messageCount;
  ValueNotifier<int>? mailCount;
  MessageBriefNotifier? messageBrief;

  MainPageBuilder.empty();
  MainPageBuilder({
    this.messageBrief,
    this.mailCount,
    this.messageCount,
  });

  Widget? build(MyRouteConfig settings) {
    switch (settings.name) {
      case "/board":
        String? boardName;
        String? bid;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          bid = settingsMap['bid'] as String?;
          boardName = settingsMap['boardName'] as String?;
        } else {
          return null;
        }
        return BoardApp(boardName: boardName ?? "版面", bid: bid ?? "");
      case "/boardSingle":
        String? boardName;
        String? bid;
        String? stype;
        String smode;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          bid = settingsMap['bid'] as String?;
          boardName = settingsMap['boardName'] as String?;
          stype = settingsMap['stype'] as String?;
          smode = settingsMap['smode'] as String;
        } else {
          return null;
        }
        return BoardSingleApp(boardName: boardName ?? "版面", bid: bid ?? "", stype: stype, smode: smode);
      case "/boardNote":
        String? boardName;
        String? bid;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          bid = settingsMap['bid'] as String?;
          boardName = settingsMap['boardName'] as String?;
        } else {
          return null;
        }
        return BoardNoteApp(boardName: boardName ?? "版面", bid: bid ?? "");
      case "/thread":
        var res = gotoThreadPage(settings.arguments);
        if (res == null) {
          return null;
        }
        return res;
      case "/singlePost":
        String? boardName;
        String bid;
        String postid;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          bid = settingsMap['bid'] as String;
          postid = settingsMap['postid'] as String;
          boardName = settingsMap['boardName'] as String?;
        } else {
          return null;
        }
        return SinglePostApp(bid: bid, postid: postid, boardName: boardName,);
      case "/post":
        String? boardName;
        String? bid;
        String? postid;
        String? parentid;
        String? nickName;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          bid = settingsMap['bid'] as String?;
          boardName = settingsMap['boardName'] as String?;
          postid = settingsMap['postid'] as String?;
          parentid = settingsMap['parentid'] as String?;
          nickName = settingsMap['nickName'] as String?;
        } else {
          return null;
        }
        return PostNewApp(boardName: boardName ?? "版面", bid: bid ?? "", postid: postid, parentid: parentid, nickName: nickName);
      case "/zone":
        bool needBack = false;
        if (settings.arguments != null) {
          needBack = (settings.arguments as Map)['needBack'] ?? false;
        }
        return ZoneApp(needBack: needBack);
      case "/favorite":
        return const FavoriteApp();
      case "/block":
        String? bid;
        String? title;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          bid = settingsMap['bid'] as String?;
          title = settingsMap['title'] as String?;
        } else {
          return null;
        }
        return BlockApp(bid: bid!, title: title!,);
      case "/collection":
        String? link;
        String? title;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          link = settingsMap['link'] as String?;
          title = settingsMap['title'] as String?;
        } else {
          return null;
        }
        return CollectionApp(link: link!, title: title!,);
      case "/collectionArticle":
        String? link;
        String? title;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          link = settingsMap['link'] as String?;
          title = settingsMap['title'] as String?;
        } else {
          return null;
        }
        return CollectionArticleApp(link: link!, title: title!,);
      case "/collectionNew":
        String mode;
        String baseOrPath;
        String title;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          mode = settingsMap['mode'] as String;
          baseOrPath = settingsMap['baseOrPath'] as String;
          title = settingsMap['title'] as String;
        } else {
          return null;
        }
        return CollectionNewApp(mode: mode, baseOrPath: baseOrPath, title: title,);
      case "/login":
        bool needBack = false;
        if (settings.arguments != null) {
          needBack = (settings.arguments as Map)['needBack'] ?? false;
        }
        return LoginApp(needBack: needBack);
      case "/about":
        return const AboutApp();
      case "/mail":
        return const MailListApp();
      case "/mailDetail":
        String? postid;
        String? mailType;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          postid = settingsMap['postid'] as String?;
          mailType = settingsMap['type'] as String?;
        } else {
          return null;
        }
        return MailDetailApp(postid: postid!, type: mailType!,);
      case "/mailNew":
        String? bid;
        String? parentid;
        String? receiver;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          bid = settingsMap['bid'] as String?;
          parentid = settingsMap['parentid'] as String?;
          receiver = settingsMap['receiver'] as String?;
        }
        return MailNewApp(bid: bid, parentid: parentid, receiver: receiver);
      case "/friend":
        return const FriendsApp();
      case "/favoriteCollection":
        return const FavoriteCollectionApp();
      case "/search":
        return const SearchApp();
      case "/simpleSearchResult":
        String? mode;
        String? keyWord;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          mode = settingsMap['mode'] as String?;
          keyWord = settingsMap['keyWord'] as String?;
        } else {
          return null;
        }
        return SimpleSearchResultApp(mode: mode!, keyWord: keyWord!,);
      case "/complexSearchResult":
        PostSearchSettings? pss;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          pss = settingsMap['settings'] as PostSearchSettings?;
        } else {
          return null;
        }
        return ComplexSearchResultApp(pss: pss!);
      case "/me":
        if (globalUInfo.login) {
          return UserApp(uid: globalUInfo.uid);
        }
        return const LoginApp();
      case "/user":
        String userID = settings.arguments as String? ?? "15265";
        return UserApp(uid: userID, needBack: true,);
      case "/message":
        if (messageBrief == null) { return null; }
        return MessagelistApp(brief: messageBrief!);
      case "/messagePerson":
        String userName = settings.arguments as String? ?? "deliver";
        return MessagePersonApp(userName: userName);
      case "/funfunfun":
        return const FunFunFunApp();
      case "/recentThread":
        return const RecentThreadApp();
      case "/markedThread":
        return const MarkedThreadApp();
      case "/seeNoThem":
        return const SeeNoThemApp();
      case "/friendsPosts":
        return const FriendsPostsApp();
      case "/settings":
        return const SettingsApp();
      case "/userStat":
        return const UserStatApp();
      case "/modifyProfile":
        SelfProfileInfo selfProfileInfo = SelfProfileInfo.empty();
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          selfProfileInfo = settingsMap['selfProfileInfo'] as SelfProfileInfo;
        }
        return ModifyProfileApp(selfProfileInfo: selfProfileInfo,);
      case "/detailImage":
        String? imgLink;
        String? imgName;
        Uint8List? imgData;
        String? imgDataStr;
        List<String>? imgLinks;
        List<String>? imgNames;
        int? curIdx;
        if (settings.arguments != null) {
          var settingsMap = settings.arguments as Map;
          imgLink = settingsMap['link'] as String?;
          imgName = settingsMap['name'] as String?;
          imgData = settingsMap['imgData'] as Uint8List?;
          imgDataStr = settingsMap['imgDataStr'] as String?;
          imgLinks = settingsMap['imgLinks'] as List<String>?;
          imgNames = settingsMap['imgNames'] as List<String>?;
          curIdx = settingsMap['curIdx'] as int?;
        } else {
          return null;
        }
        return DetailImage(
          imgLink: imgLink ?? "", imgName: imgName, imgData: imgData,
          imgLinks: imgLinks, imgNames: imgNames, curIdx: curIdx, imgDataStr: imgDataStr,
        );
      case "/home":
        if (messageCount == null || mailCount == null) { return null; }
        return HomeApp(messageCount: messageCount!, mailCount: mailCount!,);
      default:
        return Scaffold(
          appBar: AppBar(
            title: const Text("未知页面"),
          ),
          body: const Center(
            child: Text('未知页面')
          ),
        );
    }
  }
}

MainRouterDelegate? mainRouterDelegate;

void nv2RawPush(String name, {Object? arguments}) {
  mainRouterDelegate?.push(name, arguments: arguments);
}

void nv2Push(BuildContext context, String name, {Object? arguments}) {
  var delegate = Router.of(context).routerDelegate as MainRouterDelegate;
  delegate.push(name, arguments: arguments);
}

void nv2PushAndRemoveAll(BuildContext context, String name, {Object? arguments}) {
  var delegate = Router.of(context).routerDelegate as MainRouterDelegate;
  delegate.pushAndRemoveAll(name, arguments: arguments);
}

void nv2Replace(BuildContext context, String name, {Object? arguments}) {
  var delegate = Router.of(context).routerDelegate as MainRouterDelegate;
  delegate.replace(name, arguments: arguments);
}

void nv2Pop(BuildContext context) {
  var delegate = Router.of(context).routerDelegate as MainRouterDelegate;
  delegate.pop();
}

class MyPage extends Page {
  final Widget child;
  const MyPage({
    required this.child,
    super.key,
  });
  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder:(context) {
        return child;
      },
    );
  }
}

int _reload = -1;
int getForceID() {
  return _reload;
}

void forceRefresh(int a) {
  _reload = a;
}

class ForceRerefreshWidget extends InheritedWidget {
  const ForceRerefreshWidget({
    Key? key,
    required this.reload,
    required Widget child,
  }) : super(key: key, child: child);

  final int reload;

  static ForceRerefreshWidget? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ForceRerefreshWidget>();
  }

  @override
  bool updateShouldNotify(ForceRerefreshWidget oldWidget) {
    return (oldWidget.reload != reload) && (reload != -1);
  }
}

class MainRouterDelegate extends RouterDelegate<MyRouteConfig>
  with ChangeNotifier, PopNavigatorRouterDelegateMixin<MyRouteConfig> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  List<MyRouteConfig> mainRoutes = [];
  late final MainPageBuilder mainPageBuilder;
  bool onWaitExit = false;

  MainRouterDelegate() {
    mainPageBuilder = MainPageBuilder.empty();
  }
  MainRouterDelegate.empty() {
    mainPageBuilder = MainPageBuilder.empty();
  }
  MainRouterDelegate.init({required ValueNotifier<int> messageCount, required ValueNotifier<int> mailCount, required MessageBriefNotifier messageBrief}) {
    mainPageBuilder = MainPageBuilder(messageBrief: messageBrief, messageCount: messageCount, mailCount: mailCount);
  }

  @override
  Widget build(BuildContext context) {
    List<MyPage> pages = [];
    if (mainRoutes.isEmpty) {
      mainRoutes.add(MyRouteConfig.home());
    }
    int? maxPageNum = int.tryParse(globalConfigInfo.getMaxPageNum());
    if (maxPageNum!=null && (maxPageNum <= 0 || maxPageNum >= mainRoutes.length)) { maxPageNum = null; }
    var toIter = mainRoutes.reversed;
    int sNum = 0;
    for (var s in toIter) {
      var w = mainPageBuilder.build(s);
      if (w!=null) {
        pages.add(MyPage(child: w, key: ValueKey("${s.name}+${s.localIdx}")));
        sNum += 1;
        if (maxPageNum != null && sNum >= maxPageNum) {
          break;
        }
      } else {
        s.delete = true;
      }
    }
    pages = pages.reversed.toList(growable: false);
    mainRoutes.removeWhere((element) => element.delete==true);
    debugPrint("route and page: ${mainRoutes.length} ${pages.length}");
    return ForceRerefreshWidget(
      reload: _reload,
      child: Navigator(
        key: navigatorKey,
        pages: pages,
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          pop();
          return true;
        }
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(MyRouteConfig configuration) {
    if (mainRoutes.isEmpty) { return Future.value(null); }
    // for browser, so forget it now
    notifyListeners();
    return Future.value(null);
  }

  @override
  Future<bool> popRoute() async {
    if (navigatorKey.currentContext == null) {
      return Future.value(false);
    }
    var navigatorCanPop = Navigator.of(navigatorKey.currentContext!).canPop();
    if (navigatorCanPop && (!onWaitExit)) {
      // pop any dialog except exit dialog
      Navigator.of(navigatorKey.currentContext!).pop();
      return true;
    }
    if (mainRoutes.length > 1) {
      pop();
      return Future.value(true);
    }
    if (onWaitExit) { return false; }
    onWaitExit = true;
    var value = await showConfirmDialog(navigatorKey.currentContext!, "退出应用", "rt");
    if (value == null || value != "yes") {
      onWaitExit = false;
      return true;
    }
    return false;
  }

  void tryPop() {
    if (mainRoutes.isNotEmpty) {
      pop();
    }
  }
  void pop() {
    mainRoutes.removeLast();
    notifyListeners();
  }
  void pushAndRemoveAll(String name, {Object? arguments}) {
    mainRoutes.clear();
    mainRoutes.add(MyRouteConfig(name: name, arguments: arguments));
    notifyListeners();
  }
  void push(String name, {Object? arguments}) {
    mainRoutes.add(MyRouteConfig(name: name, arguments: arguments));
    notifyListeners();
  }
  void replace(String name, {Object? arguments}) {
    if (mainRoutes.isNotEmpty) {
      mainRoutes.removeLast();
    }
    mainRoutes.add(MyRouteConfig(name: name, arguments: arguments));
    notifyListeners();
  }
}

// for browser, so forget it now
class MainRouteInformationParser extends RouteInformationParser<MyRouteConfig> {
  @override
  Future<MyRouteConfig> parseRouteInformation(
      RouteInformation routeInformation) async {
    return Future.value(MyRouteConfig.home());
  }

  @override
  RouteInformation restoreRouteInformation(MyRouteConfig configuration) {
    return RouteInformation(location: configuration.name);
  }
}
