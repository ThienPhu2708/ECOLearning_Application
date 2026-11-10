import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/learning_repository.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'package:ecolearning_app/data/repositories/course_repository.dart';
import 'package:ecolearning_app/presentation/screens/my_courses/my_courses_screen.dart';
import 'package:ecolearning_app/presentation/screens/my_courses/certificate_screen.dart';
import 'package:ecolearning_app/presentation/screens/learning/rating_dialog.dart';

class Owned extends LearningRepository {
  final course = Course.fromJson({
    'id': 'c',
    'title': 'C#',
    'hasCertificate': true,
    'progress': 50,
    'myReview': {'rating': 4, 'comment': 'Hữu ích'},
  });
  @override
  Future<PagedResult<Course>> myCourses({
    String status = MyCourseStatus.inProgress,
    int page = 1,
  }) async => status == MyCourseStatus.certified
      ? PagedResult(
          items: [course],
          page: 1,
          pageSize: 12,
          total: 1,
          totalPages: 1,
        )
      : const PagedResult.empty();
}

class Quiz extends QuizRepository {
  int claims = 0, starts = 0, reads = 0;
  @override
  Future<Map<String, dynamic>> certificate(String id) async {
    reads++;
    return {'code': 'CERT-EXISTING', 'courseTitle': 'C#'};
  }

  @override
  Future<Map<String, dynamic>> claimCertificate(String id) async {
    claims++;
    throw Exception('Do not claim again');
  }

  @override
  Future<Map<String, dynamic>> start(String id) async {
    starts++;
    throw Exception('Do not start');
  }

  @override
  Future<Map<String, dynamic>> info(String id) async => {
    'lastResult': {
      'passed': true,
      'score': 9,
      'correct': 9,
      'total': 10,
      'passPercent': 80,
    },
  };
}

class Details extends CourseRepository {
  @override
  Future<Course> detail(String id) async => Course.fromJson({
    'id': id,
    'title': 'C#',
    'canReview': true,
    'myReview': {'rating': 4, 'comment': 'Hữu ích'},
  });
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  Future<void> open(
    WidgetTester tester,
    Quiz quiz, {
    Future<void> Function(Course)? learn,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MyCoursesScreen(
          repository: Owned(),
          quizRepository: quiz,
          courseRepository: Details(),
          onOpenLearning: learn,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đã nhận chứng chỉ (1)'));
    await tester.tap(find.text('Đã nhận chứng chỉ (1)'));
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, String action) async {
    await tester.ensureVisible(find.byTooltip('Thao tác khóa học'));
    await tester.tap(find.byTooltip('Thao tác khóa học'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'certificate button views existing certificate without reissue or review prompt',
    (tester) async {
      final quiz = Quiz();
      await open(tester, quiz);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('50%'), findsNothing);
      expect(find.text('Xem lại bài học'), findsNothing);
      expect(find.text('Xem chứng chỉ'), findsOneWidget);
      await tester.ensureVisible(find.text('Xem chứng chỉ'));
      await tester.tap(find.text('Xem chứng chỉ'));
      await tester.pumpAndSettle();
      expect(find.byType(CertificateScreen), findsOneWidget);
      expect(find.byType(RatingDialog), findsNothing);
      expect(quiz.reads, 1);
      expect(quiz.claims, 0);
    },
  );
  testWidgets(
    'menu keeps lessons and results accessible without starting another quiz',
    (tester) async {
      final quiz = Quiz();
      int opens = 0;
      await open(
        tester,
        quiz,
        learn: (_) async {
          opens++;
        },
      );
      await menu(tester, 'Xem lại bài học');
      expect(opens, 1);
      await menu(tester, 'Kết quả quiz');
      expect(find.text('9.0/10'), findsOneWidget);
      expect(find.text('Nhận chứng chỉ'), findsNothing);
      expect(quiz.starts, 0);
      expect(quiz.claims, 0);
    },
  );
  testWidgets('existing review opens with selected rating and old comment', (
    tester,
  ) async {
    await open(tester, Quiz());
    await menu(tester, 'Đánh giá của tôi');
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text('Hữu ích'), findsOneWidget);
    expect(find.text('4/5 ★'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Sửa đánh giá'));
    await tester.pumpAndSettle();
    expect(find.byType(RatingDialog), findsOneWidget);
    expect(find.text('Hữu ích'), findsOneWidget);
    expect(find.textContaining('4 / 5 sao'), findsOneWidget);
  });
  testWidgets('certified card fits a small phone with larger text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, Quiz());
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
