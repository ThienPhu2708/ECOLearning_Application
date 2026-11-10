import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/course_repository.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'package:ecolearning_app/data/repositories/review_repository.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/presentation/screens/quiz/quiz_result_screen.dart';
import 'package:ecolearning_app/presentation/screens/learning/rating_dialog.dart';
import 'package:ecolearning_app/presentation/screens/my_courses/certificate_screen.dart';

class Claims extends QuizRepository {
  bool fail = false;
  int count = 0;
  @override
  Future<Map<String, dynamic>> claimCertificate(String courseId) async {
    count++;
    if (fail) throw const ApiException(message: 'Chưa nhận được chứng chỉ.');
    return {
      'code': 'CERT-X',
      'courseTitle': 'C#',
      'studentName': 'Ngọc',
      'issuedAt': '2026-10-21',
    };
  }
}

class Courses extends CourseRepository {
  final course = Course.fromJson({
    'id': 'c',
    'title': 'C#',
    'progress': 100,
    'canReview': true,
  });
  @override
  Future<Course> detail(String courseId) async => course;
}

class Reviews extends ReviewRepository {
  final Courses courses;
  Reviews(this.courses);
  int count = 0;
  bool fail = false;
  @override
  Future<Map<String, dynamic>> submit(
    String courseId, {
    required int rating,
    String? comment,
  }) async {
    count++;
    if (fail) throw const ApiException(message: 'Chưa gửi được đánh giá.');
    expect(rating, 5);
    expect(comment, 'Rất hữu ích');
    courses.course.myReviewRating = rating.toDouble();
    return {'rating': rating, 'comment': comment};
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  Future<void> open(
    WidgetTester tester,
    Claims claims,
    Courses courses,
    Reviews reviews,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: QuizResultScreen(
          courseId: 'c',
          result: const {
            'passed': true,
            'score': 8,
            'correct': 8,
            'total': 10,
            'passPercent': 80,
          },
          repository: claims,
          courses: courses,
          reviews: reviews,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> claim(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Nhận chứng chỉ'));
    await tester.tap(find.text('Nhận chứng chỉ'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'successful claim opens optional review over certificate and skips it after reviewed',
    (tester) async {
      final claims = Claims();
      final courses = Courses();
      final reviews = Reviews(courses);
      await open(tester, claims, courses, reviews);
      await claim(tester);
      expect(find.byType(CertificateScreen), findsOneWidget);
      expect(find.byType(RatingDialog), findsOneWidget);
      await tester.tap(find.text('Gửi đánh giá'));
      await tester.pumpAndSettle();
      expect(
        find.text('Vui lòng chọn số sao đánh giá (1 - 5 sao)'),
        findsOneWidget,
      );
      expect(reviews.count, 0);
      await tester.tap(find.byIcon(Icons.star_border_rounded).last);
      await tester.enterText(find.byType(TextField), 'Rất hữu ích');
      await tester.ensureVisible(find.text('Gửi đánh giá'));
      await tester.tap(find.text('Gửi đánh giá'));
      await tester.pumpAndSettle();
      expect(reviews.count, 1);
      expect(find.byType(RatingDialog), findsNothing);
      expect(find.byType(CertificateScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await claim(tester);
      expect(find.byType(RatingDialog), findsNothing);
    },
  );
  testWidgets('defer leaves certificate available without posting review', (
    tester,
  ) async {
    final claims = Claims();
    final courses = Courses();
    final reviews = Reviews(courses);
    await open(tester, claims, courses, reviews);
    await claim(tester);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.byType(CertificateScreen), findsOneWidget);
    expect(reviews.count, 0);
    expect(claims.count, 1);
  });
  testWidgets('failed claim never opens certificate or review', (tester) async {
    final claims = Claims()..fail = true;
    final courses = Courses();
    final reviews = Reviews(courses);
    await open(tester, claims, courses, reviews);
    await claim(tester);
    expect(find.byType(CertificateScreen), findsNothing);
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text('Chưa nhận được chứng chỉ.'), findsOneWidget);
  });
  testWidgets(
    'review submission failure retains selected stars, comment and issued certificate',
    (tester) async {
      final claims = Claims();
      final courses = Courses();
      final reviews = Reviews(courses)..fail = true;
      await open(tester, claims, courses, reviews);
      await claim(tester);
      await tester.tap(find.byIcon(Icons.star_border_rounded).last);
      await tester.enterText(find.byType(TextField), 'Rất hữu ích');
      await tester.ensureVisible(find.text('Gửi đánh giá'));
      await tester.tap(find.text('Gửi đánh giá'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa gửi được đánh giá.'), findsOneWidget);
      expect(find.text('Rất hữu ích'), findsOneWidget);
      expect(find.byType(CertificateScreen), findsOneWidget);
      expect(find.byType(RatingDialog), findsOneWidget);
      expect(claims.count, 1);
    },
  );
}
