import '../../core/utils/json_utils.dart';

/// Một khóa học bị server loại khỏi báo giá (đã sở hữu, ngừng bán…)
class QuoteIssue {
  final String courseId;
  final String reason;

  const QuoteIssue({required this.courseId, required this.reason});
}

/// Một phương thức thanh toán server cho phép / không cho phép (F1 `paymentMethods`)
class PaymentMethodOption {
  final String id;
  final String name;
  final bool enabled;
  final String? reason;

  const PaymentMethodOption({required this.id, required this.name, required this.enabled, this.reason});
}

/// Kết quả báo giá giỏ hàng (F1 `POST /cart/quote`). Giá luôn lấy từ server, không dùng giá lưu trên máy.
///
/// Tên trường đọc linh hoạt vì hợp đồng chỉ nêu: items, subTotal, discount, total, coupon, invalidItems, paymentMethods.
class CartQuote {
  final double subTotal;
  final double discount;
  final double total;

  /// Giá hiện tại của từng khóa theo id
  final Map<String, double> prices;

  /// Giá gốc (trước giảm) của từng khóa theo id
  final Map<String, double> originalPrices;

  /// Mã giảm giá đang áp dụng (null nếu không có / không hợp lệ)
  final String? couponCode;
  final String? couponMessage;
  final bool couponValid;

  final List<QuoteIssue> invalidItems;
  final List<PaymentMethodOption> paymentMethods;

  const CartQuote({
    required this.subTotal,
    required this.discount,
    required this.total,
    this.prices = const {},
    this.originalPrices = const {},
    this.couponCode,
    this.couponMessage,
    this.couponValid = false,
    this.invalidItems = const [],
    this.paymentMethods = const [],
  });

  factory CartQuote.fromJson(Map<String, dynamic> json, {String? requestedCoupon}) {
    final prices = <String, double>{};
    final originalPrices = <String, double>{};
    for (final item in JsonUtils.asMapList(json['items'])) {
      final id = JsonUtils.asString(item['courseId'] ?? item['id']);
      if (id.isEmpty) continue;
      final price = JsonUtils.asDouble(item['price'] ?? item['finalPrice']);
      prices[id] = price;
      originalPrices[id] = JsonUtils.asDouble(item['originalPrice'], fallback: price);
    }

    final invalid = <QuoteIssue>[];
    for (final raw in JsonUtils.asList(json['invalidItems'])) {
      if (raw is Map) {
        final m = JsonUtils.asMap(raw);
        invalid.add(QuoteIssue(
          courseId: JsonUtils.asString(m['courseId'] ?? m['id']),
          reason: JsonUtils.asString(m['reason'] ?? m['message'], fallback: 'Không thể mua khóa học này.'),
        ));
      } else if (raw != null) {
        invalid.add(QuoteIssue(courseId: raw.toString(), reason: 'Không thể mua khóa học này.'));
      }
    }

    final methods = JsonUtils.asMapList(json['paymentMethods'])
        .map((m) => PaymentMethodOption(
              id: JsonUtils.asString(m['id']),
              name: JsonUtils.asString(m['name']),
              enabled: JsonUtils.asBool(m['enabled']),
              reason: JsonUtils.asStringOrNull(m['reason']),
            ))
        .where((m) => m.id.isNotEmpty)
        .toList();

    final coupon = json['coupon'];
    String? code;
    String? message;
    var valid = false;
    if (coupon is Map) {
      final m = JsonUtils.asMap(coupon);
      code = JsonUtils.asStringOrNull(m['code']) ?? requestedCoupon;
      message = JsonUtils.asStringOrNull(m['message']);
      valid = JsonUtils.asBool(m['isValid'] ?? m['valid'], fallback: true);
    } else if (coupon is String && coupon.isNotEmpty) {
      code = coupon;
      valid = true;
    }

    return CartQuote(
      subTotal: JsonUtils.asDouble(json['subTotal']),
      discount: JsonUtils.asDouble(json['discount']),
      total: JsonUtils.asDouble(json['total']),
      prices: prices,
      originalPrices: originalPrices,
      couponCode: valid ? code : null,
      couponMessage: message,
      couponValid: valid,
      invalidItems: invalid,
      paymentMethods: methods,
    );
  }
}
