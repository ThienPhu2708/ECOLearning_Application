import 'dart:async';

import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/learning_repository.dart';
import 'package:ecolearning_app/presentation/screens/my_courses/my_courses_controller.dart';
import 'package:ecolearning_app/presentation/screens/my_courses/my_courses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Course course(String id, {double progress = 25, bool certificate = false}) =>
    Course.fromJson({
      'id': id,
      'title': 'Khóa học $id',
      'instructor': 'Giảng viên mẫu',
      'progress': progress,
      'hasCertificate': certificate,
    });

PagedResult<Course> page(
  List<Course> items, {
  int number = 1,
  int pages = 1,
  int? total,
}) => PagedResult(
  items: items,
  page: number,
  pageSize: 12,
  total: total ?? items.length,
  totalPages: pages,
);

class FakeLearning extends LearningRepository {
  final Future<PagedResult<Course>> Function(String, int) reply;
  final calls = <(String, int)>[];
  FakeLearning(this.reply);

  @override
  Future<PagedResult<Course>> myCourses({
    String status = MyCourseStatus.inProgress,
    int page = 1,
  }) {
    calls.add((status, page));
    return reply(status, page);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
    'Two tabs paginate separately and remove duplicate course IDs',
    () async {
      final repo = FakeLearning(
        (status, number) async => status == MyCourseStatus.completed
            ? page([course('done', progress: 100)])
            : number == 1
            ? page([course('one')], pages: 2, total: 2)
            : page(
                [course('one'), course('two')],
                number: 2,
                pages: 2,
                total: 2,
              ),
      );
      final controller = MyCoursesController(repo);
      await controller.load();
      await controller.loadMore(MyCourseStatus.inProgress);
      expect(controller.ongoing.courses.map((c) => c.id), ['one', 'two']);
      expect(controller.completed.courses.single.id, 'done');
      expect(controller.ongoing.hasMore, false);
      expect(controller.completed.page, 1);
      controller.dispose();
    },
  );

  test('A failed refresh preserves courses and can retry', () async {
    var fail = false;
    final repo = FakeLearning((_, _) async {
      if (fail) throw const ApiException(message: 'Mất mạng');
      return page([course('one')]);
    });
    final controller = MyCoursesController(repo);
    await controller.refresh(MyCourseStatus.inProgress);
    fail = true;
    await controller.refresh(MyCourseStatus.inProgress);
    expect(controller.ongoing.courses.single.id, 'one');
    expect(controller.ongoing.error, isA<ApiException>());
    fail = false;
    await controller.refresh(MyCourseStatus.inProgress);
    expect(controller.ongoing.error, isNull);
    controller.dispose();
  });

  test('A stale page cannot overwrite a newer refresh', () async {
    final stale = Completer<PagedResult<Course>>();
    var first = true;
    final repo = FakeLearning((_, _) {
      if (first) {
        first = false;
        return stale.future;
      }
      return Future.value(page([course('new')]));
    });
    final controller = MyCoursesController(repo);
    final oldRequest = controller.refresh(MyCourseStatus.inProgress);
    await controller.refresh(MyCourseStatus.inProgress);
    stale.complete(page([course('old')]));
    await oldRequest;
    expect(controller.ongoing.courses.single.id, 'new');
    controller.dispose();
  });

  test('Failed next page retries the same page without losing data', () async {
    var fail = true;
    final repo = FakeLearning((_, number) async {
      if (number == 1) return page([course('one')], pages: 2, total: 2);
      if (fail) throw const ApiException(message: 'Mất mạng');
      return page([course('two')], number: 2, pages: 2, total: 2);
    });
    final controller = MyCoursesController(repo);
    await controller.refresh(MyCourseStatus.inProgress);
    await controller.loadMore(MyCourseStatus.inProgress);
    expect(controller.ongoing.page, 1);
    expect(controller.ongoing.moreError, isNotNull);
    fail = false;
    await controller.loadMore(MyCourseStatus.inProgress);
    expect(controller.ongoing.courses.length, 2);
    expect(repo.calls.last, (MyCourseStatus.inProgress, 2));
    controller.dispose();
  });

  test('In-flight requests are harmless after disposing the screen', () async {
    final pending = Completer<PagedResult<Course>>();
    final controller = MyCoursesController(
      FakeLearning((_, _) => pending.future),
    );
    final loading = controller.refresh(MyCourseStatus.inProgress);
    controller.dispose();
    pending.complete(page([course('one')]));
    await loading;
  });

  testWidgets('Loading, error and retry lead to API courses', (tester) async {
    final pending = Completer<PagedResult<Course>>();
    var failed = false;
    final repo = FakeLearning((status, _) async {
      if (status == MyCourseStatus.completed) return const PagedResult.empty();
      if (!failed) return pending.future;
      return page([course('api')]);
    });
    await tester.pumpWidget(
      MaterialApp(home: MyCoursesScreen(repository: repo)),
    );
    expect(find.text('Đang tải khóa học…'), findsOneWidget);
    pending.completeError(
      const ApiException(message: 'Không tải được khóa học'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tải được khóa học'), findsOneWidget);
    failed = true;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Khóa học api'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completed lessons do not grant a sample certificate', (
    tester,
  ) async {
    final repo = FakeLearning(
      (status, _) async => status == MyCourseStatus.completed
          ? page([course('done', progress: 100)])
          : const PagedResult.empty(),
    );
    await tester.pumpWidget(
      MaterialApp(home: MyCoursesScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã học đủ bài (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Làm quiz cuối khóa'), findsOneWidget);
    expect(find.text('Xem chứng chỉ'), findsNothing);
    expect(find.text('Đã cấp chứng chỉ'), findsNothing);
  });

  testWidgets('Returning from learning refreshes both course tabs', (
    tester,
  ) async {
    final repo = FakeLearning((_, _) async => page([course('api')]));
    var opens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MyCoursesScreen(
          repository: repo,
          onOpenLearning: (course) async {
            expect(course.id, 'api');
            opens++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tiếp tục học').first);
    await tester.tap(find.text('Tiếp tục học').first);
    await tester.pumpAndSettle();
    expect(opens, 1);
    expect(repo.calls.length, 4);
  });

  testWidgets('Cards fit a narrow phone with larger text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeLearning(
      (_, _) async => page([course('long title ' * 8)]),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.3)),
          child: child!,
        ),
        home: MyCoursesScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
