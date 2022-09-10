import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';

import './globalvars.dart';
import './pages/home.dart';
import './pages/board.dart';
import './pages/login.dart';
import './pages/user.dart';
import './pages/about.dart';
import './pages/read_thread.dart';
import './pages/post_new.dart';
import './pages/collection.dart';
import './pages/block.dart';
import './pages/zone.dart';
import './pages/favorite.dart';
import './pages/search.dart';
import './pages/search_result.dart';
import './pages/message.dart';
import './pages/friends.dart';
import './pages/mail.dart';
import './views/search.dart' show PostSearchSettings;
// import './pages/detail_image.dart';
import './services.dart';
import './bdwm/mail.dart';
import './utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;
  globalUInfo.init().then((res) {
    runApp(const MainPage());
  });
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Timer? timerMessage;
  Timer? timerMail;
  final NotifyMessage unreadMessage = NotifyMessage();
  final NotifyMail unreadMail = NotifyMail();
  // NotifyMessageInfo unreadMessageInfo = NotifyMessageInfo.empty();
  ValueNotifier<int> messageCount = ValueNotifier<int>(0);
  ValueNotifier<int> mailCount = ValueNotifier<int>(0);
  MessageBriefNotifier messageBrief = MessageBriefNotifier([]);

  @override
  void initState() {
    super.initState();

    unreadMessage.updateValue((NotifyMessageInfo info) {
      if (info.count != messageCount.value) {
        messageCount.value = info.count;
      }
      messageBrief.newArray(info);
    });
    timerMessage = Timer.periodic(const Duration(seconds: 15), (timer) {
      unreadMessage.updateValue((NotifyMessageInfo info) {
        if (info.count != messageCount.value) {
          messageCount.value = info.count;
        }
        messageBrief.newArray(info);
      });
    });

    unreadMail.updateValue((UnreadMailInfo info) {
      if (info.count != mailCount.value) {
        mailCount.value = info.count;
      }
    });
    timerMail = Timer.periodic(const Duration(seconds: 15), (timer) {
      unreadMail.updateValue((UnreadMailInfo info) {
        if (info.count != mailCount.value) {
          mailCount.value = info.count;
        }
      });
    });
  }

  @override
  void dispose() {
    if (timerMessage != null) {
      timerMessage!.cancel();
    }
    if (timerMail != null) {
      timerMail!.cancel();
    }
    messageCount.dispose();
    mailCount.dispose();
    messageBrief.dispose();
    clearAllExtendedImageCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("** main rebuild");
    return MaterialApp(
      title: 'OBViewer',
      theme: ThemeData(
        // #e97c62
        // colorScheme: const ColorScheme.light().copyWith(primary: Colors.orangeAccent),
        colorScheme: const ColorScheme.light().copyWith(primary: const Color(0xffe97c62)),
      ),
      home: HomeApp(messageCount: messageCount, mailCount: mailCount,),
      // home: const ThreadApp(bid: "338", threadid: "18367551", page: "a", boardName: "ID文化", postid: "26066045",),
      // home: const SimpleSearchResultApp(mode: "user", keyWord: "onepiecexx",),
      // home: const ZoneApp(),
      // home: const BlockApp(bid: "678", title: "休闲娱乐",),
      // home: CollectionArticleApp(link: "", title: "测试",),
      // home: const PostNewApp(boardName: "测试", bid: "7"),
      // home: BoardApp(bid: "103", boardName: "未名湖",),
      // home: const DetailImage(imgLink: "https://bbs.pku.edu.cn/v2/uploads/index_MKoueo.jpg", imgName: "招新.jpg",),
      // home: ThreadApp(bid: "33", threadid: "18262167", page: "2", boardName: "历史",),
      // initialRoute: "/home",
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case "/board":
            String? boardName;
            String? bid;
            if (settings.arguments != null) {
              var settingsMap = settings.arguments as Map;
              bid = settingsMap['bid'] as String;
              boardName = settingsMap['boardName'] as String;
            } else {
              return null;
            }
            builder = (BuildContext context) => BoardApp(boardName: boardName ?? "版面", bid: bid ?? "");
            break;
          case "/thread":
            var res = gotoThread(settings.arguments);
            if (res == null) {
              return null;
            }
            builder = res;
            break;
          case "/post":
            String? boardName;
            String? bid;
            String? postid;
            String? parentid;
            if (settings.arguments != null) {
              var settingsMap = settings.arguments as Map;
              bid = settingsMap['bid'] as String;
              boardName = settingsMap['boardName'] as String;
              postid = settingsMap['postid'] as String?;
              parentid = settingsMap['parentid'] as String?;
            } else {
              return null;
            }
            builder = (BuildContext context) => PostNewApp(boardName: boardName ?? "版面", bid: bid ?? "", postid: postid, parentid: parentid);
            break;
          case "/zone":
            builder = (BuildContext context) => const ZoneApp();
            break;
          case "/favorite":
            builder = (BuildContext context) => const FavoriteApp();
            break;
          case "/block":
            String? bid;
            String? title;
            if (settings.arguments != null) {
              var settingsMap = settings.arguments as Map;
              bid = settingsMap['bid'] as String;
              title = settingsMap['title'] as String;
            } else {
              return null;
            }
            builder = (BuildContext context) => BlockApp(bid: bid!, title: title!,);
            break;
          case "/collection":
            String? link;
            String? title;
            if (settings.arguments != null) {
              var settingsMap = settings.arguments as Map;
              link = settingsMap['link'] as String;
              title = settingsMap['title'] as String;
            } else {
              return null;
            }
            builder = (BuildContext context) => CollectionApp(link: link!, title: title!,);
            break;
          case "/collectionArticle":
            String? link;
            String? title;
            if (settings.arguments != null) {
              var settingsMap = settings.arguments as Map;
              link = settingsMap['link'] as String;
              title = settingsMap['title'] as String;
            } else {
              return null;
            }
            builder = (BuildContext context) => CollectionArticleApp(link: link!, title: title!,);
            break;
          case "/login":
            bool needBack = false;
            if (settings.arguments != null) {
              needBack = (settings.arguments as Map)['needBack'] ?? false;
            }
            builder = (BuildContext context) => LoginApp(needBack: needBack, nMail: unreadMail, nMessage: unreadMessage,);
            break;
          case "/about":
            builder = (BuildContext context) => const AboutApp();
            break;
          case "/mail":
            builder = (BuildContext context) => const MailListApp();
            break;
          case "/mailDetail":
            String? postid;
            if (settings.arguments != null) {
              var settingsMap = settings.arguments as Map;
              postid = settingsMap['postid'] as String;
            } else {
              return null;
            }
            builder = (BuildContext context) => MailDetailApp(postid: postid!,);
            break;
          case "/friend":
            builder = (BuildContext context) => const FriendsApp();
            break;
          case "/search":
            builder = (BuildContext context) => const SearchApp();
            break;
          case "/simpleSearchResult":
            String? mode;
            String? keyWord;
            if (settings.arguments != null) {
              var settingsMap = settings.arguments as Map;
              mode = settingsMap['mode'] as String;
              keyWord = settingsMap['keyWord'] as String;
            } else {
              return null;
            }
            builder = (BuildContext context) => SimpleSearchResultApp(mode: mode!, keyWord: keyWord!,);
            break;
          case "/complexSearchResult":
            PostSearchSettings? pss;
            if (settings.arguments != null) {
              var settingsMap = settings.arguments as Map;
              pss = settingsMap['settings'] as PostSearchSettings;
            } else {
              return null;
            }
            builder = (BuildContext context) => ComplexSearchResultApp(pss: pss!);
            break;
          case "/me":
            if (globalUInfo.login) {
              builder = (BuildContext context) => UserApp(uid: globalUInfo.uid);
            } else {
              builder = (BuildContext context) => LoginApp(nMail: unreadMail, nMessage: unreadMessage,);
            }
            break;
          case "/user":
            String userID = settings.arguments as String? ?? "15265";
            builder = (BuildContext context) => UserApp(uid: userID, needBack: true,);
            break;
          case "/message":
            builder = (BuildContext context) => MessagelistApp(brief: messageBrief,);
            break;
          case "/messagePerson":
            String userName = settings.arguments as String? ?? "deliver";
            builder = (BuildContext context) => MessagePersonApp(userName: userName, notifier: unreadMessage);
            break;
          case "/home":
          default:
            builder = (BuildContext context) => HomeApp(messageCount: messageCount, mailCount: mailCount,);
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}