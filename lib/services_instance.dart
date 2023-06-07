import './services.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;

ValueNotifier<int> messageCount = ValueNotifier<int>(0);
ValueNotifier<int> mailCount = ValueNotifier<int>(0);
MessageBriefNotifier messageBrief = MessageBriefNotifier([]);
NotifyMessage unreadMessage = NotifyMessage();
NotifyMail unreadMail = NotifyMail();
