import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/presentation/screens/profile/change_password_sheet.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  Future<void> open(
    WidgetTester tester, {
    Future<void> Function(String, String)? submit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ChangePasswordSheet(onSubmit: submit),
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

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Lưu mật khẩu mới'));
    await tester.tap(find.text('Lưu mật khẩu mới'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester,
    String old,
    String next,
    String confirm,
  ) async {
    final values = [old, next, confirm];
    for (int i = 0; i < 3; i++) {
      await tester.ensureVisible(find.byType(TextFormField).at(i));
      await tester.enterText(find.byType(TextFormField).at(i), values[i]);
    }
  }

  testWidgets(
    'validates required, length, reuse and confirmation without submitting',
    (tester) async {
      int calls = 0;
      await open(
        tester,
        submit: (_, _) async {
          calls++;
        },
      );
      await save(tester);
      expect(find.textContaining('Vui lòng nhập'), findsNWidgets(3));
      await fill(tester, 'password1', 'short', 'different');
      await save(tester);
      expect(find.text('Mật khẩu mới cần ít nhất 8 ký tự.'), findsOneWidget);
      expect(find.text('Mật khẩu xác nhận chưa khớp.'), findsOneWidget);
      await fill(tester, 'password1', 'password1', 'password1');
      await save(tester);
      expect(
        find.text('Mật khẩu mới phải khác mật khẩu hiện tại.'),
        findsOneWidget,
      );
      expect(calls, 0);
    },
  );
  testWidgets('visibility toggles and server error keeps form for retry', (
    tester,
  ) async {
    await open(
      tester,
      submit: (_, _) async => throw const ApiException(
        message: 'Mật khẩu hiện tại không đúng.',
        errors: {'currentPassword': 'Kiểm tra mật khẩu hiện tại.'},
      ),
    );
    await tester.tap(find.byTooltip('Hiện Mật khẩu hiện tại'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).obscureText,
      false,
    );
    await fill(tester, 'oldpassword', 'newpassword', 'newpassword');
    await save(tester);
    expect(find.text('Mật khẩu hiện tại không đúng.'), findsOneWidget);
    expect(find.text('Kiểm tra mật khẩu hiện tại.'), findsOneWidget);
    expect(find.byType(ChangePasswordSheet), findsOneWidget);
  });
  testWidgets('sample never claims password was changed', (tester) async {
    await open(tester);
    await fill(tester, 'oldpassword', 'newpassword', 'newpassword');
    await save(tester);
    expect(
      find.textContaining('Mật khẩu của bạn chưa thay đổi.'),
      findsOneWidget,
    );
    expect(find.byType(ChangePasswordSheet), findsOneWidget);
  });
  testWidgets('waits for service and prevents duplicate submission', (
    tester,
  ) async {
    final pending = Completer<void>();
    int calls = 0;
    await open(
      tester,
      submit: (old, next) {
        calls++;
        expect(old, 'oldpassword');
        expect(next, 'newpassword');
        return pending.future;
      },
    );
    await fill(tester, 'oldpassword', 'newpassword', 'newpassword');
    await tester.ensureVisible(find.text('Lưu mật khẩu mới'));
    await tester.tap(find.text('Lưu mật khẩu mới'));
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(ChangePasswordSheet), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.close_rounded),
          )
          .onPressed,
      isNull,
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordSheet), findsNothing);
  });
}
