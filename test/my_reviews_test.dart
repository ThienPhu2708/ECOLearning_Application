import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/learning_repository.dart';
import 'package:ecolearning_app/data/repositories/course_repository.dart';
import 'package:ecolearning_app/presentation/screens/profile/my_reviews_screen.dart';
import 'package:ecolearning_app/presentation/screens/learning/rating_dialog.dart';

class Owned extends LearningRepository {
  final calls = <int>[];
  @override
  Future<PagedResult<Course>> myCourses({
    String status = MyCourseStatus.inProgress,
    int page = 1,
  }) async {
    if (status == MyCourseStatus.inProgress) return const PagedResult.empty();
    calls.add(page);
    return PagedResult(
      items: [
        Course.fromJson({'id': '$page'}),
      ],
      page: page,
      pageSize: 1,
      total: 3,
      totalPages: 3,
    );
  }
}

class Details extends CourseRepository {
  @override
  Future<Course> detail(String id) async => Course.fromJson({
    'id': id,
    'title': id == '1'
        ? 'Đã gửi'
        : id == '2'
        ? 'Chờ đánh giá'
        : 'Chưa đủ điều kiện',
    'canReview': id != '3',
    if (id == '1') 'myReview': {'rating': 4, 'comment': 'Dễ hiểu'},
  });
}

void main() {
  testWidgets(
    'review tabs read all owned pages and view an existing review without reopening the form',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    GoogleFonts.config.allowRuntimeFetching = false;
      final owned = Owned();
      await tester.pumpWidget(
        MaterialApp(
          home: MyReviewsScreen(learning: owned, courses: Details()),
        ),
      );
      await tester.pumpAndSettle();
      expect(owned.calls, [1, 2, 3]);
      expect(find.text('Đã đánh giá (1)'), findsOneWidget);
      expect(find.text('Chưa đánh giá (1)'), findsOneWidget);
      expect(find.text('Dễ hiểu'), findsNothing);
      await tester.tap(find.text('Xem đánh giá'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(RatingDialog), findsNothing);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chưa đánh giá (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Chờ đánh giá'), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Viết đánh giá'),
      );
      expect(button.onPressed, isNotNull);
      expect(find.text('Chưa đủ điều kiện'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
