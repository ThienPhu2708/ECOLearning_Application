import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/models/lesson.dart';
import 'package:ecolearning_app/data/repositories/learning_repository.dart';
import 'package:ecolearning_app/presentation/screens/learning/learning_controller.dart';
import 'package:ecolearning_app/presentation/screens/learning/learning_space_screen.dart';
import 'package:ecolearning_app/presentation/screens/learning/rating_dialog.dart';

Lesson makeLesson(String id, {bool completed = false}) => Lesson(
  id: id,
  title: 'Lesson $id',
  duration: '01:40',
  durationSeconds: 100,
  isCompleted: completed,
);
LearningOverview makeOverview({
  bool review = false,
  bool empty = false,
  String? current,
}) => LearningOverview(
  courseId: 'course',
  title: 'Course',
  progress: review ? 100 : 25,
  currentLessonId: current,
  chapters: empty
      ? []
      : [
          Chapter(
            id: 'chapter',
            title: 'Chapter',
            lessons: [makeLesson('a', completed: true), makeLesson('b')],
          ),
        ],
  quizAvailable: true,
  quizPassed: review,
  certificateIssued: false,
  canReview: review,
);

class FakeLearning extends LearningRepository {
  Future<LearningOverview> Function() readOverview = () async => makeOverview();
  Future<Lesson> Function(String) readLesson = (id) async => makeLesson(id);
  Future<ProgressResult> Function(String, int, int) write =
      (id, position, duration) async =>
          const ProgressResult(lessonCompleted: false, courseProgress: 25);
  final selected = <String>[];
  final saved = <(String, int, int)>[];
  @override
  Future<LearningOverview> overview(String courseId) => readOverview();
  @override
  Future<Lesson> lesson(String courseId, String lessonId) {
    selected.add(lessonId);
    return readLesson(lessonId);
  }

  @override
  Future<ProgressResult> saveProgress(
    String courseId,
    String lessonId, {
    required int positionSeconds,
    required int durationSeconds,
  }) {
    saved.add((lessonId, positionSeconds, durationSeconds));
    return write(lessonId, positionSeconds, durationSeconds);
  }
}

