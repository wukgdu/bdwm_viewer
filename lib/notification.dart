import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import './utils.dart' show checkAndRequestPermission;

// https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/lib/main.dart

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
int quickID = 0;
const String groupKey = "com.wukgdu365.bdwm_viewer";

const AndroidNotificationDetails androidNotificationDetailsGeneral = AndroidNotificationDetails(
  "general", "通用",
  channelDescription: 'OBViewer 通用通知渠道',
  groupKey: groupKey,
  importance: Importance.max,
  priority: Priority.high,
  ticker: 'OBViewer',
);

void sendNotification(String title, String content, {String? payload, String type="general"}) {
  switch (type) {
    case "general":
      quickNotify(title, content);
      break;
  }
}

Future<void> quickNotify(String title, String content) async {
  bool couldDoIt = await checkAndRequestNotificationPermission();
  if (!couldDoIt) { return; }
  if (Platform.isWindows) {
  } else if (Platform.isAndroid) {
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetailsGeneral);
    await flutterLocalNotificationsPlugin.show(
      quickID++, title, content, notificationDetails,
      payload: ''
    );
  }
}

Future<bool> checkAndRequestNotificationPermission() async {
  bool couldDoIt = true;
  if (Platform.isWindows) {
    couldDoIt = await checkAndRequestPermission(Permission.notification);
  } else if (Platform.isAndroid) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      // couldDoIt = await checkAndRequestPermission(Permission.notification);
      var flnInstance = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (flnInstance == null) {
        couldDoIt = false;
      } else {
        couldDoIt = (await flnInstance.areNotificationsEnabled()) ?? false;
        if (couldDoIt == false) {
          couldDoIt = (await flnInstance.requestPermission()) ?? false;
        }
      }
    } else {
      couldDoIt = await checkAndRequestPermission(Permission.notification);
    }
  }
  return couldDoIt;
}

// @pragma('vm:entry-point')
// void notificationTapBackground(NotificationResponse notificationResponse) {
// }

Future<void> initFlnInstance() async {
  // TODO: didNotificationLaunchApp
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_quick_notify');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      switch (notificationResponse.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          // selectNotificationStream.add(notificationResponse.payload);
          break;
        case NotificationResponseType.selectedNotificationAction:
          break;
      }
    },
    // onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}
