import 'package:ecolearning_app/data/models/home_feed.dart';
import 'package:ecolearning_app/data/repositories/home_repository.dart';
import 'package:ecolearning_app/presentation/screens/home/recently_viewed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RecentFixture extends HomeRepository {
  int calls = 0;
  bool fail = false;
  @override
  Future<HomeFeed> home() async {
    calls++;
    if (fail) throw StateError('offline');
    return HomeFeed.fromJson({
      'sections': [
        {
          'key': 'recently-viewed',
          'type': 'courses',
          'title': 'Đã xem gần đây',
          'items': [
            {
              'id': 'a',
              'title': 'Khóa xem gần đây',
              'note': 'Đã xem hôm nay',
              'imageUrl': '',
            },
          ],
        },
      ],
    });
  }
}

void main() {
  testWidgets('recent page displays server history and reloads on return', (
    tester,
  ) async {
    final repo = RecentFixture();
    var opened = '';
    await tester.pumpWidget(
      MaterialApp(
        home: RecentlyViewedScreen(
          repository: repo,
          onOpenCourse: (course) async {
            opened = course.id;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Khóa xem gần đây'), findsOneWidget);
    expect(find.text('Đã xem hôm nay'), findsOneWidget);
    expect(find.textContaining('tối đa 10'), findsOneWidget);
    await tester.tap(find.text('Khóa xem gần đây'));
    await tester.pumpAndSettle();
    expect(opened, 'a');
    expect(repo.calls, 2);
  });

  testWidgets('API errors show a retry state, not an empty history', (
    tester,
  ) async {
    final repo = RecentFixture()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: RecentlyViewedScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có khóa học xem gần đây'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Khóa xem gần đây'), findsOneWidget);
  });
}
