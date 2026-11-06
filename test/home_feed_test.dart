import 'package:ecolearning_app/data/models/home_feed.dart';
import 'package:ecolearning_app/presentation/widgets/home_feed_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _course(String id, String title) => {
  'badge': 'Bán chạy',
  'note': '3 lượt đăng ký tuần này',
  'id': id,
  'title': title,
  'categoryId': 'DM01',
  'category': 'Lập trình Web & CNTT',
  'instructor': 'Trần Minh Khoa',
  'imageUrl': '',
  'level': 'Cơ bản',
  'rating': 4.5,
  'reviewCount': 4,
  'price': 899000,
  'originalPrice': 899000,
};

final _json = {
  'isPersonalized': true,
  'sections': [
    {
      'key': 'continue-learning',
      'type': 'continue',
      'title': 'Tiếp tục học',
      'subtitle': 'Học tiếp đúng bài bạn đang xem',
      'items': [
        {
          'courseId': 'DMKH12',
          'title': 'JavaScript ES6 hiện đại',
          'imageUrl': '',
          'instructor': 'Trần Minh Khoa',
          'progress': 20,
          'completedLessons': 1,
          'totalLessons': 5,
          'lessonTitle': 'Biến và kiểu dữ liệu',
          'lessonId': 'lesson-2',
          'positionSeconds': 75,
          'lessonNumber': 2,
          'isStarted': true,
        },
      ],
    },
    {
      'key': 'best-sellers',
      'type': 'courses',
      'title': 'Bán chạy tuần này',
      'subtitle': 'Xếp theo lượt đăng ký mới trong 7 ngày qua',
      'items': [_course('A', 'Nhập môn lập trình'), _course('B', 'SQL Server')],
    },
    {
      'key': 'featured-teachers',
      'type': 'teachers',
      'title': 'Giáo viên nổi bật',
      'subtitle': '',
      'items': [
        {
          'id': 59,
          'fullName': 'Trần Minh Khoa',
          'avatarUrl': '',
          'specialty': 'Lập trình Web & CNTT',
          'coursesCount': 7,
          'studentsCount': 29,
        },
      ],
    },
    {
      'key': 'recently-viewed',
      'type': 'courses',
      'title': 'Đã xem gần đây',
      'subtitle': '',
      'items': [],
    },
  ],
};

void main() {
  test('đọc /home: tiếp tục học, khóa học có nhãn, giáo viên; bỏ mục rỗng', () {
    final feed = HomeFeed.fromJson(_json);
    expect(feed.isPersonalized, isTrue);
    expect(feed.section('recently-viewed'), isNull); // mục rỗng bị bỏ

    final cont = feed.section('continue-learning')!.continues.single;
    expect(cont.progress, 20);
    expect(cont.lessonNumber, 2);
    expect(cont.toCourse().id, 'DMKH12');
    expect(cont.toCourse().lastLessonId, 'lesson-2');
    expect(cont.positionSeconds, 75);

    final best = feed.section('best-sellers')!.courses;
    expect(best.map((c) => c.course.id), ['A', 'B']);
    expect(best.first.badge, 'Bán chạy');
    expect(best.first.note, '3 lượt đăng ký tuần này');

    final teacher = feed.section('featured-teachers')!.teachers.single;
    expect(teacher.id, '59');
    expect(teacher.toCourse().instructor, 'Trần Minh Khoa');
  });

  testWidgets('các mục Trang chủ hiển thị không tràn ở màn hình hẹp', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final feed = HomeFeed.fromJson(_json);
    HomeContinueItem? opened;
    String? tapped;

    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                HomeContinueSection(
                  section: feed.section('continue-learning')!,
                  onOpen: (i) => opened = i,
                ),
                HomeCourseRail(
                  section: feed.section('best-sellers')!,
                  onTap: (c) => tapped = c.id,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tiếp tục học'), findsOneWidget);
    expect(find.text('Bài 2: Biến và kiểu dữ liệu'), findsOneWidget);
    expect(find.text('20% hoàn thành'), findsOneWidget);
    expect(find.text('Bán chạy tuần này'), findsOneWidget);
    expect(find.text('Bán chạy'), findsWidgets);

    await t.tap(find.text('JavaScript ES6 hiện đại'));
    expect(opened?.courseId, 'DMKH12');
    await t.tap(find.text('Nhập môn lập trình'));
    expect(tapped, 'A');
  });
}
