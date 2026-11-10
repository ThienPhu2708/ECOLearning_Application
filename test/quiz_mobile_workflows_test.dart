import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/core/config/api_config.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'package:ecolearning_app/data/repositories/learning_repository.dart';
import 'package:ecolearning_app/presentation/screens/quiz/quiz_controller.dart';
import 'package:ecolearning_app/presentation/screens/quiz/quiz_result_screen.dart';
import 'package:ecolearning_app/presentation/screens/quiz/quiz_support_screen.dart';
import 'package:ecolearning_app/presentation/screens/quiz/quiz_skills_card.dart';
import 'api_learning_contract_test.dart' show Transport;

Map<String, dynamic> attempt() => {
  'attemptId': 42,
  'supportsQuizReview': true,
  'expiresAt': DateTime.now()
      .add(const Duration(minutes: 10))
      .toIso8601String(),
  'questions': [
    {
      'index': 0,
      'questionId': 99,
      'text': 'Question?',
      'options': ['A', 'B', 'C', 'D'],
    },
  ],
  'answers': [-1],
};

class TrackingQuiz extends QuizRepository {
  final events = <(String, bool)>[];
  final operations = <String>[];
  bool fail = false, active = true;
  @override
  Future<int> visibility(int id, String key, {required bool returned}) async {
    if (fail) throw const ApiException(code: 'NETWORK', message: 'Offline');
    events.add((key, returned));
    operations.add('visibility');
    return events.where((e) => !e.$2).map((e) => e.$1).toSet().length;
  }

  @override
  Future<Map<String, dynamic>> checkWriter(int id) async => {
    'active': active,
    'finished': false,
  };
  @override
  Future<bool> saveDraft(int id, List<int> answers) async => true;
  @override
  Future<Map<String, dynamic>> submit(int id, List<int> answers) async {
    operations.add('submit');
    return {'pendingReview': true, 'passed': false};
  }

