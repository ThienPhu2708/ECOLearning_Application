import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/order_repository.dart';
import '../../navigation/app_navigator.dart';
import '../payment/payment_result_screen.dart';
import '../payment/payment_webview_screen.dart';

/// Thanh toán tiếp một đơn đang "Chờ thanh toán" từ Lịch sử đơn hàng.
///
/// F4 không trả lại link VNPay của đơn cũ, nên làm theo hợp đồng F3: tạo thanh toán mới cho đúng các khóa
/// trong đơn (server tự hủy đơn chờ cũ, mỗi người chỉ có một đơn chờ). Mã giảm giá của đơn cũ được giữ lại
/// nếu F4 có trả `couponCode`; giá luôn do server tính lại.
class ResumePayment {
  ResumePayment._();

  /// Trả `true` nếu đã mở màn thanh toán / kết quả (danh sách đơn nên tải lại), `false` nếu không làm gì.
  static Future<bool> start(BuildContext context, OrderRepository repo, String orderId) async {
    try {
      // 1. Đọc lại trạng thái thật của đơn: có thể đã trả tiền, hết hạn hoặc bị hủy từ lúc mở danh sách
      final order = await repo.order(orderId);
      final status = JsonUtils.asString(order['status']).toLowerCase();
      if (status != 'pending') {
        AppNavigator.showMessage(
          status == 'paid'
              ? 'Đơn hàng này đã được thanh toán.'
              : 'Đơn hàng không còn ở trạng thái chờ thanh toán, bạn hãy đặt lại từ giỏ hàng.',
        );
        return true; // trạng thái đã đổi nên cần tải lại danh sách
      }

      final courseIds = JsonUtils.asMapList(order['items'])
          .map((e) => JsonUtils.asString(e['id'] ?? e['courseId']))
          .where((id) => id.isNotEmpty)
          .toList();
      if (courseIds.isEmpty) {
        AppNavigator.showMessage('Không đọc được danh sách khóa học của đơn hàng này.');
        return false;
      }

      // 2. Tạo thanh toán mới cho các khóa đó
      final created = await repo.createOrder(
        courseIds,
        couponCode: JsonUtils.asStringOrNull(order['couponCode']),
      );
      if (!context.mounted) return true;

      final newId = JsonUtils.asString(created['orderId']);
      final paymentUrl = JsonUtils.asStringOrNull(created['paymentUrl']);
      final requiresPayment = JsonUtils.asBool(created['requiresPayment'], fallback: true);

      final Widget next = (!requiresPayment || paymentUrl == null)
          ? PaymentResultScreen(orderId: newId, courseIds: courseIds)
          : PaymentWebViewScreen(orderId: newId, paymentUrl: paymentUrl, courseIds: courseIds);
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => next));
      return true;
    } on ApiException catch (e) {
      AppNavigator.showMessage(e.message);
      // 409 ALREADY_OWNED, 400 COUPON_INVALID / COURSE_UNAVAILABLE...: đơn có thể đã đổi nên tải lại danh sách
      return true;
    }
  }
}
