import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';

import './globalvars.dart';
import './pages/home.dart';
import './pages/board.dart';
import './pages/login.dart';
import './pages/user.dart';
import './pages/read_thread.dart';
import './services.dart';

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
  Timer? timer;
  NotifyMessage unreadMessage = NotifyMessage();
  NotifyMessageInfo unreadMessageInfo = NotifyMessageInfo.empty();

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      unreadMessage.updateValue((NotifyMessageInfo info) {
        if (unreadMessageInfo.count != info.count) {
          setState(() {
            unreadMessageInfo = info;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("** main rebuild");
    return MaterialApp(
      title: 'OBViewer',
      theme: ThemeData(
        // #e97c62
        // colorScheme: const ColorScheme.light().copyWith(primary: Colors.orangeAccent),
        colorScheme: const ColorScheme.light().copyWith(primary: Color(0xffe97c62)),
      ),
      home: HomeApp(unreadMessageInfo: unreadMessageInfo,),
      // home: ThreadApp(bid: "33", threadid: "18262167", page: "2", boardName: "历史",),
      // initialRoute: "/home",
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case "/board":
            String? boardName = settings.arguments as String?;
            builder = (BuildContext context) => BoardApp(boardName: boardName,);
            break;
          case "/thread":
            var res = gotoThread(settings.arguments);
            if (res == null) {
              return null;
            }
            builder = res;
            break;
          case "/login":
            bool needBack = false;
            if (settings.arguments != null) {
              needBack = (settings.arguments as Map)['needBack'] ?? false;
            }
            builder = (BuildContext context) => LoginApp(needBack: needBack,);
            break;
          case "/me":
            if (globalUInfo.login) {
              builder = (BuildContext context) => UserApp(uid: globalUInfo.uid);
            } else {
              builder = (BuildContext context) => LoginApp();
            }
            break;
          case "/user":
            String userID = settings.arguments as String? ?? "15265";
            builder = (BuildContext context) => UserApp(uid: userID, needBack: true,);
            break;
          case "/home":
          default:
            builder = (BuildContext context) => HomeApp(unreadMessageInfo: unreadMessageInfo,);
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}