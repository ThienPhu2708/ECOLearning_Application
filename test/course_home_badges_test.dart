import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/models/home_feed.dart';
import 'package:ecolearning_app/presentation/widgets/course_card.dart';
import 'package:ecolearning_app/presentation/widgets/home_feed_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home badge overlays image and note remains below card', (
    tester,
  ) async {
    final section = HomeSection.fromJson({
      'key': 'top-rated',
      'type': 'courses',
      'title': 'Khóa học đánh giá cao',
      'items': [
        {
          'id': '1',
          'title': 'Khóa học',
          'badge': 'Đánh giá cao',
          'tag': 'Đánh giá cao',
          'note': 'Ghi chú',
        },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeCourseRail(section: section, onTap: (_) {}),
        ),
      ),
    );
    expect(find.text('Đánh giá cao'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Đánh giá cao')).dy,
      lessThan(tester.getTopLeft(find.text('Khóa học')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Ghi chú')).dy,
      greaterThan(tester.getBottomLeft(find.byType(CourseCard)).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'multiple labels and compact personal badge fit without overflow',
    (tester) async {
      final course = Course.fromJson({
        'id': '1',
        'title': 'Khóa học',
        'tag': 'Mới',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CourseCard(
                  course: course,
                  badges: const ['Mới', 'Đánh giá cao'],
                  onTap: () {},
                ),
                CourseCard(
                  course: course,
                  badges: const ['Phù hợp với bạn'],
                  layout: CourseCardLayout.listHorizontal,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Mới'), findsOneWidget);
      expect(find.text('Đánh giá cao'), findsOneWidget);
      expect(find.text('Phù hợp với bạn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
