import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/core/theme/app_theme.dart';
import 'package:ecolearning_app/data/models/category.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/course_repository.dart';
import 'package:ecolearning_app/presentation/screens/category/category_courses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Course _course(String id, String title) => Course(
  id: id,
  title: title,
  category: 'Y tế',
  instructor: 'GV',
  rating: 4,
  reviewCount: 1,
  price: 100000,
  originalPrice: 100000,
  imageUrl: '',
  tag: '',
  level: 'Cơ bản',
  duration: '1h',
  lessonsCount: 2,
);

/// Ghi lại tham số gọi API và trả 2 trang giả
class _FakeCourses extends CourseRepository {
  final calls = <Map<String, Object?>>[];

  @override
  Future<PagedResult<Course>> courses({
    String? q,
    String? categoryId,
    String? level,
    String? price,
    double? minRating,
    String? sort,
    bool webCatalog = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    calls.add({'categoryId': categoryId, 'sort': sort, 'page': page});
    return PagedResult<Course>(
      items: [_course('c$page', 'Khóa trang $page')],
      page: page,
      pageSize: 10,
      total: 11,
      totalPages: 2,
    );
  }
}

void main() {
  testWidgets('Danh mục hiện khóa học của danh mục và chuyển trang', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final repo = _FakeCourses();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: CategoryCoursesScreen(
          category: const Category(
            id: 'CAT-006',
            name: 'Y tế',
            icon: Icons.school,
            emoji: '',
          ),
          repository: repo,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Gọi API đúng danh mục, trang 1
    expect(repo.calls.first['categoryId'], 'CAT-006');
    expect(repo.calls.first['page'], 1);
    expect(find.text('Khóa trang 1'), findsOneWidget);

    // Bấm sang trang 2 trên thanh phân trang
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.calls.last['page'], 2);
    expect(repo.calls.last['categoryId'], 'CAT-006');
    expect(find.text('Khóa trang 2'), findsOneWidget);
  });
}
