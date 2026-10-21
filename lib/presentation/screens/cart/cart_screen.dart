import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/models/cart_quote.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../navigation/app_navigator.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import '../course_detail/course_detail_screen.dart';
import '../payment/payment_result_screen.dart';
import '../payment/payment_webview_screen.dart';

/// Màn hình Giỏ hàng & Thanh toán (UC4 & Section 4.5)
/// Giỏ lưu trên máy (CartProvider) nhưng giá, mã giảm giá luôn lấy từ server (F1).
/// Thanh toán: F3 tạo đơn → mở VNPay trong WebView → F4 xác minh (PaymentWebViewScreen, PaymentResultScreen).
class CartScreen extends StatefulWidget {
  /// Cho phép thay repository khi test
  final OrderRepository? repository;

  const CartScreen({super.key, this.repository});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final OrderRepository _orderRepo = widget.repository ?? OrderRepository();
  final _couponController = TextEditingController();

  CartQuote? _quote;
  Object? _quoteError;
  bool _quoting = false;
  String? _appliedCode;
  String? _couponError;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _refreshQuote();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  /// F1. Báo giá lại theo giỏ hiện tại. Trả false nếu lỗi (lỗi coupon được ghi vào [_couponError]).
  Future<bool> _refreshQuote({String? coupon}) async {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      setState(() {
        _quote = null;
        _quoteError = null;
        _appliedCode = null;
      });
      return true;
    }

    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    final code = coupon ?? _appliedCode;
    try {
      final data = await _orderRepo.quote(cart.ids, couponCode: code);
      if (!mounted) return false;
      final quote = CartQuote.fromJson(data, requestedCoupon: code);
      await cart.updatePrices(quote.prices, quote.originalPrices);
      if (!mounted) return false;

      String? couponError;
      if (code != null && !quote.couponValid) {
        couponError = quote.couponMessage ?? 'Mã giảm giá không hợp lệ hoặc đã hết lượt dùng';
      }
      setState(() {
        _quote = quote;
        _appliedCode = quote.couponValid ? quote.couponCode : null;
        _couponError = couponError;
        _quoting = false;
      });

      // Khóa đã sở hữu / ngừng bán: bỏ khỏi giỏ và báo cho người dùng
      if (quote.invalidItems.isNotEmpty) {
        await _dropInvalidItems(quote);
      }
      return couponError == null;
    } on ApiException catch (e) {
      if (!mounted) return false;
      setState(() {
        _quoting = false;
        if (code != null && e.code.toUpperCase().contains('COUPON')) {
          // Mã sai: giữ báo giá không mã
          _couponError = e.message;
          _appliedCode = null;
        } else if (code != null && _quote != null && coupon != null) {
          _couponError = e.message;
        } else {
          _quoteError = e;
        }
      });
      if (code != null && coupon != null && _couponError != null) {
        // Báo giá lại không kèm mã để số tiền hiển thị đúng
        _appliedCode = null;
        return _refreshQuote().then((_) => false);
      }
      return false;
    }
  }

  Future<void> _dropInvalidItems(CartQuote quote) async {
    final cart = context.read<CartProvider>();
    final titles = <String>[];
    for (final issue in quote.invalidItems) {
      final item = cart.items.where((e) => e.id == issue.courseId).toList();
      titles.add(item.isEmpty ? issue.reason : '${item.first.title}: ${issue.reason}');
    }
    await cart.removeAll(quote.invalidItems.map((e) => e.courseId));
    if (!mounted) return;
    AppNavigator.showMessage('Đã bỏ khỏi giỏ: ${titles.join('; ')}');
    await _refreshQuote();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _couponError = 'Vui lòng nhập mã khuyến mãi');
      return;
    }
    setState(() => _couponError = null);
    final ok = await _refreshQuote(coupon: code);
    if (!mounted || !ok) return;
    final q = _quote;
    if (q != null && q.couponValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Áp dụng mã ${q.couponCode} thành công'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// F2. Chọn mã từ ví: mã không dùng được cho giỏ hiện tại bị làm mờ kèm lý do
  Future<void> _openCouponWallet() async {
    final cart = context.read<CartProvider>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CouponWalletSheet(courseIds: cart.ids, repo: _orderRepo),
    );
    if (picked == null || !mounted) return;
    _couponController.text = picked;
    _applyCoupon();
  }

  void _removeCoupon() {
    _couponController.clear();
    setState(() {
      _appliedCode = null;
      _couponError = null;
    });
    _refreshQuote();
  }

  Future<void> _removeItem(CartItem item) async {
    final cart = context.read<CartProvider>();
    await cart.remove(item.id);
    if (!mounted) return;
    _refreshQuote();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${item.title}" khỏi giỏ hàng'),
          behavior: SnackBarBehavior.floating,
          persist: false,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () async {
              await cart.restore(item);
              if (mounted) _refreshQuote();
            },
          ),
        ),
      );
  }

  /// F3. Tạo đơn rồi mở VNPay (hoặc ghi danh ngay nếu tổng bằng 0)
  Future<void> _confirmCheckout() async {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      // Luôn báo giá lại ngay trước khi thanh toán để chắc chắn giá và mã còn hiệu lực
      final ok = await _refreshQuote();
      if (!mounted) return;
      if (!ok || cart.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final courseIds = cart.ids;
      final order = await _orderRepo.createOrder(courseIds, couponCode: _appliedCode);
      if (!mounted) return;
      final orderId = JsonUtils.asString(order['orderId']);
      final requiresPayment = JsonUtils.asBool(order['requiresPayment'], fallback: true);
      final paymentUrl = JsonUtils.asStringOrNull(order['paymentUrl']);
      setState(() => _isProcessing = false);

      final Widget next = (!requiresPayment || paymentUrl == null)
          ? PaymentResultScreen(orderId: orderId, courseIds: courseIds)
          : PaymentWebViewScreen(orderId: orderId, paymentUrl: paymentUrl, courseIds: courseIds);
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => next));
      if (mounted) _refreshQuote();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        if (e.code == 'COUPON_INVALID') {
          // Mã hết hiệu lực lúc tạo đơn: bỏ mã và báo ngay dưới ô nhập mã
          _couponError = e.message;
          _appliedCode = null;
        }
      });
      showErrorSnackBar(context, e);
      // ALREADY_OWNED / COURSE_UNAVAILABLE / COUPON_INVALID: giỏ có thể đã đổi, báo giá lại để hiện đúng
      _refreshQuote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

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
      body: items.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
                      onRefresh: _refreshQuote,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.all(AppDimens.p16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_quoting) const LinearProgressIndicator(minHeight: 3, color: AppColors.primary),
                            if (_quoteError != null) _buildQuoteErrorBanner(),
                            Text(
                              'Khóa học đã chọn (${items.length})',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            ...items.map(_buildCartItem),
                            const SizedBox(height: 20.0),
                            _buildCouponSection(),
                            const SizedBox(height: 20.0),
                            if (_quote != null) ...[
                              _buildPriceSummary(),
                              const SizedBox(height: 20.0),
                            ],
                            _buildPaymentMethods(),
                            const SizedBox(height: 28.0),
                            AppButton(
                              text: _quote == null
                                  ? 'Xác nhận thanh toán'
                                  : (_quote!.total <= 0
                                      ? 'Đăng ký học miễn phí'
                                      : 'Xác nhận thanh toán (${AppFormatters.formatCurrency(_quote!.total)})'),
                              isLoading: _isProcessing,
                              icon: const Icon(Icons.lock_outline_rounded, size: 20),
                              onPressed: (_quote == null || _quoting || _isProcessing) ? null : _confirmCheckout,
                            ),
                            const SizedBox(height: 20.0),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildQuoteErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppDimens.radiusInput,
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Text(
              'Không cập nhật được giá: ${errorMessage(_quoteError)}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(onPressed: _refreshQuote, child: const Text('Thử lại')),
        ],
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
  Widget _buildCartItem(CartItem course) {
    // Giá hiển thị là giá server báo ở lần báo giá gần nhất; chưa có thì dùng giá lưu trên máy
    final price = _quote?.prices[course.id] ?? course.price;
    final original = course.originalPrice;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDimens.radiusCard,
        child: InkWell(
          borderRadius: AppDimens.radiusCard,
          onTap: () => CourseDetailScreen.open(context, course.toCourse(), ClickSource.home),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p12),
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
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceSubtle,
                  child: const Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted),
                ),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.0,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(price),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (original > price) ...[
                      Text(
                        AppFormatters.formatCurrency(original),
                        style: AppTypography.captionTiny.copyWith(
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
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
          ),
        ),
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
                    hintText: 'Nhập mã giảm giá',
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
                    // Theme app đặt nút rộng vô hạn; trong một hàng ngang phải chặn lại, nếu không cả trang không dựng được
                    minimumSize: const Size(96, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimens.radiusButton,
                    ),
                  ),
                  onPressed: _quoting ? null : _applyCoupon,
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _quoting ? null : _openCouponWallet,
              icon: const Icon(Icons.local_activity_outlined, size: 18),
              label: const Text('Chọn mã từ ví của tôi'),
            ),
          ),
          if (_appliedCode != null) ...[
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '✓ Đã áp dụng mã $_appliedCode',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(onPressed: _removeCoupon, child: const Text('Bỏ mã')),
              ],
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
                AppFormatters.formatCurrency(_quote?.subTotal ?? 0),
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if ((_quote?.discount ?? 0) > 0) ...[
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khuyến mãi (${_appliedCode ?? ''}):',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.success),
                ),
                Text(
                  '-${AppFormatters.formatCurrency(_quote?.discount ?? 0)}',
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
            children: [
              Expanded(
                child: Text(
                  'Tổng thanh toán:',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppFormatters.formatCurrency(_quote?.total ?? 0),
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Phương thức thanh toán lấy từ server (F1 paymentMethods). Chỉ Thẻ ATM nội địa (Napas) dùng được ở VNPay Sandbox.
  Widget _buildPaymentMethods() {
    final fromServer = _quote?.paymentMethods ?? const <PaymentMethodOption>[];
    final methods = fromServer.isNotEmpty
        ? fromServer
        : const [
            PaymentMethodOption(id: ApiConfig.paymentMethodAtm, name: 'Thẻ ATM nội địa', enabled: true),
            PaymentMethodOption(
                id: 'Visa/Mastercard',
                name: 'Thẻ quốc tế',
                enabled: false,
                reason: 'Chưa hỗ trợ ở môi trường thử nghiệm VNPay Sandbox'),
            PaymentMethodOption(
                id: 'MoMo/VNPay',
                name: 'Ví điện tử / quét QR',
                enabled: false,
                reason: 'Chưa hỗ trợ ở môi trường thử nghiệm VNPay Sandbox'),
          ];

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
          for (final m in methods)
            _buildPaymentTile(
              m.name,
              m.enabled ? Icons.credit_card_rounded : Icons.credit_card_off_rounded,
              m.enabled ? AppColors.primary : AppColors.textMuted,
              selected: m.id == ApiConfig.paymentMethodAtm && m.enabled,
              disabled: !m.enabled,
              note: m.enabled ? 'Môi trường thử nghiệm (Sandbox), không trừ tiền thật' : m.reason,
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(
    String title,
    IconData icon,
    Color iconColor, {
    bool selected = false,
    bool disabled = false,
    String? note,
  }) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? AppColors.primary : AppColors.textHeading,
                          ),
                        ),
                      ),
                      if (disabled) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Chưa hỗ trợ',
                              style: AppTypography.captionTiny
                                  .copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  if (note != null)
                    Text(note, style: AppTypography.captionTiny.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}


/// Bottom sheet "Ví mã giảm giá" (F2 `GET /coupons/my?courseIds=...`).
/// Tên trường đọc linh hoạt: code, title/description, isApplicable/usable, reason/message, expiresAt.
class _CouponWalletSheet extends StatefulWidget {
  final List<String> courseIds;
  final OrderRepository repo;

  const _CouponWalletSheet({required this.courseIds, required this.repo});

  @override
  State<_CouponWalletSheet> createState() => _CouponWalletSheetState();
}

class _CouponWalletSheetState extends State<_CouponWalletSheet> {
  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.repo.myCoupons(widget.courseIds);
      if (!mounted) return;
      setState(() {
        _coupons = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      padding: const EdgeInsets.all(AppDimens.p24),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: AppDimens.radiusSheet),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ví mã giảm giá',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 18.0)),
          const SizedBox(height: AppDimens.p12),
          Flexible(
            child: _loading
                ? const Padding(padding: EdgeInsets.all(AppDimens.p24), child: LoadingView())
                : _error != null
                    ? ErrorView(error: _error, onRetry: _load)
                    : _coupons.isEmpty
                        ? const EmptyView(
                            icon: Icons.local_activity_outlined,
                            title: 'Ví chưa có mã giảm giá',
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _coupons.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p8),
                            itemBuilder: (context, index) => _buildCoupon(_coupons[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupon(Map<String, dynamic> c) {
    final code = JsonUtils.asString(c['code']);
    final title = JsonUtils.asString(c['title'] ?? c['description'] ?? c['name']);
    final usable = JsonUtils.asBool(c['isApplicable'] ?? c['usable'] ?? c['canUse'] ?? c['applicable'], fallback: true);
    final discountText = JsonUtils.asString(c['discountText']);
    final reason = JsonUtils.asString(c['reason'] ?? c['message']);
    final expires = JsonUtils.asDate(c['expiresAt'] ?? c['endDate']);

    return Opacity(
      opacity: usable ? 1 : 0.5,
      child: InkWell(
        onTap: usable && code.isNotEmpty ? () => Navigator.of(context).pop(code) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.p12),
          decoration: BoxDecoration(
            color: usable ? AppColors.primaryLight : AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: usable ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.confirmation_num_outlined, color: AppColors.primary),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w800)),
                    if (discountText.isNotEmpty)
                      Text(discountText, style: AppTypography.captionTiny.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    if (title.isNotEmpty)
                      Text(title, style: AppTypography.captionTiny.copyWith(color: AppColors.textSecondary)),
                    if (expires != null)
                      Text('HSD: ${expires.day.toString().padLeft(2, '0')}/${expires.month.toString().padLeft(2, '0')}/${expires.year}',
                          style: AppTypography.captionTiny.copyWith(color: AppColors.textMuted)),
                    if (!usable && reason.isNotEmpty)
                      Text(reason, style: AppTypography.captionTiny.copyWith(color: AppColors.error)),
                  ],
                ),
              ),
              if (usable) const Text('Dùng', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
