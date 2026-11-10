import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/presentation/screens/learning_support/paged_collection.dart';
import 'fixtures/preview_repositories.dart';
import 'package:ecolearning_app/presentation/screens/favorites/favorites_screen.dart';
import 'package:ecolearning_app/presentation/screens/orders/order_history_screen.dart';
import 'package:ecolearning_app/presentation/screens/my_courses/certificates_screen.dart';

PagedResult<String> page(List<String> values, {int number = 1}) => PagedResult(
  items: values,
  page: number,
  pageSize: 3,
  total: 4,
  totalPages: 2,
);

class FailingFavorites extends PreviewFavoriteRepository {
  @override
  Future<bool> toggle(String courseId) async =>
      throw const ApiException(message: 'Không thể bỏ yêu thích');
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('pagination retry preserves items and deduplicates', () async {
    bool fail = true;
    final c = PagedCollection<String>((p) async {
      if (p == 1) return page(['a', 'b']);
      if (fail) throw const ApiException(message: 'Offline');
      return page(['b', 'c'], number: 2);
    }, (s) => s);
    await c.load();
    await c.load(more: true);
    expect(c.items, ['a', 'b']);
    fail = false;
    await c.load(more: true);
    expect(c.items, ['a', 'b', 'c']);
    expect(c.hasMore, false);
    c.dispose();
  });
  test(
    'stale pages do not overwrite refresh or resurrect removed items',
    () async {
      final pending = Completer<PagedResult<String>>();
      int reads = 0;
      final c = PagedCollection<String>((p) async {
        reads++;
        return p == 2 ? pending.future : page([reads == 1 ? 'old' : 'new']);
      }, (s) => s);
      await c.load();
      final more = c.load(more: true);
      await c.load();
      pending.complete(page(['stale'], number: 2));
      await more;
      expect(c.items, ['new']);
      c.remove('new');
      expect(c.items, isEmpty);
      c.dispose();
    },
  );
  testWidgets('favorite removal confirms server result before removing', (
    tester,
  ) async {
    final repo = PreviewFavoriteRepository();
    await tester.pumpWidget(
      MaterialApp(home: FavoritesScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('4 khóa học đã lưu'), findsOneWidget);
    await tester.tap(
      find.byTooltip('Bỏ yêu thích Flutter: xây dựng ứng dụng di động'),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Xây dựng website với ASP.NET Core'), findsOneWidget);
    expect(find.text('Flutter: xây dựng ứng dụng di động'), findsNothing);
    expect(repo.courses, hasLength(3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed favorite removal keeps the course', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: FavoritesScreen(repository: FailingFavorites())),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip('Bỏ yêu thích Flutter: xây dựng ứng dụng di động'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flutter: xây dựng ứng dụng di động'), findsOneWidget);
    expect(find.text('Không thể bỏ yêu thích'), findsOneWidget);
  });
  testWidgets('order detail shows matching course, amount and transaction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderHistoryScreen(repository: PreviewOrderRepository()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('DH261020100001'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('Lập trình C# từ cơ bản đến nâng cao'), findsOneWidget);
    expect(find.text('0 đ'), findsOneWidget);
    expect(find.text('VNP26001020'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unearned certificates show empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CertificatesScreen(repository: PreviewQuizRepository()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có chứng chỉ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
