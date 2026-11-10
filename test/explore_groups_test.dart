import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/models/home_feed.dart';
import 'package:ecolearning_app/data/repositories/favorite_repository.dart';
import 'package:ecolearning_app/data/repositories/home_repository.dart';
import 'package:ecolearning_app/presentation/screens/explore/explore_screen.dart';
import 'package:ecolearning_app/presentation/screens/explore/filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'explore_filters_test.dart' show FilterRepository, course;

class FavoritesFixture extends FavoriteRepository {
  final calls = <int>[];
  @override
  Future<PagedResult<Course>> list({int page = 1}) async {
    calls.add(page);
    return PagedResult(
      items: [course('Yêu thích $page', page == 1 ? 4.8 : 3.5, 'Cơ bản', 0)],
      page: page,
      pageSize: 1,
      total: 2,
      totalPages: 2,
    );
  }
}

class HomeFixture extends HomeRepository {
  @override
  Future<HomeFeed> home() async => HomeFeed.fromJson({
    'sections': [
      {
        'key': 'best-sellers',
        'type': 'courses',
        'title': 'Bán chạy',
        'items': [
          {
            'id': 'best',
            'title': 'Bán chạy đúng kỳ',
            'level': 'Cơ bản',
            'rating': 4.5,
            'price': 10,
            'originalPrice': 10,
          },
        ],
      },
    ],
  });
}

void main() {
  testWidgets(
    'home sort shortcuts reset filters and request the chosen server order',
    (tester) async {
      final key = GlobalKey<ExploreScreenState>();
      final repository = FilterRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(key: key, repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      key.currentState!.showTopRated();
      await tester.pumpAndSettle();
      key.currentState!.showSort('newest');
      await tester.pumpAndSettle();
      expect(repository.calls.last['sort'], 'newest');
      expect(repository.calls.last['minRating'], isNull);
      expect(repository.calls.last['page'], 1);
      await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Mới nhất'))
            .selected,
        isTrue,
      );
      Navigator.of(tester.element(find.text('Bộ lọc tìm kiếm'))).pop();
      await tester.pumpAndSettle();
      key.currentState!.showSort('popular');
      await tester.pumpAndSettle();
      expect(repository.calls.last['sort'], 'popular');
      expect(repository.calls.last['minRating'], isNull);
      await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Phổ biến'))
            .selected,
        isTrue,
      );
    },
  );
  testWidgets(
    'high rating requires at least four stars and re-enables lower choices for other sorts',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      FilterCriteria? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet(
              initialCriteria: FilterCriteria(minRating: 3),
              onApply: (value) => applied = value,
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Đánh giá cao'));
      await tester.tap(find.text('Đánh giá cao'));
      await tester.pump();
      final all = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Tất cả xếp hạng'),
      );
      final three = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Từ 3.0★ trở lên'),
      );
      expect(all.onSelected, isNull);
      expect(three.onSelected, isNull);
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Từ 4.0★ trở lên'),
            )
            .selected,
        isTrue,
      );
      await tester.ensureVisible(find.text('Từ 4.5★ trở lên'));
      await tester.tap(find.text('Từ 4.5★ trở lên'));
      await tester.ensureVisible(find.text('Mới nhất'));
      await tester.tap(find.text('Mới nhất'));
      await tester.pump();
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Từ 3.0★ trở lên'),
            )
            .onSelected,
        isNotNull,
      );
      await tester.tap(find.text('Đánh giá cao'));
      await tester.pump();
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      // This test hosts the sheet directly, so provide a route to pop on apply.
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pump();
      expect(applied?.minRating, 4.5);
      expect(applied?.sort, 'rating');
    },
  );
  testWidgets('top rated shortcut applies rating threshold and server sort', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final key = GlobalKey<ExploreScreenState>();
    final repository = FilterRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ExploreScreen(key: key, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    key.currentState!.showTopRated();
    await tester.pumpAndSettle();
    expect(repository.calls.last['minRating'], 4.0);
    expect(repository.calls.last['sort'], 'rating');
    expect(repository.calls.last['level'], isNull);
    expect(find.textContaining('Tìm thấy 2 khóa học'), findsOneWidget);
    expect(find.text('Khóa C'), findsNothing);
    await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, 'Từ 4.0★ trở lên'),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Đánh giá cao'))
          .selected,
      isTrue,
    );
  });
  testWidgets(
    'homepage group selection resets filters and loads all favorites pages',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final key = GlobalKey<ExploreScreenState>();
      final favorites = FavoritesFixture();
      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(
            key: key,
            repository: FilterRepository(),
            favorites: favorites,
            home: HomeFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      key.currentState!.showGroup(CourseGroup.favorites);
      await tester.pumpAndSettle();
      expect(favorites.calls, [1, 2]);
      expect(find.text('Khóa Yêu thích 1'), findsOneWidget);
      expect(find.text('Khóa Yêu thích 2'), findsOneWidget);
      expect(find.textContaining('Tìm thấy 2 khóa học'), findsOneWidget);
      await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Khóa học yêu thích'),
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Khóa học yêu thích'),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Tất cả xếp hạng'),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Tất cả').last)
            .selected,
        isTrue,
      );
      await tester.ensureVisible(find.text('Từ 4.5★ trở lên'));
      await tester.tap(find.text('Từ 4.5★ trở lên'));
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 1 khóa học'), findsOneWidget);
      expect(find.text('Khóa Yêu thích 2'), findsNothing);
      key.currentState!.showGroup(CourseGroup.bestSellers);
      await tester.pumpAndSettle();
      expect(find.text('Bán chạy đúng kỳ'), findsOneWidget);
      expect(find.text('Khóa Yêu thích 1'), findsNothing);
      await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Khóa học yêu thích'),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Khóa học yêu thích'));
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 2 khóa học'), findsOneWidget);
      await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Mới nhất'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Mới nhất'));
      await tester.pump();
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Khóa học yêu thích'),
            )
            .selected,
        isFalse,
      );
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 3 khóa học'), findsOneWidget);
    },
  );
}
