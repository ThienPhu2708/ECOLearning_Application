import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/core/theme/app_theme.dart';
import 'package:ecolearning_app/data/repositories/order_repository.dart';
import 'package:ecolearning_app/presentation/providers/auth_provider.dart';
import 'package:ecolearning_app/presentation/providers/cart_provider.dart';
import 'package:ecolearning_app/presentation/screens/orders/order_history_screen.dart';
import 'package:ecolearning_app/presentation/screens/payment/payment_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giả API đơn hàng: một đơn chờ thanh toán và một đơn đã thanh toán
class _FakeOrders extends OrderRepository {
  final created = <List<String>>[];
  final coupons = <String?>[];

  @override
  Future<PagedResult<Map<String, dynamic>>> orders({int page = 1}) async => const PagedResult(
        items: [
          {'orderId': 'DH-PENDING', 'status': 'pending', 'total': 279200, 'itemsCount': 2, 'createdAt': '2026-10-21T10:00:00+07:00'},
          {'orderId': 'DH-PAID', 'status': 'paid', 'total': 100000, 'itemsCount': 1, 'createdAt': '2026-10-20T10:00:00+07:00'},
        ],
        page: 1,
        pageSize: 10,
        total: 2,
        totalPages: 1,
      );

  @override
  Future<Map<String, dynamic>> order(String orderId) async => {
        'orderId': orderId,
        'status': orderId == 'DH-PENDING' ? 'pending' : 'paid',
        'total': 279200,
        'items': [
          {'id': 'KH01', 'title': 'Khóa 1'},
          {'id': 'KH02', 'title': 'Khóa 2'},
        ],
        'couponCode': 'GIAM20',
      };

  @override
  Future<Map<String, dynamic>> createOrder(List<String> courseIds, {String? couponCode, String paymentMethod = 'Napas'}) async {
    created.add(courseIds);
    coupons.add(couponCode);
    // Đơn 0 đồng: không cần mở VNPay, sang thẳng màn kết quả
    return {'orderId': 'DH-NEW', 'total': 0, 'requiresPayment': false};
  }
}

void main() {
  testWidgets('Bấm đơn chờ thanh toán thì tạo thanh toán cho đúng các khóa và sang thanh toán', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final repo = _FakeOrders();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: OrderHistoryScreen(repository: repo)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Đơn chờ có nút "Thanh toán ngay", đơn đã trả thì không
    expect(find.text('Thanh toán ngay'), findsOneWidget);
    expect(find.text('Chờ thanh toán'), findsOneWidget);

    // Bấm vào thẻ đơn chờ (không cần bấm đúng nút) cũng sang thanh toán
    await tester.tap(find.text('DH-PENDING'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tạo thanh toán mới đúng các khóa của đơn, giữ mã giảm giá của đơn cũ
    expect(repo.created, [
      ['KH01', 'KH02'],
    ]);
    expect(repo.coupons, ['GIAM20']);
    // Đơn 0 đồng nên vào thẳng màn kết quả
    expect(find.byType(PaymentResultScreen), findsOneWidget);

    // Phông test (Ahem) rộng bất thường nên có thể báo tràn chữ giả; chỉ coi là lỗi nếu không phải tràn chữ
    Object? e;
    while ((e = tester.takeException()) != null) {
      expect(e.toString(), contains('overflowed'), reason: 'Lỗi hiển thị thật: $e');
    }
  });
}
