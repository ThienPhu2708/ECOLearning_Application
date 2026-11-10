import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/presentation/screens/learning_support/search_pages.dart';
import 'package:ecolearning_app/presentation/widgets/list_search_field.dart';

void main() {
  test(
    'search scans later pages, supports Vietnamese and paginates matching results',
    () async {
      final calls = <int>[];
      Future<PagedResult<String>> fetch(int page) async {
        calls.add(page);
        return PagedResult(
          items: page == 1 ? ['SQL'] : ['Lập trình C#', 'Lập trình Web'],
          page: page,
          pageSize: 1,
          total: 3,
          totalPages: 2,
        );
      }

      final result = await searchPages(
        fetch: fetch,
        query: 'LAP TRINH',
        text: (String x) => x,
        id: (String x) => x,
        page: 2,
      );
      expect(calls, [1, 2]);
      expect(result.items, ['Lập trình Web']);
      expect(result.total, 2);
      expect(result.totalPages, 2);
      calls.clear();
      await searchPages(
        fetch: fetch,
        query: '',
        text: (String x) => x,
        id: (String x) => x,
        page: 2,
      );
      expect(calls, [2]);
    },
  );
  test(
    'failed later page cannot silently produce incomplete search results',
    () async {
      await expectLater(
        searchPages<String>(
          fetch: (page) async {
            if (page == 2) throw StateError('offline');
            return const PagedResult(
              items: ['a'],
              page: 1,
              pageSize: 1,
              total: 2,
              totalPages: 2,
            );
          },
          query: 'a',
          text: (x) => x,
          id: (x) => x,
          page: 1,
        ),
        throwsStateError,
      );
    },
  );
  testWidgets(
    'typing is debounced and clearing restores the full list immediately',
    (tester) async {
      final queries = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListSearchField(hint: 'Tìm', onChanged: queries.add),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'SQL');
      await tester.pump(const Duration(milliseconds: 200));
      expect(queries, isEmpty);
      await tester.pump(const Duration(milliseconds: 300));
      expect(queries, ['SQL']);
      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      expect(queries, ['SQL', '']);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
