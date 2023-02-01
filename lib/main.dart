import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_fonts/dynamic_fonts.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:dynamic_color/dynamic_color.dart';
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

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.danger,
  });

  final Color? danger;

  @override
  CustomColors copyWith({Color? danger}) {
    return CustomColors(
      danger: danger ?? this.danger,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      danger: Color.lerp(danger, other.danger, t),
    );
  }

  CustomColors harmonized(ColorScheme dynamic) {
    return copyWith(danger: danger!.harmonizeWith(dynamic.primary));
  }
}

const _brandBlue = Color(0xFF1E88E5);

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
    bool useDynamicColor = true;
    CustomColors lightCustomColors = CustomColors(danger: bdwmPrimaryColor);
    CustomColors darkCustomColors = CustomColors(danger: bdwmPrimaryColor);

    // https://github.com/material-foundation/material-dynamic-color-flutter/blob/main/example/lib/complete_example.dart
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // On Android S+ devices, use the provided dynamic color scheme.
          // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
          lightColorScheme = lightDynamic.harmonized();
          // (Optional) Customize the scheme as desired. For example, one might
          // want to use a brand color to override the dynamic [ColorScheme.secondary].
          lightColorScheme = lightColorScheme.copyWith(secondary: _brandBlue);
          bdwmPrimaryColor = lightColorScheme.primary;
          // (Optional) If applicable, harmonize custom colors.
          lightCustomColors = lightCustomColors.harmonized(lightColorScheme);

          // Repeat for the dark color scheme.
          darkColorScheme = darkDynamic.harmonized();
          darkColorScheme = darkColorScheme.copyWith(secondary: _brandBlue);
          darkCustomColors = darkCustomColors.harmonized(darkColorScheme);
        } else {
          // Otherwise, use fallback schemes.
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: bdwmPrimaryColor,
            brightness: Brightness.light,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: bdwmPrimaryColor,
            brightness: Brightness.dark,
          );
        }
        return MaterialApp.router(
          title: 'OBViewer',
          theme: useDynamicColor ? ThemeData(
            colorScheme: lightColorScheme,
            extensions: [lightCustomColors],
            brightness: Brightness.light,
            useMaterial3: globalConfigInfo.useMD3
          ) : ThemeData(
            // colorScheme: ColorScheme.fromSeed(seedColor: bdwmPrimaryColor),
            colorScheme: !globalConfigInfo.useMD3 ? const ColorScheme.light().copyWith(primary: bdwmPrimaryColor)
            : ColorScheme(brightness: Brightness.light,
              primary: bdwmPrimaryColor, onPrimary: Colors.white,
              secondary: const Color(0xff03dac6), onSecondary: Colors.black,
              error: const Color(0xffb00020), onError: Colors.white,
              surface: Colors.white, onSurface: Colors.black,
              background: Colors.white, onBackground: Colors.black,
              outlineVariant: const Color(0xffcccccc),
            ),
            cardTheme: CardTheme(color: Colors.white, surfaceTintColor: Colors.white, shadowColor: bdwmPrimaryColor),
            brightness: Brightness.light,
            useMaterial3: globalConfigInfo.useMD3,
            // iconTheme: IconThemeData(color: bdwmPrimaryColor),
          ),
          darkTheme: useDynamicColor ? ThemeData(
            colorScheme: darkColorScheme,
            extensions: [darkCustomColors],
            brightness: Brightness.dark,
            useMaterial3: globalConfigInfo.useMD3
          ) : ThemeData(
            colorScheme: !globalConfigInfo.useMD3 ? const ColorScheme.dark().copyWith(primary: bdwmPrimaryColor, surface: Colors.grey[800])
            : ColorScheme(brightness: Brightness.dark,
              primary: bdwmPrimaryColor, onPrimary: Colors.black,
              secondary: const Color(0xff03dac6), onSecondary: Colors.black,
              error: const Color(0xffcf6679), onError: Colors.black,
              surface: const Color(0xff424242), onSurface: Colors.white,
              background: const Color(0xff323232), onBackground: Colors.white,
              outlineVariant: const Color(0xffcccccc),
            ),
            brightness: Brightness.dark,
            useMaterial3: globalConfigInfo.useMD3,
            // iconTheme: IconThemeData(color: bdwmPrimaryColor),
          ),
          routerDelegate: mainRouterDelegate,
          // backButtonDispatcher: RootBackButtonDispatcher(),
        );
      }
    );
  }
}
