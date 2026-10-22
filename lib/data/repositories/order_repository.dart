import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/paged_result.dart';
import '../../core/utils/json_utils.dart';

/// Nhóm F: Giỏ hàng, đơn hàng, thanh toán VNPay (Task_Tuan10.docx mục 6.6 và luồng 6.9).
/// Người dùng chính: Thư (F1 – F4, F6), Ngọc (F5 lịch sử đơn hàng).
///
/// Các hàm trả `Map` theo đúng mẫu JSON trong tài liệu; người làm màn hình tự tạo model nếu cần.
class OrderRepository {
  OrderRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// F1. Báo giá giỏ hàng: items, subTotal, discount, total, coupon, invalidItems, paymentMethods
  Future<Map<String, dynamic>> quote(List<String> courseIds, {String? couponCode}) async =>
      JsonUtils.asMap(await _api.post('/cart/quote', data: {'courseIds': courseIds, 'couponCode': couponCode}));

  /// F2. Mã giảm giá trong ví (đánh dấu mã nào dùng được cho giỏ hiện tại)
  Future<List<Map<String, dynamic>>> myCoupons(List<String> courseIds) async {
    final data = await _api.get(
      '/coupons/my',
      query: {'courseIds': courseIds.join(',')},
    );
    // The shared API returns { bestCode, items }; keep accepting the old list
    // shape while older server instances are being upgraded.
    if (data is List) return JsonUtils.asMapList(data);
    return JsonUtils.asMapList(JsonUtils.asMap(data)['items']);
  }

  /// F3. Tạo đơn hàng: orderId, total, expiresAt, requiresPayment, paymentUrl (mở trong WebView)
  Future<Map<String, dynamic>> createOrder(
    List<String> courseIds, {
    String? couponCode,
    String paymentMethod = ApiConfig.paymentMethodAtm,
  }) async =>
      JsonUtils.asMap(await _api.post('/orders', data: {
        'courseIds': courseIds,
        'couponCode': couponCode,
        'paymentMethod': paymentMethod,
      }));

  /// F4. Trạng thái đơn: status = pending / paid / failed / expired / cancelled
  Future<Map<String, dynamic>> order(String orderId) async => JsonUtils.asMap(await _api.get('/orders/$orderId'));

  /// F5. Lịch sử đơn hàng
  Future<PagedResult<Map<String, dynamic>>> orders({int page = 1}) async =>
      PagedResult.fromJson(await _api.get('/orders', query: {'page': page}), (m) => m);

  /// F6. Đăng ký khóa học miễn phí
  Future<void> enrollFree(String courseId) async {
    await _api.post('/courses/$courseId/enroll-free');
  }
}
