import 'dart:async';
import 'package:dio/dio.dart';
import 'package:ecolearning_app/core/config/api_config.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/data/models/category.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/course_repository.dart';
import 'package:ecolearning_app/presentation/screens/explore/explore_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'api_learning_contract_test.dart' show Transport;

Course course(String id, double rating, String level, double price) =>
    Course.fromJson({
      'id': id,
      'title': 'Khóa $id',
      'category': 'CNTT',
      'instructor': 'GV',
      'level': level,
      'rating': rating,
      'reviewCount': 1,
      'price': price,
      'originalPrice': price,
      'imageUrl': '',
    });

class FilterRepository extends CourseRepository {
  final calls = <Map<String, Object?>>[];
  final values = [
    course('A', 4.8, 'Cơ bản', 0),
    course('B', 4.2, 'Nâng cao', 100),
    course('C', 3.5, 'Cơ bản', 0),
  ];
  @override
  Future<List<Category>> categories() async => [];
  @override
  Future<({List<String> keywords, List<Course> courses})> suggest(
    String q,
  ) async => (keywords: <String>[], courses: <Course>[]);
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
    calls.add({
      'q': q,
      'categoryId': categoryId,
      'level': level,
      'price': price,
      'minRating': minRating,
      'sort': sort,
      'webCatalog': webCatalog,
      'page': page,
      'pageSize': pageSize,
    });
    var result = values
        .where(
          (c) =>
              (level == null || c.level == level) &&
              (price != 'free' || c.originalPrice == 0) &&
              (price != 'paid' || c.originalPrice > 0) &&
              (minRating == null || c.rating >= minRating),
        )
        .toList();
    if (sort == 'rating') result.sort((a, b) => b.rating.compareTo(a.rating));
    return PagedResult(
      items: result.skip((page - 1) * pageSize).take(pageSize).toList(),
      page: page,
      pageSize: pageSize,
      total: result.length,
      totalPages: (result.length / pageSize).ceil(),
    );
  }
}

class SlowFilterRepository extends FilterRepository {
  final pending = <String, Completer<PagedResult<Course>>>{};
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
  }) {
    if (pageSize == 50) return super.courses(q: q, pageSize: pageSize);
    final completer = Completer<PagedResult<Course>>();
    pending[q ?? ''] = completer;
    return completer.future;
  }
}

class PagingFilterRepository extends FilterRepository {
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
    if (pageSize == 50) return super.courses(pageSize: pageSize);
    calls.add({'q': q, 'page': page, 'pageSize': pageSize, 'sort': sort});
    return PagedResult(
      items: [course('Trang $page', 4.5, 'Cơ bản', 0)],
      page: page,
      pageSize: pageSize,
      total: 21,
      totalPages: 3,
    );
  }
}

PagedResult<Course> result(String id, int total) => PagedResult(
  items: [course(id, 4, 'Cơ bản', 0)],
  page: 1,
  pageSize: 10,
  total: total,
  totalPages: 1,
);

void main() {
  testWidgets('free filter can be enabled and disabled', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = FilterRepository();
    await tester.pumpWidget(MaterialApp(home: ExploreScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(repo.calls.last['sort'], 'newest');
    expect(repo.calls.last['webCatalog'], isTrue);
    await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
    await tester.pumpAndSettle();
    expect(find.text('Khóa học có phí'), findsNothing);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(repo.calls.last['price'], 'free');
    expect(find.textContaining('Tìm thấy 2 khóa học'), findsOneWidget);
    await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).first);
    await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(repo.calls.last['price'], isNull);
    expect(find.textContaining('Tìm thấy 3 khóa học'), findsOneWidget);
  });
  test('repository sends all filters and uses server total and page', () async {
    final transport = Transport()
      ..data = {
        'items': [],
        'page': 2,
        'pageSize': 10,
        'total': 11,
        'totalPages': 2,
      };
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
      ..httpClientAdapter = transport;
    final repo = CourseRepository(
      client: ApiClient(dio: dio, tokenProvider: () => null),
    );
    final response = await repo.courses(
      q: 'sql',
      categoryId: 'dm',
      level: 'Cơ bản',
      price: 'free',
      minRating: 4.5,
      sort: 'rating',
      webCatalog: true,
      page: 2,
      pageSize: 10,
    );
    expect(
      transport.calls.last.queryParameters,
      containsPair('minRating', 4.5),
    );
    expect(transport.calls.last.queryParameters, containsPair('price', 'free'));
    expect(
      transport.calls.last.queryParameters,
      containsPair('level', 'Cơ bản'),
    );
    expect(
      transport.calls.last.queryParameters,
      containsPair('sort', 'rating'),
    );
    expect(transport.calls.last.queryParameters, containsPair('page', 2));
    expect(
      transport.calls.last.queryParameters,
      containsPair('webCatalog', true),
    );
    expect(response.total, 11);
    expect(response.totalPages, 2);
  });
  testWidgets(
    'high rating sets minimum; combined filters and reset update counts and request',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final repo = FilterRepository();
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 3 khóa học'), findsOneWidget);
      await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đánh giá cao'));
      await tester.tap(find.text('Đánh giá cao'));
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 2 khóa học'), findsOneWidget);
      expect(repo.calls.last['sort'], 'rating');
      expect(repo.calls.last['minRating'], 4.0);
      await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Từ 4.5★ trở lên'));
      await tester.tap(find.text('Cơ bản'));
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.tap(find.byType(Switch).first);
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 1 khóa học'), findsOneWidget);
      expect(repo.calls.last, containsPair('minRating', 4.5));
      expect(repo.calls.last, containsPair('level', 'Cơ bản'));
      expect(repo.calls.last, containsPair('price', 'free'));
      expect(repo.calls.last, containsPair('page', 1));
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 3 khóa học'), findsOneWidget);
      expect(repo.calls.last['minRating'], isNull);
      await tester.tap(find.byTooltip('Bộ lọc nâng cao'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Từ 4.5★ trở lên'));
      await tester.tap(find.text('Nâng cao'));
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.tap(find.byType(Switch).first);
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 0 khóa học'), findsOneWidget);
      expect(find.text('Không tìm thấy kết quả phù hợp'), findsOneWidget);
    },
  );

  testWidgets(
    'search and page navigation use the server total and requested page',
    (tester) async {
      final repo = PagingFilterRepository();
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'sql');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 21 khóa học'), findsOneWidget);
      expect(repo.calls.last['q'], 'sql');
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(repo.calls.last['page'], 2);
      expect(repo.calls.last['q'], 'sql');
      expect(find.text('Khóa Trang 2'), findsOneWidget);
    },
  );

  testWidgets(
    'older response cannot replace new results even during debounce',
    (tester) async {
      final repo = SlowFilterRepository();
      await tester.pumpWidget(
        MaterialApp(home: ExploreScreen(repository: repo)),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'mới');
      repo.pending['']!.complete(result('Cũ', 8));
      await tester.pump();
      expect(find.textContaining('Tìm thấy 8 khóa học'), findsNothing);
      await tester.pump(const Duration(milliseconds: 450));
      repo.pending['mới']!.complete(result('Mới', 1));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tìm thấy 1 khóa học'), findsOneWidget);
      expect(find.text('Khóa Mới'), findsOneWidget);
      expect(find.text('Khóa Cũ'), findsNothing);
    },
  );
}
