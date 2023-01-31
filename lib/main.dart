import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_fonts/dynamic_fonts.dart';
import 'package:quick_actions/quick_actions.dart';
// import 'package:flutter/rendering.dart';

import './router.dart';
import './globalvars.dart';
import './views/constants.dart' show bdwmPrimaryColor;
import './services.dart';
import './services_instance.dart';
import './bdwm/mail.dart';
import './utils.dart';
import './check_update.dart' show checkUpdateByTime;

void main() async {
  if (isAndroid()) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;
  await globalUInfo.init();
  await globalContactInfo.init();
  await globalConfigInfo.init();
  await globalNotConfigInfo.init();
  await globalThreadHistory.init();
  await globalMarkedThread.init();
  initPrimaryColor();
  checkUpdateByTime();
  await unreadMessage.initWorker();
  await unreadMail.initWorker();
  registerDynamicFont();
  runApp(const MainPage());
}

void initPrimaryColor() {
  var colorValue = int.tryParse(globalConfigInfo.getPrimaryColorString());
  if (colorValue != null) {
    bdwmPrimaryColor = Color(colorValue);
  }
}
class NotoSansMonoCJKscFile extends DynamicFontsFile {
  NotoSansMonoCJKscFile(this.variant,  expectedFileHash, int expectedLength)
      : super(expectedFileHash, expectedLength);

  final DynamicFontsVariant variant;

  @override
  String get url => 'https://bbs.pku.edu.cn/attach/ec/04/ec04cc376b34887c/NotoSansMonoCJKsc-Regular.otf';
}

void registerDynamicFont() {
  DynamicFonts.register('NotoSansMonoCJKsc', [
    NotoSansMonoCJKscFile(
      const DynamicFontsVariant(fontWeight: FontWeight.w400, fontStyle: FontStyle.normal),
      "ec04cc376b34887cedbdf84074e2e226ed2761eeabdcb9173fc1dd7bfd153ef7",
      16393784,
    ),
  ].fold<Map<DynamicFontsVariant, DynamicFontsFile>>({}, (previousValue, element) => previousValue..[element.variant]=element,));
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => MainPageState();

  static MainPageState? maybeOf(BuildContext context) {
    final mainPageState = context.findAncestorStateOfType<MainPageState>();
    return mainPageState;
  }
}

class MainPageState extends State<MainPage> {
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

    if (isAndroid()) {
      const QuickActions quickActions = QuickActions();
      quickActions.initialize((String shortcutType) {
        switch (shortcutType) {
          // 没用的case，保留switch为了以后可能的修改
          case '/me':
          case '/favorite':
            mainRouterDelegate.replace(shortcutType);
            break;
          default:
            mainRouterDelegate.push(shortcutType);
        }
      });
      quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: '/message', localizedTitle: '消息', icon: 'ic_wei'),
        const ShortcutItem(type: '/mail', localizedTitle: '站内信', icon: 'ic_wei'),
        const ShortcutItem(type: '/search', localizedTitle: '搜索', icon: 'ic_wei'),
        const ShortcutItem(type: '/recentThread', localizedTitle: '最近浏览', icon: 'ic_wei'),
        const ShortcutItem(type: '/markedThread', localizedTitle: '帖子收藏', icon: 'ic_wei'),
      ]);
    }
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

  void refresh() {
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("** main rebuild");
    return MaterialApp.router(
      title: 'OBViewer',
      theme: ThemeData(
        // colorScheme: const ColorScheme.light().copyWith(primary: bdwmPrimaryColor),
        // colorScheme: ColorScheme.fromSeed(seedColor: bdwmPrimaryColor),
        colorScheme: ColorScheme(brightness: Brightness.light,
          primary: bdwmPrimaryColor, onPrimary: Colors.white,
          secondary: const Color(0xff03dac6), onSecondary: Colors.black,
          error: const Color(0xffb00020), onError: Colors.white,
          surface: Colors.white, onSurface: Colors.black,
          background: Colors.white, onBackground: Colors.black,
        ),
        cardTheme: CardTheme(color: Colors.white, surfaceTintColor: Colors.white, shadowColor: bdwmPrimaryColor),
        brightness: Brightness.light,
        useMaterial3: true,
        // iconTheme: IconThemeData(color: bdwmPrimaryColor),
      ),
      darkTheme: ThemeData(
        // colorScheme: const ColorScheme.dark().copyWith(primary: bdwmPrimaryColor, surface: Colors.grey[800]),
        colorScheme: ColorScheme(brightness: Brightness.dark,
          primary: bdwmPrimaryColor, onPrimary: Colors.black,
          secondary: const Color(0xff03dac6), onSecondary: Colors.black,
          error: const Color(0xffcf6679), onError: Colors.black,
          surface: const Color(0xff424242), onSurface: Colors.white,
          background: const Color(0xff121212), onBackground: Colors.white,
        ),
        brightness: Brightness.dark,
        useMaterial3: true,
        // iconTheme: IconThemeData(color: bdwmPrimaryColor),
      ),
      routerDelegate: mainRouterDelegate,
      // backButtonDispatcher: RootBackButtonDispatcher(),
    );
  }
}