const offline = ApiException(message: 'Mất kết nối', code: 'NETWORK');
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('resume uses server lesson, or first unfinished when absent', () async {
    final repo = FakeLearning();
    final c = LearningController(repo, 'course');
    await c.load();
    expect(c.current!.id, 'b');
    repo.readOverview = () async => makeOverview(current: 'a');
    await c.load();
    expect(c.current!.id, 'a');
    c.dispose();
  });
  test('empty course and failed load are recoverable', () async {
    final repo = FakeLearning()..readOverview = (() async => throw offline);
    final c = LearningController(repo, 'course');
    await c.load();
    expect(c.error, offline);
    repo.readOverview = () async => makeOverview(empty: true);
    await c.load();
    expect(c.error, isNull);
    expect(c.current, isNull);
    expect(c.chapters, isEmpty);
    c.dispose();
  });
  test(
    'failed lesson switch retains previous lesson and prevents overlapping switches',
    () async {
      final repo = FakeLearning();
      final c = LearningController(repo, 'course');
      await c.load();
      final pending = Completer<Lesson>();
      repo.readLesson = (_) => pending.future;
      final change = c.select(makeLesson('a'));
      expect(await c.select(makeLesson('b')), false);
      pending.completeError(offline);
      expect(await change, false);
      expect(c.current!.id, 'b');
      c.dispose();
    },
  );
  test(
    'watching beyond eighty percent does not locally complete lessons or unlock review',
    () async {
      final c = LearningController(FakeLearning(), 'course');
      await c.load();
      await c.save('b', 95, 100);
      expect(c.chapters.first.lessons.last.isCompleted, false);
      expect(c.canReview, false);
      c.dispose();
    },
  );
  test(
    'review requires completed lessons and passing quiz even with a stale permission flag',
    () async {
      for (final state in [(50.0, true), (100.0, false), (100.0, true)]) {
        final repo = FakeLearning()
          ..readOverview = (() async => LearningOverview(
            courseId: 'course',
            title: 'Course',
            progress: state.$1,
            currentLessonId: 'a',
            chapters: makeOverview().chapters,
            quizAvailable: true,
            quizPassed: state.$2,
            certificateIssued: false,
            canReview: true,
          ));
        final controller = LearningController(repo, 'course');
        await controller.load();
        expect(controller.canReview, state.$1 == 100 && state.$2);
        controller.dispose();
      }
    },
  );
  test('server completion refreshes review eligibility', () async {
    final repo = FakeLearning();
    final c = LearningController(repo, 'course');
    await c.load();
    repo.write = (_, position, duration) async =>
        const ProgressResult(lessonCompleted: true, courseProgress: 100);
    repo.readOverview = () async => makeOverview(review: true);
    await c.save('b', 100, 100);
    expect(c.canReview, true);
    c.dispose();
  });
  test(
    'failed progress stays attached to its original lesson and retries after switching',
    () async {
      final repo = FakeLearning()
        ..write = ((id, position, duration) async => throw offline);
      final c = LearningController(repo, 'course');
      await c.load();
      await c.save('b', 42, 100);
      expect(c.progressError, offline);
      await c.select(makeLesson('a'));
      repo.write = (_, position, duration) async =>
          const ProgressResult(lessonCompleted: false, courseProgress: 40);
      await c.retryProgress();
      expect(repo.saved, [('b', 42, 100), ('b', 42, 100)]);
      expect(c.current!.id, 'a');
      expect(c.progressError, isNull);
      c.dispose();
    },
  );
  test('progress writes are serialized and positions are clamped', () async {
    final repo = FakeLearning();
    final pending = Completer<ProgressResult>();
    repo.write = (_, position, duration) => pending.future;
    final c = LearningController(repo, 'course');
    await c.load();
    final one = c.save('a', 200, 100);
    final two = c.save('b', -4, 100);
    await Future<void>.delayed(Duration.zero);
    expect(repo.saved, [('a', 100, 100)]);
    pending.complete(
      const ProgressResult(lessonCompleted: false, courseProgress: 20),
    );
    await Future.wait([one, two]);
    expect(repo.saved, [('a', 100, 100), ('b', 0, 100)]);
    c.dispose();
  });
  test(
    'finishing a request after disposal does not notify a dead screen',
    () async {
      final repo = FakeLearning();
      final pending = Completer<Lesson>();
      repo.readLesson = (_) => pending.future;
      final c = LearningController(repo, 'course');
      final load = c.load();
      await Future<void>.delayed(Duration.zero);
      c.dispose();
      pending.complete(makeLesson('b'));
      await load;
      expect(c.current, isNull);
    },
  );
  testWidgets('learning shows actual API failure, retries to an empty course', (
    tester,
  ) async {
    final repo = FakeLearning()..readOverview = (() async => throw offline);
    await tester.pumpWidget(
      MaterialApp(
        home: LearningSpaceScreen(
          course: Course.fromJson({'id': 'course', 'title': 'Course'}),
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mất kết nối'), findsOneWidget);
    repo.readOverview = () async => makeOverview(empty: true);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Khóa học chưa có bài giảng'), findsOneWidget);
    expect(find.text('Lesson a'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('lesson UI keeps server review gate and handles missing video', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeLearning();
    await tester.pumpWidget(
      MaterialApp(
        home: LearningSpaceScreen(
          course: Course.fromJson({'id': 'course', 'title': 'Course'}),
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tải được video bài học'), findsOneWidget);
    expect(find.text('Đánh giá 5★'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Đánh giá'), findsNothing);
    expect(find.text('Hỏi đáp Q&A'), findsNothing);
    expect(find.text('Ghi chú'), findsOneWidget);
    expect(find.text('Lesson b'), findsWidgets);
    await tester.tap(find.text('Tài liệu'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có tài liệu'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'review stays open on API failure and cannot submit twice while pending',
    (tester) async {
      final pending = Completer<void>();
      int calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatingDialog(
              course: Course.fromJson({'id': 'course', 'title': 'Course'}),
              onSubmit: (_, comment) {
                calls++;
                return pending.future;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.star_border_rounded).last);
      await tester.tap(find.text('Gửi đánh giá'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(calls, 1);
      pending.completeError(offline);
      await tester.pumpAndSettle();
      expect(find.text('Mất kết nối'), findsOneWidget);
      expect(find.text('Gửi đánh giá'), findsOneWidget);
    },
  );
}
