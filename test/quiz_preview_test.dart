import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'fixtures/learning_preview_app.dart';
import 'package:ecolearning_app/presentation/screens/quiz/quiz_controller.dart';
import 'package:ecolearning_app/presentation/screens/quiz/quiz_take_screen.dart';
import 'package:ecolearning_app/presentation/screens/quiz/quiz_intro_screen.dart';
import 'package:ecolearning_app/presentation/screens/quiz/quiz_result_screen.dart';
import 'fixtures/preview_repositories.dart';

Map<String, dynamic> attempt(DateTime expires) => {
  'attemptId': 42,
  'expiresAt': expires.toIso8601String(),
  'questions': [
    for (int i = 0; i < 2; i++)
      {
        'index': i,
        'text': 'Question $i',
        'options': ['A', 'B', 'C', 'D'],
      },
  ],
  'answers': [-1, 3],
};

class FakeQuiz extends QuizRepository {
  int submits = 0;
  final drafts = <List<int>>[];
  Future<bool> Function(List<int>) draftReply = (_) async => true;
  Future<Map<String, dynamic>> Function(List<int>) submitReply = (_) async => {
    'score': 5,
    'correct': 1,
    'total': 2,
    'passed': false,
    'passPercent': 80,
  };
  @override
  Future<bool> saveDraft(int attemptId, List<int> answers) {
    drafts.add(List.of(answers));
    return draftReply(answers);
  }

