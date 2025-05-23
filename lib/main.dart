import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_fonts/dynamic_fonts.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:dynamic_color/dynamic_color.dart';
// import 'package:flutter/rendering.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart' show FlutterDisplayMode, DisplayMode;
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;

import './router.dart';
import './globalvars.dart';
import './views/constants.dart' show bdwmPrimaryColor, bdwmSurfaceColor;
import './services.dart';
import './services_instance.dart';
import './bdwm/mail.dart';
import './utils.dart';
import './views/utils.dart' show showInformDialog;
import './check_update.dart' show checkUpdateByTime, curVersionForBBS;
import './notification.dart' show initFlnInstance;
import './views/top10.dart' show getDataTop10, gotTop10, isTop10Valid;
import './pages/read_thread.dart' show naviGotoThreadByLink;
import './views/multi_users.dart' show processSwitchUsersDialog, showSwitchUsersDialog;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isAndroid()) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }
  // debugPaintSizeEnabled = true;
  // debugProfilePlatformChannels = true;
  await globalContactInfo.init();
  await globalConfigInfo.init();
  await globalNotConfigInfo.init();
  await globalUInfo.init(useGuest: globalConfigInfo.getGuestFirst());
  await globalImmConfigInfo.init();
  await globalThreadHistory.init();
  await globalMarkedThread.init();
  await globalPostHistoryData.init();
  await initFlnInstance();
  initPrimaryColor();
  // if (!globalConfigInfo.getGuestFirst()) {
  //   checkUpdateByTime();
  // }
  await unreadMessage.initWorker();
  await unreadMail.initWorker();
  registerDynamicFont();
  if (isAndroid()) {
    await setHighRefreshRate(globalConfigInfo.getRefreshRate());
  }
  runApp(const MainPage());
}

@pragma("vm:entry-point")
Future<void> backgroundCallback(Uri? uri) async {
  if (uri == null) { return; }
  if (uri.scheme != "bdwmviewer") { return; }
  await globalUInfo.init();
  if (uri.host == 'obviewerupdatetop10') {
    String top10string = "";
    String top10Status = "";
    var homeInfo = await getDataTop10();
    if (homeInfo.errorMessage != null) {
      top10string = await HomeWidget.getWidgetData<String>('_top10string', defaultValue: "") ?? "";
      top10Status = "网络超时";
    } else {
      if (gotTop10(homeInfo.top10Info) && isTop10Valid(homeInfo.top10Info!)) {
        for (var item in homeInfo.top10Info!) {
          top10string += "${item.title}\n${item.link}\n${item.countComments}\n";
        }
        top10Status = "更新十大成功";
      } else {
        top10string = await HomeWidget.getWidgetData<String>('_top10string', defaultValue: "") ?? "";
        top10Status = "获取十大失败";
      }
    }
    debugPrint(top10string);
    await HomeWidget.saveWidgetData<String>('_top10status', top10Status);
    await HomeWidget.saveWidgetData<String>('_top10string', top10string);
    await HomeWidget.updateWidget(name: 'HomeWidget0Provider', iOSName: 'AppWidgetProvider');
  }
}

Future<void> setHighRefreshRate(String refreshRate) async {
  if (refreshRate == 'no') { return; }
  if (refreshRate == 'high') {
    await FlutterDisplayMode.setHighRefreshRate();
  } else if (refreshRate == 'low') {
    await FlutterDisplayMode.setLowRefreshRate();
  } else {
    var values = refreshRate.split(",");
    await FlutterDisplayMode.setPreferredMode(DisplayMode(
      id: int.parse(values[0]), width: int.parse(values[1]), height: int.parse(values[2]), refreshRate: double.parse(values[3]),
    ));
  }
}

