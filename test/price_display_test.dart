import 'package:ecolearning_app/presentation/widgets/price_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, double price, double original) =>
      t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PriceDisplay(price: price, originalPrice: original),
        ),
      ));

  testWidgets('khóa giảm giá hiện giá gốc gạch ngang và nhãn phần trăm', (t) async {
    await pump(t, 750000, 1000000);
    expect(find.text('-25%'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(3));
  });

  testWidgets('khóa không giảm chỉ hiện một giá', (t) async {
    await pump(t, 1000000, 1000000);
    expect(find.byType(Text), findsOneWidget);
  });
}