  @override
  Future<Map<String, dynamic>> submit(int attemptId, List<int> answers) {
    submits++;
    return submitReply(answers);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test(
    'drafts serialize immutable answer snapshots and preserve resumed answers',
    () async {
      final repo = FakeQuiz();
      final now = DateTime(2026, 10, 20);
      final c = QuizController(
        repo,
        attempt(now.add(const Duration(minutes: 30))),
        now: () => now,
      );
      expect(c.answers, [-1, 3]);
      expect(c.answered, 1);
      c.choose(0, 1);
      c.choose(0, 2);
      await c.saveDraft();
      expect(repo.drafts.first, [1, 3]);
      expect(repo.drafts.last, [2, 3]);
      expect(c.dirty, false);
      c.dispose();
    },
  );
  test('failed drafts remain dirty and retry latest answers', () async {
    final repo = FakeQuiz()
      ..draftReply = ((_) async =>
          throw const ApiException(message: 'Offline'));
    final c = QuizController(
      repo,
      attempt(DateTime.now().add(const Duration(minutes: 30))),
    );
    c.choose(0, 2);
    await c.saveDraft();
    expect(c.dirty, true);
    expect(c.draftError, isNotNull);
    repo.draftReply = (_) async => true;
    await c.saveDraft();
    expect(c.dirty, false);
    expect(c.draftError, isNull);
    c.dispose();
  });
  test(
    'expiry blocks answers and auto submits once even when server fails',
    () async {
      var now = DateTime(2026, 10, 20);
      final repo = FakeQuiz()
        ..submitReply = ((_) async =>
            throw const ApiException(message: 'Offline'));
      final c = QuizController(
        repo,
        attempt(now.add(const Duration(seconds: 5))),
        now: () => now,
      );
      now = now.add(const Duration(seconds: 6));
      c.tick();
      await Future<void>.delayed(Duration.zero);
      c.tick();
      expect(repo.submits, 1);
      expect(c.submitError, isNotNull);
      c.choose(0, 0);
      expect(c.answers.first, -1);
      repo.submitReply = (_) async => {'passed': false};
      await c.submit();
      expect(repo.submits, 2);
      expect(c.result, isNotNull);
      c.dispose();
    },
  );
  test('submit waits for draft and ignores repeated taps', () async {
    final repo = FakeQuiz();
    final pending = Completer<bool>();
    repo.draftReply = (_) => pending.future;
    final c = QuizController(
      repo,
      attempt(DateTime.now().add(const Duration(minutes: 30))),
    );
    c.choose(0, 1);
    final submit = c.submit();
    await c.submit();
    expect(repo.submits, 0);
    pending.complete(true);
    await submit;
    expect(repo.submits, 1);
    c.dispose();
  });
  test(
    'expired draft response can trigger submit without deadlocking',
    () async {
      final repo = FakeQuiz()..draftReply = ((_) async => false);
      final c = QuizController(
        repo,
        attempt(DateTime.now().add(const Duration(minutes: 30))),
      );
      c.choose(0, 1);
      await c.saveDraft();
      await Future<void>.delayed(Duration.zero);
      expect(repo.submits, 1);
      expect(c.result, isNotNull);
      c.dispose();
    },
  );
  test('invalid attempt does not silently create an empty quiz', () {
    expect(() => QuizController(FakeQuiz(), {}), throwsFormatException);
  });
  test(
    'sample quiz resumes, grades, and issues one stable certificate after pass',
    () async {
      final repo = PreviewQuizRepository();
      final first = await repo.start('sample');
      await repo.saveDraft(
        first['attemptId'] as int,
        List.generate(10, (i) => i % 4),
      );
      final resumed = await repo.start('sample');
      expect(resumed['attemptId'], first['attemptId']);
      expect(resumed['answers'], List.generate(10, (i) => i % 4));
      final result = await repo.submit(
        first['attemptId'] as int,
        List.generate(10, (i) => i % 4),
      );
      expect(result['passed'], true);
      expect((await repo.info('sample'))['canStart'], false);
      final cert = await repo.claimCertificate('sample');
      expect(await repo.claimCertificate('sample'), cert);
      expect(await repo.certificates(), hasLength(1));
    },
  );
  testWidgets(
    'quiz numbers scroll to the question and selected answers change the navigator',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeQuiz();
      await tester.pumpWidget(
        MaterialApp(
          home: QuizTakeScreen(
            courseId: 'sample',
            attempt: attempt(DateTime.now().add(const Duration(minutes: 30))),
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('A. A').first);
      await tester.pumpAndSettle();
      expect(repo.drafts.last, [0, 3]);
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Question 1')).top, greaterThan(200));
      expect(tester.getRect(find.text('Question 1')).bottom, lessThan(800));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'automatic submit closes an open leave dialog before replacing the quiz route',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<bool>();
      final repo = FakeQuiz()..draftReply = ((_) => pending.future);
      await tester.pumpWidget(
        MaterialApp(
          home: QuizTakeScreen(
            courseId: 'sample',
            attempt: attempt(DateTime.now().add(const Duration(minutes: 30))),
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('A. A').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Tạm rời bài quiz?'), findsOneWidget);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.byType(QuizResultScreen), findsOneWidget);
      expect(find.byType(QuizTakeScreen), findsNothing);
      expect(find.text('Tạm rời bài quiz?'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'preview owned courses and completed-course quiz work without an API',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        previousErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      await tester.pumpWidget(const LearningPreviewApp());
      await tester.pumpAndSettle();
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.text('Hồ sơ'), findsOneWidget);
      expect(find.text('Bản xem thử'), findsNothing);
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Khóa học yêu thích'));
      await tester.tap(find.text('Khóa học yêu thích'));
      await tester.pumpAndSettle();
      expect(find.text('4 khóa học đã lưu'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khóa học'));
      await tester.pumpAndSettle();
      expect(find.text('Xây dựng ứng dụng với Flutter'), findsOneWidget);
      expect(find.text('Lỗi kết nối mạng'), findsNothing);
      await tester.tap(find.text('Đã học đủ bài (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Lập trình C# từ cơ bản đến nâng cao'), findsOneWidget);
      await tester.ensureVisible(find.text('Làm quiz cuối khóa'));
      await tester.tap(find.text('Làm quiz cuối khóa'));
      await tester.pumpAndSettle();
      expect(find.byType(QuizIntroScreen), findsOneWidget);
      expect(find.text('Bắt đầu quiz'), findsOneWidget);
      expect(find.text('Lỗi kết nối mạng'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'preview opens quiz and canceling confirmation does not consume an attempt',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        previousErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      await tester.pumpWidget(const LearningPreviewApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khóa học'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã học đủ bài (1)'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Làm quiz cuối khóa'));
      await tester.tap(find.text('Làm quiz cuối khóa'));
      await tester.pumpAndSettle();
      expect(find.byType(QuizIntroScreen), findsOneWidget);
      await tester.tap(find.text('Bắt đầu quiz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(find.byType(QuizTakeScreen), findsNothing);
      await tester.tap(find.text('Bắt đầu quiz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      expect(find.byType(QuizTakeScreen), findsOneWidget);
      expect(find.text('0/10'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