void initPrimaryColor() {
  var colorValue = int.tryParse(globalConfigInfo.getPrimaryColorString());
  if (colorValue != null) {
    bdwmPrimaryColor = Color(colorValue);
  } else {
    bdwmPrimaryColor = bdwmSurfaceColor;
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

// const _brandBlue = Color(0xFF1E88E5);

class MainPage extends StatefulWidget {
  const MainPage({super.key});

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
  final navigatorKey = GlobalKey<NavigatorState>();

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
    mainRouterDelegate = MainRouterDelegate.init();

    updateUnreadMessageData();
    updateUnreadMailData();
    timerMessage = Timer.periodic(const Duration(seconds: 30), (timer) {
      updateUnreadMessageData();
      timerMessage = timer;
    });
    timerMail = Timer.periodic(const Duration(seconds: 30), (timer) {
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
            mainRouterDelegate?.replace(shortcutType);
            break;
          default:
            mainRouterDelegate?.push(shortcutType);
        }
      });
      quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: '/message', localizedTitle: '消息', icon: 'ic_wei'),
        const ShortcutItem(type: '/mail', localizedTitle: '站内信', icon: 'ic_wei'),
        const ShortcutItem(type: '/search', localizedTitle: '搜索', icon: 'ic_wei'),
        const ShortcutItem(type: '/recentThread', localizedTitle: '最近浏览', icon: 'ic_wei'),
        const ShortcutItem(type: '/markedThread', localizedTitle: '帖子收藏', icon: 'ic_wei'),
      ]);

      HomeWidget.registerInteractivityCallback(backgroundCallback);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (globalConfigInfo.getGuestFirst()) {
        // 延后1秒再选择用户：当通过桌面小组件进入十大帖子时，可在刷新后浏览登录后才能看的帖子
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        if (!mounted) { return; }
        var globalContext = getGlobalContext();
        if (globalContext == null) { return; }
        if (!globalContext.mounted) { return; }
        var switchRes = await showSwitchUsersDialog(globalContext, showLogin: false, desc: "选择非游客需要下拉刷新，不需要重新登录");
        await processSwitchUsersDialog(switchRes);
        if (globalUInfo.uid != guestUitem.uid) {
          // await globalUInfo.init();
          // checkUpdateByTime();
          showUpdateDialog();
          // setState(() { });
        }
      } else {
        showUpdateDialog();
      }
    });
  }
  
  Future<void> showUpdateDialog() async {
    var res = await checkUpdateByTime();
    if (res.isEmpty) { return; }
    if (res.startsWith("checked")) {
      return;
    }
    if (!mounted) { return; }
    var globalContext = getGlobalContext();
    if (globalContext == null) { return; }
    var txt = "原因未知";
    var values = res.split("-");
    if (values.length > 1) {
      txt = values[1];
    }
    if (res.startsWith("checkfail")) {
      txt = "失败：$txt";
    } else if (res.startsWith("checksuccess")) {
      txt = "最新版本：$txt\n当前版本：$curVersionForBBS";
    }
    if (!globalContext.mounted) { return; }
    showInformDialog(globalContext, "检查新版本", txt);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isAndroid()) {
      _checkForWidgetLaunch();
      HomeWidget.widgetClicked.listen(_launchedFromWidget);
    }
  }

  void _checkForWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget);
  }

  void _launchedFromWidget(Uri? uri) {
    debugPrint('uri $uri');
    if (uri == null) { return; }
    if (uri.scheme != "bdwmviewer") { return; }
    if (uri.host == 'obvieweropenlink') {
      var link = uri.queryParameters["link"] ?? "";
      debugPrint('open $link');
      if (link.isEmpty) {
        return;
      }
      var arguments = naviGotoThreadByLink(null, link, "", getArguments: true, needToBoard: true);
      if (arguments == null) { return; }
      mainRouterDelegate?.push('/thread', arguments: arguments);
    }
  }

  void refresh() {
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("** main rebuild");
    bool useDynamicColor = globalConfigInfo.useDynamicColor;
    CustomColors lightCustomColors = CustomColors(danger: bdwmPrimaryColor);
    CustomColors darkCustomColors = CustomColors(danger: bdwmPrimaryColor);

    // https://github.com/material-foundation/material-dynamic-color-flutter/blob/main/example/lib/complete_example.dart
    // https://m3.material.io/styles/color/dynamic-color/user-generated-color
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
          // lightColorScheme = lightColorScheme.copyWith(secondary: _brandBlue);
          if (useDynamicColor) {
            bdwmPrimaryColor = lightColorScheme.primary;
          }
          // (Optional) If applicable, harmonize custom colors.
          lightCustomColors = lightCustomColors.harmonized(lightColorScheme);

          // Repeat for the dark color scheme.
          darkColorScheme = darkDynamic.harmonized();
          // darkColorScheme = darkColorScheme.copyWith(secondary: _brandBlue);
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
          localizationsDelegates: [...GlobalMaterialLocalizations.delegates, FlutterQuillLocalizations.delegate],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
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
              secondary: bdwmPrimaryColor.withAlpha(200), onSecondary: Colors.black,
              error: const Color(0xffb00020), onError: Colors.white,
              surface: Colors.white, onSurface: Colors.black,
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
              secondary: bdwmPrimaryColor.withAlpha(200), onSecondary: Colors.black,
              error: const Color(0xffcf6679), onError: Colors.black,
              surface: const Color(0xff424242), onSurface: Colors.white,
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
