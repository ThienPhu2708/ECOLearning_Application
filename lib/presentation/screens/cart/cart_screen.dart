import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/sign_in_required.dart';
import '../../widgets/state_views.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/order_repository.dart';
import '../payment/payment_webview_screen.dart';
import '../payment/payment_result_screen.dart';
import '../../../data/models/course.dart';
import '../../widgets/app_button.dart';

/// Màn hình Giỏ hàng & Thanh toán (UC4 & Section 4.5)
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  String? get _couponCode =>
      JsonUtils.asStringOrNull(JsonUtils.asMap(_quote?['coupon'])['code']);
  String _paymentMethod = 'Napas'; // 'momo', 'vnpay', 'card'
  bool _isProcessing = false;

  Map<String, dynamic>? _quote;
  final _repo = OrderRepository();
  bool _quoting = true;
  Object? _quoteError;
  List<Course> get _cartCourses => context
      .read<CartProvider>()
      .items
      .map((item) => Course.fromJson(item.toJson()))
      .toList();
  double get _subtotal => JsonUtils.asDouble(_quote?['subTotal']);
  double get _discountAmount => JsonUtils.asDouble(_quote?['discount']);
  double get _totalPayment => JsonUtils.asDouble(_quote?['total']);
  @override
  void initState() {
    super.initState();
    _refreshQuote();
  }

  Future<void> _refreshQuote() async {
    if (context.read<AuthProvider?>()?.isLoggedIn != true) {
      setState(() => _quoting = false);
      return;
    }
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      final quote = await _repo.quote(
        context.read<CartProvider>().ids,
        couponCode: _couponController.text.trim().isEmpty
            ? null
            : _couponController.text.trim(),
      );
      if (mounted) setState(() => _quote = quote);
    } catch (e) {
      if (mounted) setState(() => _quoteError = e);
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  Future<void> _applyCoupon() async {
    await _refreshQuote();
  }

  Future<void> _removeItem(Course course) async {
    await context.read<CartProvider>().remove(course.id);
    if (mounted) await _refreshQuote();
  }

  Future<void> _confirmCheckout() async {
    if (_isProcessing || _quoting || _quoteError != null || _quote == null) {
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final result = await _repo.createOrder(
        context.read<CartProvider>().ids,
        couponCode: _couponController.text.trim().isEmpty
            ? null
            : _couponController.text.trim(),
        paymentMethod: 'Napas',
      );
      if (!mounted) return;
      final id = JsonUtils.asString(result['orderId']);
      final url = JsonUtils.asString(result['paymentUrl']);
      if (id.isEmpty) {
        throw StateError('Chưa nhận được mã đơn hàng từ máy chủ.');
      }
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => JsonUtils.asBool(result['requiresPayment'])
              ? PaymentWebViewScreen(orderId: id, paymentUrl: url)
              : PaymentResultScreen(orderId: id),
        ),
      );
      if (mounted) await _refreshQuote();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CartProvider>();
    if (context.watch<AuthProvider?>()?.isLoggedIn != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Giỏ hàng')),
        body: const SignInRequired(),
      );
    }
    if (_quoting || _quoteError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Giỏ hàng')),
        body: _quoting
            ? const LoadingView()
            : ErrorView(error: _quoteError, onRetry: _refreshQuote),
      );
    }
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
      body: _cartCourses.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề số lượng
                  Text(
                    'Khóa học đã chọn (${_cartCourses.length})',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Danh sách sản phẩm trong giỏ
                  ..._cartCourses.map((course) => _buildCartItem(course)),
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
                    text:
                        'Xác nhận thanh toán (${AppFormatters.formatCurrency(_totalPayment)})',
                    isLoading: _isProcessing,
                    icon: const Icon(Icons.lock_outline_rounded, size: 20),
                    onPressed: _quote == null ? null : _confirmCheckout,
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
              child: Image.network(course.imageUrl, fit: BoxFit.cover),
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
          if (_couponCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Đã áp dụng: $_couponCode',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.success,
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
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khuyến mãi:',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success,
                  ),
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
            'Napas',
            'Thẻ ATM nội địa qua VNPay',
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
