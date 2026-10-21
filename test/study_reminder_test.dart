import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;
import 'package:ecolearning_app/core/notifications/study_reminder_service.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/presentation/screens/profile/study_reminder_tile.dart';

class FakeNotifications implements ReminderNotifications {
  bool allowed = true, exact = true, fail = false;
  ReminderSettings? pending;
  int schedules = 0, cancels = 0, permissionRequests = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> isAllowed() async => allowed;
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<bool> requestExactPermission() async => exact;
  @override
  Future<void> schedule(ReminderSettings settings) async {
    schedules++;
    if (fail) {
      fail = false;
      throw Exception('Cannot schedule');
    }
    pending = settings;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    pending = null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    data.initializeTimeZones();
  });
  test(
    'next reminder uses local time and advances to next day once the minute passed',
    () {
      final zone = tz.getLocation('Asia/Ho_Chi_Minh');
      expect(
        nextStudyReminder(tz.TZDateTime(zone, 2026, 10, 21, 19, 59), 20, 0),
        tz.TZDateTime(zone, 2026, 10, 21, 20),
      );
      expect(
        nextStudyReminder(tz.TZDateTime(zone, 2026, 10, 21, 20), 20, 0),
        tz.TZDateTime(zone, 2026, 10, 22, 20),
      );
      expect(
        nextStudyReminder(tz.TZDateTime(zone, 2026, 12, 31, 23, 59), 0, 5),
        tz.TZDateTime(zone, 2027, 1, 1, 0, 5),
      );
      final dst = tz.getLocation('America/New_York');
      expect(
        nextStudyReminder(tz.TZDateTime(dst, 2026, 3, 7, 21), 20, 0),
        tz.TZDateTime(dst, 2026, 3, 8, 20),
      );
    },
  );
  test(
    'defaults off, persists time, replaces daily reminder and cancels when disabled',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final platform = FakeNotifications();
      final service = StudyReminderService(
        preferences: prefs,
        notifications: platform,
      );
      expect((await service.load()).enabled, false);
      expect(platform.permissionRequests, 0);
      await service.enable(const TimeOfDay(hour: 20, minute: 35));
      expect(platform.pending!.timeLabel, '20:35');
      expect(
        (await StudyReminderService(
          preferences: prefs,
          notifications: platform,
        ).load()).enabled,
        true,
      );
      await service.enable(const TimeOfDay(hour: 7, minute: 5));
      expect(platform.pending!.timeLabel, '07:05');
      await service.disable();
      expect(platform.pending, isNull);
      expect((await service.load()).enabled, false);
      expect((await service.load()).timeLabel, '07:05');
    },
  );
  test(
    'denied notification permission never marks reminders enabled',
    () async {
      final platform = FakeNotifications()..allowed = false;
      final service = StudyReminderService(
        preferences: await SharedPreferences.getInstance(),
        notifications: platform,
      );
      await expectLater(
        service.enable(const TimeOfDay(hour: 20, minute: 0)),
        throwsA(isA<ApiException>()),
      );
      expect((await service.load()).enabled, false);
      expect(platform.schedules, 0);
    },
  );
  test(
    'inexact permission fallback is recorded and failed edit retains old reminder',
    () async {
      final platform = FakeNotifications()..exact = false;
      final service = StudyReminderService(
        preferences: await SharedPreferences.getInstance(),
        notifications: platform,
      );
      await service.enable(const TimeOfDay(hour: 20, minute: 0));
      expect((await service.load()).exact, false);
      platform.fail = true;
      await expectLater(
        service.enable(const TimeOfDay(hour: 21, minute: 0)),
        throwsException,
      );
      expect((await service.load()).timeLabel, '20:00');
      expect(platform.pending!.timeLabel, '20:00');
    },
  );
  testWidgets(
    'toggle asks for hour and minute, cancel leaves off, saved time can be edited or disabled',
    (tester) async {
      final platform = FakeNotifications();
      final service = StudyReminderService(
        preferences: await SharedPreferences.getInstance(),
        notifications: platform,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StudyReminderTile(service: service)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(platform.schedules, 0);
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu giờ nhắc'));
      await tester.pumpAndSettle();
      expect(find.text('Nhắc mỗi ngày lúc 20:00'), findsOneWidget);
      expect(find.text('Đổi giờ nhắc'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(platform.pending, isNull);
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    },
  );
}
