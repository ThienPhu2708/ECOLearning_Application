import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/data/models/user.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/presentation/screens/profile/edit_profile_sheet.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  User user() => User(
    id: '1',
    fullName: 'Ánh Ngọc',
    email: 'ngoc@example.com',
    avatarUrl: '',
    phone: '0987654321',
  );
  Future<void> open(
    WidgetTester tester,
    Future<User> Function(String, String, String?, DateTime?) save,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<User>(
                context: context,
                isScrollControlled: true,
                builder: (_) => EditProfileSheet(user: user(), onSave: save),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
  }

  testWidgets('prefills profile, locks email and validates name and phone', (
    tester,
  ) async {
    int calls = 0;
    await open(tester, (_, _, _, _) async {
      calls++;
      return user();
    });
    expect(find.text('Ánh Ngọc'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).readOnly,
      true,
    );
    await tester.enterText(find.byType(TextFormField).at(0), '   ');
    await tester.ensureVisible(find.byType(TextFormField).at(2));
    await tester.enterText(find.byType(TextFormField).at(2), 'abc');
    await submit(tester);
    expect(find.text('Vui lòng nhập họ và tên.'), findsOneWidget);
    expect(find.text('Số điện thoại cần có 9–15 chữ số.'), findsOneWidget);
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('server error preserves edits and exposes field error', (
    tester,
  ) async {
    await open(
      tester,
      (_, _, _, _) async => throw const ApiException(
        message: 'Chưa lưu được.',
        errors: {'phone': 'Số điện thoại không hợp lệ.'},
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Tên mới');
    await submit(tester);
    expect(find.text('Chưa lưu được.'), findsOneWidget);
    expect(find.text('Số điện thoại không hợp lệ.'), findsOneWidget);
    expect(find.text('Tên mới'), findsOneWidget);
    expect(find.byType(EditProfileSheet), findsOneWidget);
  });
  testWidgets('success waits for saving, submits trimmed name and closes', (
    tester,
  ) async {
    final pending = Completer<User>();
    int calls = 0;
    await open(tester, (name, phone, gender, date) {
      calls++;
      expect(name, 'Tên mới');
      expect(phone, '0987654321');
      return pending.future;
    });
    await tester.enterText(find.byType(TextFormField).at(0), '  Tên mới  ');
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(EditProfileSheet), findsOneWidget);
    pending.complete(user());
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileSheet), findsNothing);
  });
}
