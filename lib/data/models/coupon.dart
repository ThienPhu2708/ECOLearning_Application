/// Model Mã giảm giá / Coupon thanh toán
class Coupon {
  final String code;
  final double discountPercent; // VD: 20 (tức là 20%)
  final String description;
  final bool isValid;

  const Coupon({
    required this.code,
    required this.discountPercent,
    required this.description,
    this.isValid = true,
  });
}
