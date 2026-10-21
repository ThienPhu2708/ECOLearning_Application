import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolearning_app/presentation/screens/learning/lesson_notes_tab.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('notes persist per user and lesson with timestamp and delete', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    int? sought;
    Future<void> show(String lesson, {String user = 'u'}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonNotesTab(
              key: ValueKey('$user/$lesson'),
              userId: user,
              courseId: 'c',
              lessonId: lesson,
              lessonTitle: 'Bài học',
              position: () => 125,
              onSeek: (time) async {
                sought = time;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show('a');
    await tester.tap(find.text('Lưu ghi chú tại mốc hiện tại'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập nội dung ghi chú.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Nội dung cần nhớ');
    await tester.tap(find.text('Lưu ghi chú tại mốc hiện tại'));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung cần nhớ'), findsOneWidget);
    await tester.tap(find.text('02:05'));
    expect(sought, 125);
    await show('b');
    expect(find.text('Nội dung cần nhớ'), findsNothing);
    await show('a', user: 'other');
    expect(find.text('Nội dung cần nhớ'), findsNothing);
    await show('a');
    expect(find.text('Nội dung cần nhớ'), findsOneWidget);
    await tester.tap(find.byTooltip('Xóa ghi chú'));
    await tester.pumpAndSettle();
    await show('b');
    await show('a');
    expect(find.text('Nội dung cần nhớ'), findsNothing);
  });
}
