import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/data/repositories/lesson_resources_repository.dart';
import 'package:ecolearning_app/presentation/screens/learning/lesson_notes_tab.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/presentation/screens/learning/learning_space_screen.dart';
import 'learning_test.dart' show FakeLearning, makeLesson;

class NotesVideo extends VideoPlayerController {
  NotesVideo() : super.networkUrl(Uri.parse('https://example.com/lesson.mp4')) {
    value = const VideoPlayerValue(
      duration: Duration(minutes: 5),
      size: Size(1920, 1080),
      isInitialized: true,
    );
  }
  final seeks = <int>[];
  @override
  Future<void> initialize() async {}
  @override
  Future<void> seekTo(Duration position) async {
    seeks.add(position.inSeconds);
    value = value.copyWith(position: position);
  }
}

class FakeNotes extends LessonResourcesRepository {
  final values = <String, List<Map<String, dynamic>>>{};
  int next = 1;
  @override
  Future<List<Map<String, dynamic>>> notes(
    String course,
    String lesson,
  ) async => List.of(values['$course/$lesson'] ?? []);
  @override
  Future<Map<String, dynamic>> saveNote(
    String course,
    String lesson,
    String content,
    int seconds, {
    int? id,
  }) async {
    final note = {
      'id': id ?? next++,
      'content': content,
      'positionSeconds': seconds,
    };
    final items = values.putIfAbsent('$course/$lesson', () => []);
    items.removeWhere((n) => n['id'] == id);
    items.add(note);
    return note;
  }

  @override
  Future<void> deleteNote(int id) async {
    for (final items in values.values) {
      items.removeWhere((n) => n['id'] == id);
    }
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'learning screen jumps to saved note timestamps while free scrubbing stays disabled',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final notes = FakeNotes();
      await notes.saveNote('course', 'b', 'Mở đầu', 51);
      await notes.saveNote('course', 'b', 'Các kiểu dữ liệu', 86);
      final video = NotesVideo();
      final repo = FakeLearning()
        ..readLesson = ((id) async => makeLesson(id).copyWith(
          videoUrl: 'https://example.com/lesson.mp4',
          lastPositionSeconds: 150,
        ));
      await tester.pumpWidget(
        MaterialApp(
          home: LearningSpaceScreen(
            course: Course.fromJson({'id': 'course', 'title': 'Course'}),
            repository: repo,
            resources: notes,
            videoControllerFactory: (_) => video,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(video.seeks, [150]);
      await tester.tap(find.text('Ghi chú'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('00:51'));
      await tester.tap(find.text('00:51'));
      await tester.pumpAndSettle();
      expect(video.value.position.inSeconds, 51);
      await tester.ensureVisible(find.text('01:26'));
      await tester.tap(find.text('01:26'));
      await tester.pumpAndSettle();
      expect(video.value.position.inSeconds, 86);
      expect(find.byType(Slider), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'server notes reload per account and lesson with timestamp and delete',
    (tester) async {
      final accounts = <String, FakeNotes>{};
      int? sought;
      Future<void> show(String lesson, {String user = 'u'}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LessonNotesTab(
                key: ValueKey('$user/$lesson'),
                userId: user,
                repository: accounts.putIfAbsent(user, () => FakeNotes()),
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
    },
  );
}
