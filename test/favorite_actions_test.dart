import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'fixtures/mock_data.dart';
import 'package:ecolearning_app/data/repositories/favorite_repository.dart';
import 'fixtures/learning_preview_app.dart';
import 'package:ecolearning_app/presentation/screens/learning_support/favorite_coordinator.dart';
import 'package:ecolearning_app/presentation/screens/learning_support/learning_data_scope.dart';
import 'fixtures/preview_repositories.dart';
import 'package:ecolearning_app/presentation/widgets/course_card.dart';
import 'package:ecolearning_app/presentation/widgets/course_favorite_button.dart';

Course sample() => Course.fromJson({
  'id': 'test-favorite',
  'title': 'Khóa học mẫu',
  'instructor': 'Giảng viên',
  'price': 349000,
});
PagedResult<Course> page(List<Course> items) => PagedResult(
  items: items,
  page: 1,
  pageSize: 12,
  total: items.length,
  totalPages: 1,
);

class FakeFavorites extends FavoriteRepository {
  Future<PagedResult<Course>> Function(int) read = (_) async => page([]);
  Future<bool> Function(String) write = (_) async => true;
  int calls = 0;
  @override
  Future<PagedResult<Course>> list({int page = 1}) => read(page);
  @override
  Future<bool> toggle(String courseId) {
    calls++;
    return write(courseId);
  }
}

Widget scoped(FavoriteRepository repo, Widget body) => LearningDataScope(
  learning: PreviewLearningRepository(),
  quiz: PreviewQuizRepository(),
  favorites: repo,
  orders: PreviewOrderRepository(),
  child: MaterialApp(home: Scaffold(body: body)),
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('favorite list hydrates saved hearts', () async {
    final course = sample();
    final repo = FakeFavorites()..read = ((_) async => page([course]));
    final state = FavoriteCoordinator(repo);
    state.register(course);
    await state.ensureLoaded();
    expect(state.isFavorite(course), true);
    state.dispose();
  });
  test('failed toggle leaves the previous heart state unchanged', () async {
    final course = sample();
    final repo = FakeFavorites()
      ..write = ((_) async => throw const ApiException(message: 'Offline'));
    final state = FavoriteCoordinator(repo);
    state.register(course);
    await state.ensureLoaded();
    await expectLater(state.toggle(course), throwsA(isA<ApiException>()));
    expect(state.isFavorite(course), false);
    expect(state.isPending(course.id), false);
    state.dispose();
  });
  test(
    'duplicate clicks only send one toggle and server state is authoritative',
    () async {
      final course = sample();
      final pending = Completer<bool>();
      final repo = FakeFavorites()..write = ((_) => pending.future);
      final state = FavoriteCoordinator(repo);
      state.register(course);
      await state.ensureLoaded();
      final first = state.toggle(course);
      await state.toggle(course);
      expect(repo.calls, 1);
      pending.complete(true);
      await first;
      expect(state.isFavorite(course), true);
      repo.write = (_) async => false;
      await state.toggle(course);
      expect(state.isFavorite(course), false);
      state.dispose();
    },
  );
  test('a stale initial list cannot undo a newer confirmed toggle', () async {
    final pending = Completer<PagedResult<Course>>();
    final repo = FakeFavorites()..read = ((_) => pending.future);
    final course = sample();
    final state = FavoriteCoordinator(repo);
    state.register(course);
    final loading = state.ensureLoaded();
    await state.toggle(course);
    pending.complete(page([]));
    await loading;
    expect(state.isFavorite(course), true);
    state.dispose();
  });
  testWidgets(
    'card heart does not navigate and updates another instance of the same course',
    (tester) async {
      final course = sample();
      final copy = course.copyWith();
      final repo = FakeFavorites();
      int opened = 0;
      await tester.pumpWidget(
        scoped(
          repo,
          SingleChildScrollView(
            child: Column(
              children: [
                CourseCard(course: course, onTap: () => opened++),
                CourseFavoriteButton(course: copy),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thêm vào yêu thích Khóa học mẫu').first);
      await tester.pumpAndSettle();
      expect(opened, 0);
      expect(repo.calls, 1);
      expect(find.byTooltip('Bỏ yêu thích Khóa học mẫu'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed heart action shows an error without coloring it as saved',
    (tester) async {
      final repo = FakeFavorites()
        ..write = ((_) async =>
            throw const ApiException(message: 'Chưa lưu được yêu thích'));
      await tester.pumpWidget(
        scoped(repo, Center(child: CourseFavoriteButton(course: sample()))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thêm vào yêu thích Khóa học mẫu'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa lưu được yêu thích'), findsOneWidget);
      expect(find.byTooltip('Thêm vào yêu thích Khóa học mẫu'), findsOneWidget);
    },
  );
  testWidgets(
    'my courses shortcut opens favorites and tab actions match their roles',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);
      final course = MockData.topMatchCourse;
      final original = course.isFavorite;
      addTearDown(() => course.isFavorite = original);
      await tester.pumpWidget(const LearningPreviewApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byTooltip('Thêm vào yêu thích ${course.title}').first,
      );
      await tester.tap(
        find.byTooltip('Thêm vào yêu thích ${course.title}').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khóa học').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Khóa học yêu thích'));
      await tester.pumpAndSettle();
      expect(find.text('5 khóa học đã lưu'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Xem thêm'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Xem thêm'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Bỏ yêu thích ${course.title}'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Bỏ yêu thích ${course.title}'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trang chủ').last);
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Thêm vào yêu thích ${course.title}').first,
        findsOneWidget,
      );
      for (final tab in ['Khám phá', 'Hồ sơ', 'Khóa học', 'Trang chủ']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(
          find.byTooltip('Giỏ hàng'),
          tab == 'Trang chủ' || tab == 'Khám phá' ? findsOneWidget : findsNothing,
        );
        expect(
          find.byTooltip('Khóa học yêu thích'),
          tab == 'Khóa học' ? findsOneWidget : findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
