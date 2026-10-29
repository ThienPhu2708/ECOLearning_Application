import 'package:ecolearning_app/presentation/widgets/home_hero_carousel.dart';
import 'package:ecolearning_app/presentation/widgets/home_highlights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('banner và các mục giới thiệu không tràn ở màn hình hẹp', (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    int? tab;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                HomeHeroCarousel(onNavigateTab: (i) => tab = i),
                const HomeWhySection(),
                const HomeStatsBand(),
                const HomeStepsSection(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Khám phá ngay'), findsOneWidget);
    expect(find.text('Vì sao chọn E-Learning?'), findsOneWidget);
    expect(find.text('15,000+'), findsOneWidget);
    expect(find.text('Bắt đầu với 4 bước'), findsOneWidget);

    await t.tap(find.text('Khám phá ngay'));
    expect(tab, 1);

    // Tự chuyển sang slide kế sau 5 giây rồi dừng timer khi dọn widget
    await t.pump(const Duration(seconds: 5));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Khóa học dành riêng cho bạn'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
