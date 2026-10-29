import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Android devices may report legacy IANA names such as Asia/Saigon.
// Keep aliases as well as current names so local reminders can be scheduled.
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../network/api_exception.dart';

class ReminderSettings {
  final bool enabled, exact;
  final int hour, minute;
  const ReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
    this.exact = true,
  });
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'exact': exact,
  };
  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    final hour = json['hour'], minute = json['minute'];
    if (hour is! int ||
        hour < 0 ||
        hour > 23 ||
        minute is! int ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('Invalid reminder time');
    }
    return ReminderSettings(
      enabled: json['enabled'] == true,
      hour: hour,
      minute: minute,
      exact: json['exact'] != false,
    );
  }
}

tz.TZDateTime nextStudyReminder(tz.TZDateTime now, int hour, int minute) {
  var date = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!date.isAfter(now)) {
    date = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }
  return date;
}

abstract class ReminderNotifications {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<bool> isAllowed();
  Future<bool> requestExactPermission();
  Future<bool> canScheduleExact();
  Future<void> schedule(ReminderSettings settings);
  Future<void> cancel();
}

class DeviceReminderNotifications implements ReminderNotifications {
  static final openCourses = ValueNotifier<bool>(false);
  static const notificationId = 71001;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  @override
  Future<void> initialize() =>
      _initializing ??= _initialize().catchError((Object e) {
        _initializing = null;
        throw e;
      });
  Future<void> _initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw const ApiException(
        message: 'Nhắc học hiện hỗ trợ trên điện thoại Android và iPhone.',
      );
    }
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_study_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == 'study_reminder') openCourses.value = true;
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.payload == 'study_reminder') {
      openCourses.value = true;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (_android != null) {
      return await _android!.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<bool> isAllowed() async {
    await initialize();
    if (_android != null) {
      return await _android!.areNotificationsEnabled() ?? false;
    }
    return (await _ios?.checkPermissions())?.isEnabled ?? false;
  }

  @override
  Future<bool> canScheduleExact() async {
    await initialize();
    return _android == null ||
        await _android!.canScheduleExactNotifications() == true;
  }

  @override
  Future<bool> requestExactPermission() async {
    if (_android == null) return true;
    if (await _android!.canScheduleExactNotifications() == true) return true;
    return await _android!.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<void> schedule(ReminderSettings settings) async {
    await initialize();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Đến giờ học rồi!',
      body: 'Dành một chút thời gian để tiếp tục khóa học của bạn nhé.',
      payload: 'study_reminder',
      scheduledDate: nextStudyReminder(
        tz.TZDateTime.now(tz.local),
        settings.hour,
        settings.minute,
      ),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminders',
          'Nhắc học hằng ngày',
          channelDescription: 'Thông báo nhắc bạn học theo giờ đã chọn.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_study_notification',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: settings.exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() async {
    await initialize();
    await _plugin.cancel(id: notificationId);
  }
}

class StudyReminderService {
  static final instance = StudyReminderService();
  static const storageKey = 'study_reminder_v1';
  final ReminderNotifications notifications;
  final SharedPreferences? preferences;
  StudyReminderService({ReminderNotifications? notifications, this.preferences})
    : notifications = notifications ?? DeviceReminderNotifications();
  Future<SharedPreferences> get _prefs async =>
      preferences ?? await SharedPreferences.getInstance();
  Future<ReminderSettings> load() async {
    final raw = (await _prefs).getString(storageKey);
    return raw == null
        ? const ReminderSettings()
        : ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _store(ReminderSettings settings) async {
    if (!await (await _prefs).setString(
      storageKey,
      jsonEncode(settings.toJson()),
    )) {
      throw const ApiException(
        message: 'Chưa lưu được lịch nhắc. Vui lòng thử lại.',
      );
    }
  }

  /// Re-register the persisted daily alarm after app updates or a lost alarm.
  /// Startup only: never prompt for permissions and never switch reminders on.
  Future<ReminderSettings> restore() async {
    final old = await load();
    if (!old.enabled) return old;
    await notifications.initialize();
    if (!await notifications.isAllowed()) return old;
    final exact = await notifications.canScheduleExact();
    final settings = ReminderSettings(
      enabled: true,
      hour: old.hour,
      minute: old.minute,
      exact: exact,
    );
    await notifications.schedule(settings);
    if (old.exact != exact) await _store(settings);
    return settings;
  }

  Future<ReminderSettings> enable(TimeOfDay time) async {
    final old = await load();
    await notifications.initialize();
    if (!await notifications.requestPermission()) {
      throw const ApiException(
        message:
            'Thông báo chưa được cho phép. Vào Cài đặt điện thoại → Thông báo → E-Learning để bật quyền.',
      );
    }
    final exact = await notifications.requestExactPermission();
    final next = ReminderSettings(
      enabled: true,
      hour: time.hour,
      minute: time.minute,
      exact: exact,
    );
    try {
      await notifications.schedule(next);
      await _store(next);
    } catch (_) {
      try {
        if (old.enabled) {
          await notifications.schedule(old);
        } else {
          await notifications.cancel();
        }
      } catch (_) {
        /* Keep the original scheduling error. */
      }
      rethrow;
    }
    return next;
  }

  Future<ReminderSettings> disable() async {
    final old = await load();
    await notifications.cancel();
    final next = ReminderSettings(
      hour: old.hour,
      minute: old.minute,
      exact: old.exact,
    );
    try {
      await _store(next);
    } catch (_) {
      if (old.enabled) await notifications.schedule(old);
      rethrow;
    }
    return next;
  }
}
