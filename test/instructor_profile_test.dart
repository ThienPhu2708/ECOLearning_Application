import 'package:dio/dio.dart';
import 'package:ecolearning_app/core/config/api_config.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/models/instructor_profile.dart';
import 'package:ecolearning_app/data/repositories/course_repository.dart';
import 'package:ecolearning_app/data/repositories/instructor_repository.dart';
import 'package:ecolearning_app/presentation/screens/instructor/instructor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'api_learning_contract_test.dart' show Transport;

final profileJson = <String, dynamic>{
  'id': 59,
  'fullName': 'Trần Minh Khoa',
  'avatarUrl': '',
  'specialty': 'Lập trình .NET, C#, ASP.NET MVC',
  'experience': 'Kinh nghiệm giảng dạy thực tế',
  'coursesCount': 7,
  'studentsCount': 15,
  'rating': 4.5,
  'reviewCount': 11,
  'courses': [
    {
      'id': 'c1',
      'title': 'Khóa học 1',
      'instructor': 'Trần Minh Khoa',
      'reviewCount': 2,
      'rating': 4.5,
    },
  ],
};

class FakeInstructor extends InstructorRepository {
  String? requestedId;
  bool fail = false;
  @override
  Future<InstructorProfile> profile(String id) async {
    requestedId = id;
    if (fail) throw StateError('offline');
    return InstructorProfile.fromJson(profileJson);
  }
}

class FakeCourse extends CourseRepository {
  int detailCalls = 0;
  final reviewPages = <int>[];
  @override
  Future<Course> detail(String courseId) async {
    detailCalls++;
    return Course.fromJson({
      'id': courseId,
      'instructorInfo': {'id': 59},
    });
  }

  @override
  Future<Map<String, dynamic>> reviews(
    String courseId, {
    int? stars,
    int page = 1,
  }) async {
    reviewPages.add(page);
    return {
      'page': page,
      'totalPages': 2,
      'items': [
        {
          'userName': 'Học viên $page',
          'rating': 5,
          'comment': 'Nhận xét $page',
        },
      ],
    };
  }
}

void main() {
  test(
    'teacher endpoint parses profile independently from course totals',
    () async {
      final transport = Transport()..data = profileJson;
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = transport;
      final result = await InstructorRepository(
        client: ApiClient(dio: dio, tokenProvider: () => 'token'),
      ).profile('59');
      expect(transport.calls.single.path, '/teachers/59');
      expect(transport.calls.single.headers['Authorization'], 'Bearer token');
      expect(result.coursesCount, 7);
      expect(result.studentsCount, 15);
      expect(result.reviewCount, 11);
      expect(result.rating, 4.5);
      expect(result.experience, 'Kinh nghiệm giảng dạy thực tế');
    },
  );

  testWidgets(
    'teacher profile displays server statistics and paginated reviews',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2700);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final teachers = FakeInstructor();
      final courses = FakeCourse();
      await tester.pumpWidget(
        MaterialApp(
          home: InstructorScreen(
            course: Course.fromJson({
              'id': 'c1',
              'instructor': 'Trần Minh Khoa',
            }),
            instructorRepository: teachers,
            courseRepository: courses,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(courses.detailCalls, 1);
      expect(teachers.requestedId, '59');
      expect(courses.reviewPages, [1, 2]);
      expect(find.text('Lập trình .NET, C#, ASP.NET MVC'), findsOneWidget);
      expect(find.text('Kinh nghiệm giảng dạy thực tế'), findsOneWidget);
      expect(find.text('15 học viên'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      await tester.tap(find.text('Lượt đánh giá'));
      await tester.pumpAndSettle();
      expect(find.text('Nhận xét 1'), findsOneWidget);
      expect(find.text('Nhận xét 2'), findsOneWidget);
    },
  );

  testWidgets(
    'profile errors allow retry and do not claim introduction is absent',
    (tester) async {
      final teachers = FakeInstructor()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: InstructorScreen(
            course: Course.fromJson({
              'instructorInfo': {'id': 59},
            }),
            instructorRepository: teachers,
            courseRepository: FakeCourse(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Giảng viên chưa cập nhật lời giới thiệu.'),
        findsNothing,
      );
      expect(find.text('Thử lại'), findsOneWidget);
      teachers.fail = false;
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Kinh nghiệm giảng dạy thực tế'), findsOneWidget);
    },
  );
}
