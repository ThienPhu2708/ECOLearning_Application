import 'package:ecolearning_app/data/repositories/lesson_discussion_repository.dart';
import 'package:ecolearning_app/presentation/screens/learning/lesson_discussion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDiscussion extends LessonDiscussionRepository {
  int? sentParent;
  String? sentContent;
  @override
  Future<DiscussionPage> timeline(
    String course,
    String lesson, {
    int page = 1,
  }) async => DiscussionPage.fromJson({
    'page': page,
    'totalPages': 2,
    'totalComments': 3,
    'items': page == 1
        ? [
            {
              'id': 2,
              'authorName': 'An',
              'content': 'Câu hỏi',
              'createdAt': '2026-11-06T00:02:00Z',
            },
            {
              'id': 3,
              'parentId': 2,
              'authorName': 'Bình',
              'content': 'Trả lời',
              'replyToAuthor': 'An',
              'replyToContent': 'Câu hỏi',
              'createdAt': '2026-11-06T00:03:00Z',
            },
            if (sentContent != null)
              {
                'id': 4,
                'authorName': 'Tôi',
                'content': sentContent,
                'isMine': true,
                'createdAt': '2026-11-06T00:04:00Z',
              },
          ]
        : [
            {
              'id': 1,
              'authorName': 'Lan',
              'content': 'Tin cũ',
              'createdAt': '2026-11-06T00:01:00Z',
            },
            {
              'id': 2,
              'authorName': 'An',
              'content': 'Câu hỏi',
              'createdAt': '2026-11-06T00:02:00Z',
            },
          ],
  });
  @override
  Future<void> send(
    String course,
    String lesson,
    String content,
    int? parentId, {
    List<int>? image,
    String? filename,
  }) async {
    sentParent = parentId;
    sentContent = content;
  }
}

void main() {
  testWidgets('Enter sends and Alt+Enter inserts a newline at the cursor', (
    tester,
  ) async {
    final repo = FakeDiscussion();
    await tester.pumpWidget(
      MaterialApp(
        home: LessonDiscussionScreen(
          courseId: 'c',
          lessonId: 'l',
          lessonTitle: 'Bài',
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Xin chào');
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    expect(controller.text, 'Xin\n chào');
    expect(repo.sentContent, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(repo.sentContent, 'Xin\n chào');
    expect(controller.text, isEmpty);
  });

  testWidgets(
    'emoji inserts at cursor and sent comment appears last on right',
    (tester) async {
      final repo = FakeDiscussion();
      await tester.pumpWidget(
        MaterialApp(
          home: LessonDiscussionScreen(
            courseId: 'c',
            lessonId: 'l',
            lessonTitle: 'Bài',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Xin chào');
      final field = tester.widget<TextField>(find.byType(TextField));
      field.controller!.selection = const TextSelection.collapsed(offset: 3);
      await tester.tap(find.byTooltip('Biểu cảm'));
      await tester.pumpAndSettle();
      final emojis = [
        '😀',
        '😂',
        '😊',
        '😍',
        '🥰',
        '😎',
        '🤔',
        '😳',
        '😮',
        '😅',
        '👍',
        '👎',
        '❤️',
        '🎉',
        '👏',
        '🙏',
        '🔥',
        '✅',
        '💡',
        '💯',
      ];
      for (final emoji in emojis) {
        expect(find.text(emoji), findsOneWidget);
      }
      expect(
        tester.getTopLeft(find.text('😂')).dx,
        greaterThan(tester.getTopLeft(find.text('😀')).dx),
      );
      expect(
        tester.getTopLeft(find.text('😎')).dy,
        greaterThan(tester.getTopLeft(find.text('😀')).dy),
      );
      await tester.tap(find.text('😊'));
      await tester.pumpAndSettle();
      expect(field.controller!.text, 'Xin😊 chào');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(repo.sentContent, 'Xin😊 chào');
      final mine = tester.getCenter(find.text('Xin😊 chào'));
      final community = tester.getCenter(find.text('Trả lời'));
      expect(
        mine.dx,
        greaterThan(
          tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
        ),
      );
      expect(
        community.dx,
        lessThan(
          tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
        ),
      );
      expect(mine.dy, greaterThan(community.dy));
    },
  );

  testWidgets(
    'older page is prepended without duplicates and reply targets root',
    (tester) async {
      final repo = FakeDiscussion();
      await tester.pumpWidget(
        MaterialApp(
          home: LessonDiscussionScreen(
            courseId: 'c',
            lessonId: 'l',
            lessonTitle: 'Bài',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Phản hồi An'), findsOneWidget);
      await tester.tap(find.text('Tải thêm'));
      await tester.pumpAndSettle();
      expect(find.text('Tin cũ'), findsOneWidget);
      expect(find.text('Câu hỏi'), findsNWidgets(2)); // message and quote
      await tester.ensureVisible(find.text('Trả lời'));
      final replyButton = find.widgetWithText(TextButton, 'Phản hồi').last;
      await tester.ensureVisible(replyButton);
      await tester.tap(replyButton);
      await tester.enterText(find.byType(TextField), 'Cảm ơn');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(repo.sentParent, 2);
    },
  );
}
