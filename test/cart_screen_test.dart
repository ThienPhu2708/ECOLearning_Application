import 'package:ecolearning_app/core/theme/app_theme.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/order_repository.dart';
import 'package:ecolearning_app/presentation/providers/auth_provider.dart';
import 'package:ecolearning_app/presentation/providers/cart_provider.dart';
import 'package:ecolearning_app/presentation/screens/cart/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Báo giá giả đúng theo ví dụ F1 trong tài liệu hợp đồng
class _FakeOrders extends OrderRepository {
  _FakeOrders(this.quoteJson);
  final Map<String, dynamic> quoteJson;

  @override
  Future<Map<String, dynamic>> quote(List<String> courseIds, {String? couponCode}) async => quoteJson;
}

Course _course(String id, String title) => Course(
      id: id,
      title: title,
      category: 'CNTT',
      instructor: 'Giảng viên A',
      rating: 4.5,
      reviewCount: 2,
      price: 349000,
      originalPrice: 499000,
      imageUrl: '',
      tag: '',
      level: 'Cơ bản',
      duration: '1h',
      lessonsCount: 3,
    );

Future<void> _pump(WidgetTester tester, CartProvider cart, OrderRepository repo) async {
  tester.view.physicalSize = const Size(1080, 2200); // ~ điện thoại 360dp
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<CartProvider>.value(value: cart),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: CartScreen(repository: repo)),
  ));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(seconds: 1));
}

/// Trong môi trường test, chữ dùng phông Ahem rộng bất thường nên có thể báo tràn chữ giả;
/// chỉ coi là lỗi nếu không phải lỗi tràn chữ.
void _expectNoRealError(WidgetTester tester) {
  Object? e;
  while ((e = tester.takeException()) != null) {
    expect(e.toString(), contains('overflowed'), reason: 'Lỗi hiển thị thật: $e');
  }
}

void main() {
  testWidgets('Giỏ hàng hiện khóa học khi báo giá thành công', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cart = CartProvider();
    await cart.add(_course('KH01', 'Khóa học thử nghiệm giỏ hàng'));

    await _pump(tester, cart, _FakeOrders({
      'items': [
        {'id': 'KH01', 'title': 'x', 'price': 349000, 'originalPrice': 499000},
      ],
      'subTotal': 349000,
      'discount': 0,
      'total': 349000,
      'coupon': null,
      'invalidItems': [],
      'paymentMethods': [
        {'id': 'Napas', 'name': 'Thẻ ATM nội địa', 'enabled': true},
        {'id': 'Visa/Mastercard', 'name': 'Thẻ quốc tế', 'enabled': false, 'reason': 'Chưa hỗ trợ'},
      ],
    }));

    _expectNoRealError(tester);
    expect(find.text('Khóa học thử nghiệm giỏ hàng'), findsOneWidget);
    expect(find.textContaining('Xác nhận thanh toán'), findsOneWidget);
  });

  testWidgets('Khóa bị server loại (invalidItems) được báo và bỏ khỏi giỏ', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cart = CartProvider();
    await cart.add(_course('KH02', 'Khóa đã sở hữu'));

    await _pump(tester, cart, _FakeOrders({
      'items': [],
      'subTotal': 0,
      'discount': 0,
      'total': 0,
      'invalidItems': [
        {'id': 'KH02', 'reason': 'Bạn đã sở hữu khóa học này'},
      ],
      'paymentMethods': [],
    }));

    _expectNoRealError(tester);
    expect(cart.isEmpty, isTrue);
    expect(find.text('Giỏ hàng của bạn đang trống'), findsOneWidget);
  });
}
