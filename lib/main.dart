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
// import './pages/detail_image.dart';
import './services.dart';
import './bdwm/mail.dart';

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
  NotifyMessage unreadMessage = NotifyMessage();
  NotifyMail unreadMail = NotifyMail();
  // NotifyMessageInfo unreadMessageInfo = NotifyMessageInfo.empty();
  ValueNotifier<int> messageCount = ValueNotifier<int>(0);
  ValueNotifier<int> mailCount = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    timerMessage = Timer.periodic(const Duration(seconds: 15), (timer) {
      unreadMessage.updateValue((NotifyMessageInfo info) {
        if (info.count != messageCount.value) {
          messageCount.value = info.count;
        }
      });
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
          case "/login":
            bool needBack = false;
            if (settings.arguments != null) {
              needBack = (settings.arguments as Map)['needBack'] ?? false;
            }
            builder = (BuildContext context) => LoginApp(needBack: needBack,);
            break;
          case "/about":
            builder = (BuildContext context) => const AboutApp();
            break;
          case "/me":
            if (globalUInfo.login) {
              builder = (BuildContext context) => UserApp(uid: globalUInfo.uid);
            } else {
              builder = (BuildContext context) => const LoginApp();
            }
            break;
          case "/user":
            String userID = settings.arguments as String? ?? "15265";
            builder = (BuildContext context) => UserApp(uid: userID, needBack: true,);
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