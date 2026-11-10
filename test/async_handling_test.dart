import 'dart:async';

import 'package:ecolearning_app/core/error_reporting.dart';
import 'package:ecolearning_app/core/theme/app_theme.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/order_repository.dart';
import 'package:ecolearning_app/presentation/providers/auth_provider.dart';
import 'package:ecolearning_app/presentation/providers/cart_provider.dart';
import 'package:ecolearning_app/presentation/screens/cart/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Báo giá do test tự quyết định lúc nào trả về (giả lập mạng chậm, trả lời không theo thứ tự)
class _SlowOrders extends OrderRepository {
  final calls = <(List<String>, Completer<Map<String, dynamic>>)>[];
  @override
  Future<Map<String, dynamic>> quote(List<String> courseIds, {String? couponCode}) {
    final c = Completer<Map<String, dynamic>>();
    calls.add((List.of(courseIds), c));
    return c.future;
  }
}

class _BrokenOrders extends OrderRepository {
  @override
  Future<Map<String, dynamic>> quote(List<String> courseIds, {String? couponCode}) async =>
      throw const FormatException('Dữ liệu báo giá sai định dạng');
}

const _prices = {'A': 100000.0, 'B': 200000.0, 'C': 300000.0};

Map<String, dynamic> _quoteFor(List<String> ids) {
  final total = ids.fold<double>(0, (s, id) => s + _prices[id]!);
  return {
    'items': [
      for (final id in ids) {'id': id, 'price': _prices[id], 'originalPrice': _prices[id]},
    ],
    'subTotal': total,
    'discount': 0,
    'total': total,
    'invalidItems': [],
    'paymentMethods': [],
  };
}

Course _course(String id) => Course(
  id: id,
  title: 'Khóa $id',
  category: 'CNTT',
  instructor: 'Giáo viên',
  rating: 0,
  reviewCount: 0,
  price: _prices[id]!,
  originalPrice: _prices[id]!,
  imageUrl: '',
  tag: '',
  level: 'Cơ bản',
  duration: '1h',
  lessonsCount: 1,
);

Future<CartProvider> _pumpCart(WidgetTester tester, OrderRepository repo, List<String> ids) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
  final cart = CartProvider();
  for (final id in ids) {
    await cart.add(_course(id));
  }
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<CartProvider>.value(value: cart),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: CartScreen(repository: repo)),
  ));
  await tester.pump();
  return cart;
}

/// Phông Ahem trong test rộng bất thường nên có thể báo tràn chữ giả; chỉ coi lỗi khác là lỗi thật
void _ignoreOverflow(WidgetTester tester) {
  Object? e;
  while ((e = tester.takeException()) != null) {
    expect(e.toString(), contains('overflowed'), reason: 'Lỗi thật: $e');
  }
}

Finder _confirmButton() => find.textContaining('Xác nhận thanh toán');

String _confirmText(WidgetTester tester) => tester.widget<Text>(_confirmButton()).data!;

void main() {
  testWidgets('báo giá cũ về muộn không ghi đè tổng tiền của giỏ hiện tại', (tester) async {
    final repo = _SlowOrders();
    final cart = await _pumpCart(tester, repo, ['A', 'B', 'C']);
    repo.calls.single.$2.complete(_quoteFor(['A', 'B', 'C']));
    await tester.pump();
    _ignoreOverflow(tester);

    // Xóa A rồi xóa B thật nhanh: 2 báo giá chạy chồng nhau
    await tester.tap(find.byTooltip('Xóa khỏi giỏ').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Xóa khỏi giỏ').first);
    await tester.pump();
    expect(cart.ids, ['C']);
    expect(repo.calls.map((c) => c.$1), [
      ['A', 'B', 'C'],
      ['B', 'C'],
      ['C'],
    ]);

    // Mạng trả lời ngược thứ tự: báo giá mới (chỉ C) về trước, báo giá cũ (B + C) về sau
    repo.calls[2].$2.complete(_quoteFor(['C']));
    await tester.pump();
    repo.calls[1].$2.complete(_quoteFor(['B', 'C']));
    await tester.pump();
    _ignoreOverflow(tester);

    expect(_confirmText(tester), contains('300.000'), reason: 'giỏ chỉ còn C (300.000đ)');
    expect(_confirmText(tester), isNot(contains('500.000')), reason: 'không được hiện tổng của B + C');
    await tester.pump(const Duration(seconds: 4)); // hết SnackBar "Đã xóa"
  });

  testWidgets('lỗi báo giá ngoài dự kiến không làm kẹt nút thanh toán', (tester) async {
    await _pumpCart(tester, _BrokenOrders(), ['A']);
    await tester.pump();
    _ignoreOverflow(tester);
    expect(find.textContaining('Không cập nhật được giá'), findsOneWidget);
    expect(find.textContaining('Đang'), findsNothing, reason: 'không còn ở trạng thái đang tính giá');
  });

  test('lỗi bất đồng bộ lọt lưới được ghi log và coi như đã xử lý', () {
    final logs = <String>[];
    final reporter = ErrorReporter(logs.add);
    expect(reporter.asyncError(StateError('Future quên await'), StackTrace.empty), isTrue,
        reason: 'true = đã xử lý, app không văng');
    expect(logs.single, contains('[Lỗi bất đồng bộ chưa được bắt] Bad state: Future quên await'));
  });

  testWidgets('lỗi giao diện: giữ hành vi mặc định rồi ghi log', (tester) async {
    final logs = <String>[];
    final previous = FlutterError.onError;
    addTearDown(() => FlutterError.onError = previous);
    FlutterError.onError = (details) => logs.add('mặc định');

    installErrorReporting(log: logs.add);
    FlutterError.onError!(FlutterErrorDetails(exception: Exception('vẽ lỗi')));
    expect(logs, ['mặc định', '[Lỗi giao diện] Exception: vẽ lỗi']);
  });
}