  @override
  Future<Map<String, dynamic>> support(String id) async => {
    'canAppeal': false,
    'appeals': [
      {
        'attemptId': 42,
        'content': 'Please check question 1',
        'status': 'Answered',
        'replies': [
          {'teacherName': 'Teacher', 'content': 'Checked your answer.'},
        ],
      },
    ],
  };
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test(
    'retake start installs writer token for visibility, save and submit',
    () async {
      final t = Transport()
        ..data = {'attemptId': 42, 'writerToken': 'retake-writer'};
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = t;
      final repo = QuizRepository(
        client: ApiClient(dio: dio, tokenProvider: () => 'token'),
      );
      await repo.startRetake('course', 7);
      expect(t.calls.last.path, '/courses/course/quiz/retakes/7/start');
      expect((t.calls.last.data as Map)['takeover'], false);
      t.data = {'count': 3};
      expect(await repo.visibility(42, 'a' * 32, returned: false), 3);
      expect((t.calls.last.data as Map)['writerToken'], 'retake-writer');
      t.data = {'saved': true};
      await repo.saveDraft(42, [2]);
      expect((t.calls.last.data as Map)['writerToken'], 'retake-writer');
      t.data = {'score': 9};
      await repo.submit(42, [2]);
      expect((t.calls.last.data as Map)['writerToken'], 'retake-writer');
    },
  );
  test(
    'reports use server question IDs and appeals target selected attempt',
    () async {
      final t = Transport()..data = {'sent': true};
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = t;
      final repo = QuizRepository(
        client: ApiClient(dio: dio, tokenProvider: () => 'token'),
      );
      await repo.report(42, 99, 'Đáp án có vẻ sai', 'Please check');
      expect(t.calls.last.path, '/quiz-attempts/42/reports');
      expect((t.calls.last.data as Map)['questionId'], 99);
      await repo.appeal('course', 42, 'Check attempt');
      expect(t.calls.last.path, '/courses/course/quiz/appeals');
      expect((t.calls.last.data as Map)['attemptId'], 42);
      t.data = [];
      await repo.history('course');
      expect(t.calls.last.path, '/courses/course/quiz/history');
    },
  );
  test(
    'inactive and paused callbacks count one departure and pair the return',
    () async {
      final r = TrackingQuiz();
      final q = QuizController(r, attempt());
      q.depart();
      q.depart();
      await q.flushVisibility();
      expect(r.events.length, 1);
      q.resume();
      await q.flushVisibility();
      expect(r.events.length, 2);
      expect(r.events[0].$1, r.events[1].$1);
      expect(r.events[1].$2, true);
      expect(q.departures, 1);
      q.dispose();
    },
  );
  test('failed departure telemetry is retried before submission', () async {
    final r = TrackingQuiz()..fail = true;
    final q = QuizController(r, attempt());
    q.depart();
    await q.flushVisibility();
    await q.submit();
    expect(q.result, isNull);
    expect(r.operations, isNot(contains('submit')));
    expect(q.submitError, isNotNull);
    r.fail = false;
    await q.submit();
    expect(r.operations, ['visibility', 'submit']);
    expect(q.result!['pendingReview'], true);
    q.dispose();
  });
  test(
    'resume records the matching return for an open server departure',
    () async {
      final r = TrackingQuiz();
      final q = QuizController(
        r,
        attempt()
          ..['openDepartureKey'] = 'b' * 32
          ..['departureCount'] = 2,
      );
      q.resume();
      await q.flushVisibility();
      expect(r.events.single, ('b' * 32, true));
      q.dispose();
    },
  );
  test(
    'lost writer disables edits and does not submit from stale session',
    () async {
      final r = TrackingQuiz()..active = false;
      final q = QuizController(r, attempt());
      await q.checkSession();
      expect(q.sessionLost, true);
      q.choose(0, 2);
      await q.submit();
      expect(q.answers, [-1]);
      expect(r.operations, isEmpty);
      q.dispose();
    },
  );
  testWidgets(
    'pending result never displays pass or certificate claim even with stale passed flag',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizResultScreen(
            courseId: 'c',
            result: {
              'pendingReview': true,
              'passed': true,
              'total': 10,
              'passPercent': 80,
            },
          ),
        ),
      );
      expect(find.text('Chờ giáo viên xem xét'), findsOneWidget);
      expect(find.text('Nhận chứng chỉ'), findsNothing);
      expect(find.text('Bạn đã đạt bài quiz'), findsNothing);
      expect(find.text('— /10'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('voided result cannot claim certificate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuizResultScreen(
          courseId: 'c',
          result: {'isVoided': true, 'passed': true, 'score': 10},
        ),
      ),
    );
    expect(find.text('Kết quả hết hiệu lực'), findsOneWidget);
    expect(find.text('Nhận chứng chỉ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'used appeal shows teacher response without another submit button',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizSupportScreen(
            courseId: 'c',
            repository: TrackingQuiz(),
            initialTab: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Checked your answer.'), findsOneWidget);
      expect(find.text('Gửi phúc khảo'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('skill requirements fit a narrow phone with long skill names', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizSkillsCard(
            results: true,
            skills: [
              {
                'name': 'Kỹ năng biến và kiểu dữ liệu rất dài cần xuống dòng',
                'total': 3,
                'correct': 2,
                'passPercent': 60,
                'required': true,
                'passed': true,
              },
            ],
          ),
        ),
      ),
    );
    expect(find.textContaining('Bắt buộc'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'history resume targets only an existing attempt and preserves writer token',
    () async {
      final t = Transport()
        ..data = {'attemptId': 42, 'writerToken': 'resume-token'};
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = t;
      final repo = QuizRepository(
        client: ApiClient(dio: dio, tokenProvider: () => 'token'),
      );
      await repo.resume(42);
      expect(t.calls.last.path, '/quiz-attempts/42/resume');
      expect((t.calls.last.data as Map)['takeover'], false);
      t.data = {'saved': true};
      await repo.saveDraft(42, [1]);
      expect((t.calls.last.data as Map)['writerToken'], 'resume-token');
    },
  );

  test(
    'older two-tab API is partitioned from real issued-certificate flags',
    () async {
      final t = Transport()
        ..data = {
          'items': [
            {'id': 'issued', 'progress': 100, 'hasCertificate': true},
            {'id': 'waiting', 'progress': 100, 'hasCertificate': false},
          ],
          'page': 1,
          'pageSize': 12,
          'total': 2,
          'totalPages': 1,
          'counts': {'inProgress': 0, 'completed': 2},
        };
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = t;
      final repo = LearningRepository(
        client: ApiClient(dio: dio, tokenProvider: () => 'token'),
      );
      final certified = await repo.myCourses(status: MyCourseStatus.certified);
      final completed = await repo.myCourses(status: MyCourseStatus.completed);
      expect(certified.items.map((c) => c.id), ['issued']);
      expect(certified.total, 1);
      expect(completed.items.map((c) => c.id), ['waiting']);
      expect(completed.total, 1);
    },
  );
}
