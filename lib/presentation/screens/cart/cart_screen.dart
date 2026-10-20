import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/coupon.dart';
import '../../../data/models/course.dart';
import '../../widgets/app_button.dart';
import '../learning/learning_space_screen.dart';

/// Màn hình Giỏ hàng & Thanh toán (UC4 & Section 4.5)
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  Coupon? _appliedCoupon;
  String? _couponError;
  String _paymentMethod = 'momo'; // 'momo', 'vnpay', 'card'
  bool _isProcessing = false;

  double get _subtotal => MockData.cartItems.fold(
        0.0,
        (sum, item) => sum + item.price,
      );

  double get _discountAmount {
    if (_appliedCoupon == null) return 0.0;
    return _subtotal * (_appliedCoupon!.discountPercent / 100.0);
  }

  double get _totalPayment => (_subtotal - _discountAmount).clamp(0.0, double.infinity);

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponError = 'Vui lòng nhập mã khuyến mãi';
        _appliedCoupon = null;
      });
      return;
    }

    final match = MockData.availableCoupons.firstWhere(
      (c) => c.code == code,
      orElse: () => const Coupon(code: '', discountPercent: 0, description: '', isValid: false),
    );

    if (match.isValid) {
      setState(() {
        _appliedCoupon = match;
        _couponError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Áp dụng mã ${match.code} thành công: -${match.discountPercent.toInt()}%'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _appliedCoupon = null;
        _couponError = 'Mã giảm giá không hợp lệ hoặc đã hết lượt dùng';
      });
    }
  }

  void _removeItem(Course course) {
    setState(() {
      MockData.cartItems.removeWhere((c) => c.id == course.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa "${course.title}" khỏi giỏ hàng'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () {
            setState(() {
              MockData.cartItems.add(course);
            });
          },
        ),
      ),
    );
  }

  void _confirmCheckout() {
    if (MockData.cartItems.isEmpty) return;

    setState(() => _isProcessing = true);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Chuyển các khóa học trong giỏ sang trạng thái đã đăng ký
      final purchasedCourses = List<Course>.from(MockData.cartItems);
      for (var c in purchasedCourses) {
        c.isEnrolled = true;
        if (c.progress == 0) {
          c.progress = 5.0;
        }
        if (!MockData.allCourses.any((item) => item.id == c.id)) {
          MockData.allCourses.add(c);
        }
      }
      MockData.cartItems.clear();

      // Hiện Modal chúc mừng
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppDimens.radiusCard),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Thanh toán thành công!',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Bạn đã sở hữu thành công ${purchasedCourses.length} khóa học. Bắt đầu lộ trình học ngay hôm nay!',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24.0),
              AppButton(
                text: 'Vào không gian học ngay',
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng Dialog
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LearningSpaceScreen(
                        course: purchasedCourses.first,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Giỏ hàng & Thanh toán',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: MockData.cartItems.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề số lượng
                  Text(
                    'Khóa học đã chọn (${MockData.cartItems.length})',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Danh sách sản phẩm trong giỏ
                  ...MockData.cartItems.map((course) => _buildCartItem(course)),
                  const SizedBox(height: 20.0),

                  // Khung nhập mã giảm giá Coupon
                  _buildCouponSection(),
                  const SizedBox(height: 20.0),

                  // Bảng tính tiền chi tiết
                  _buildPriceSummary(),
                  const SizedBox(height: 20.0),

                  // Phương thức thanh toán
                  _buildPaymentMethods(),
                  const SizedBox(height: 28.0),

                  // Nút xác nhận thanh toán
                  AppButton(
                    text: 'Xác nhận thanh toán (${AppFormatters.formatCurrency(_totalPayment)})',
                    isLoading: _isProcessing,
                    icon: const Icon(Icons.lock_outline_rounded, size: 20),
                    onPressed: _confirmCheckout,
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
    );
  }

  // Trạng thái giỏ rỗng (Empty State)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_shopping_cart_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Giỏ hàng của bạn đang trống',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Hãy khám phá thêm nhiều khóa học công nghệ & thiết kế mới nhất.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24.0),
            AppButton(
              text: 'Khám phá khóa học ngay',
              width: 220,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  // Từng thẻ khóa học trong giỏ
  Widget _buildCartItem(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: SizedBox(
              width: 90,
              height: 65,
              child: Image.network(
                course.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  course.instructor,
                  style: AppTypography.captionTiny.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  AppFormatters.formatCurrency(course.price),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 22.0,
            ),
            tooltip: 'Xóa khỏi giỏ',
            onPressed: () => _removeItem(course),
          ),
        ],
      ),
    );
  }

  // Khung nhập mã giảm giá Coupon
  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mã giảm giá (Coupon)',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'VD: CHAOMUNG2026',
                    prefixIcon: Icon(Icons.confirmation_num_outlined, size: 20),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.p8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimens.radiusButton,
                    ),
                  ),
                  onPressed: _applyCoupon,
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
          if (_appliedCoupon != null) ...[
            const SizedBox(height: 8.0),
            Text(
              '✓ Đã áp dụng: ${_appliedCoupon!.description} (-${_appliedCoupon!.discountPercent.toInt()}%)',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_couponError != null) ...[
            const SizedBox(height: 8.0),
            Text(
              '✕ $_couponError',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Bảng tính chi phí
  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết hóa đơn',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tạm tính:', style: AppTypography.bodyMedium),
              Text(
                AppFormatters.formatCurrency(_subtotal),
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khuyến mãi (${_appliedCoupon?.code}):',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.success),
                ),
                Text(
                  '-${AppFormatters.formatCurrency(_discountAmount)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const Divider(color: AppColors.border, height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng thanh toán:',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(_totalPayment),
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Phương thức thanh toán
  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn cổng thanh toán',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12.0),
          _buildPaymentTile(
            'momo',
            'Ví Điện Tử MoMo (Khuyên dùng)',
            Icons.account_balance_wallet_rounded,
            Colors.pink,
          ),
          _buildPaymentTile(
            'vnpay',
            'Cổng VNPAY / Quét mã QR',
            Icons.qr_code_2_rounded,
            Colors.blue,
          ),
          _buildPaymentTile(
            'card',
            'Thẻ ATM Nội Địa / Visa / Mastercard',
            Icons.credit_card_rounded,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(
    String value,
    String title,
    IconData icon,
    Color iconColor,
  ) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textHeading,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
