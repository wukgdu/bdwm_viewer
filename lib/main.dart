import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/rendering.dart';

import './router.dart';
import './globalvars.dart';
import './views/constants.dart' show bdwmPrimaryColor, bdwmSurfaceColor;
import './services.dart';
import './services_instance.dart';
import './bdwm/mail.dart';
import './utils.dart';
import './check_update.dart' show checkUpdateByTime;

void main() async {
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;
  await globalUInfo.init();
  await globalContactInfo.init();
  await globalConfigInfo.init();
  checkUpdateByTime();
  await unreadMessage.initWorker();
  await unreadMail.initWorker();
  runApp(const MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Timer? timerMessage;
  Timer? timerMail;
  ValueNotifier<int> messageCount = ValueNotifier<int>(0);
  ValueNotifier<int> mailCount = ValueNotifier<int>(0);
  MessageBriefNotifier messageBrief = MessageBriefNotifier([]);
  late final MainRouterDelegate mainRouterDelegate;

  void updateUnreadMessageData() {
    unreadMessage.updateValue((NotifyMessageInfo info) {
      if (info.count != messageCount.value) {
        messageCount.value = info.count;
      }
      messageBrief.newArray(info);
    });
  }

  void updateUnreadMailData() {
    unreadMail.updateValue((UnreadMailInfo info) {
      if (info.count != mailCount.value) {
        mailCount.value = info.count;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    mainRouterDelegate = MainRouterDelegate.init(messageCount: messageCount, mailCount: mailCount, messageBrief: messageBrief,);

    updateUnreadMessageData();
    updateUnreadMailData();
    timerMessage = Timer.periodic(const Duration(seconds: 15), (timer) {
      updateUnreadMessageData();
      timerMessage = timer;
    });
    timerMail = Timer.periodic(const Duration(seconds: 15), (timer) {
      updateUnreadMailData();
      timerMail = timer;
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
    unreadMail.disposeWorker();
    unreadMessage.disposeWorker();
    clearAllExtendedImageCache(really: true);
    debugPrint("main dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("** main rebuild");
    return MaterialApp.router(
      title: 'OBViewer',
      theme: ThemeData(
        // #e97c62
        colorScheme: const ColorScheme.light().copyWith(primary: bdwmSurfaceColor),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark().copyWith(primary: bdwmPrimaryColor, surface: Colors.grey[800]),
        // brightness: Brightness.dark,
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      routerDelegate: mainRouterDelegate,
      // backButtonDispatcher: RootBackButtonDispatcher(),
    );
  }
}
