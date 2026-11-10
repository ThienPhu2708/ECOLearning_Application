import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/order_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import '../main_navigation.dart';

/// Kết quả thanh toán (Task_Tuan10.docx mục 2.2). Phụ trách: Thư – việc T-7 – API F4.
/// Trạng thái luôn lấy từ server (F4), không dựa vào URL callback của VNPay:
/// - paid: thành công, xóa khóa đã mua khỏi giỏ, nút "Vào học".
/// - failed / expired / cancelled: thất bại, nút "Thử thanh toán lại" (giỏ giữ nguyên).
/// - pending: chưa thanh toán, cho kiểm tra lại hoặc thanh toán lại.
class PaymentResultScreen extends StatefulWidget {
  final String orderId;

  /// Khóa học trong đơn lúc tạo, dùng để dọn giỏ khi đơn `paid` (kết hợp với danh sách khóa server trả về)
  final List<String> courseIds;

  const PaymentResultScreen({super.key, required this.orderId, this.courseIds = const []});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  final _repo = OrderRepository();

  bool _loading = true;
  Object? _error;
  Map<String, dynamic> _order = const {};

  String get _status => JsonUtils.asString(_order['status']).toLowerCase();
  bool get _paid => _status == 'paid';
  bool get _pending => _status == 'pending';

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
      final order = await _repo.order(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
      if (_paid) await _onPaid();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// Chỉ xóa khỏi giỏ khi server xác nhận đơn đã thanh toán
  Future<void> _onPaid() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final ids = <String>{...widget.courseIds};
    for (final item in JsonUtils.asMapList(_order['items'])) {
      final id = JsonUtils.asString(item['courseId'] ?? item['id']);
      if (id.isNotEmpty) ids.add(id);
    }
    await cart.removeAll(ids);
    auth.refreshUser().catchError((_) {});
  }

  void _goToMyCourses() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 2)),
      (_) => false,
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Kết quả thanh toán'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _loading
            ? const LoadingView(message: 'Đang xác nhận thanh toán...')
            : _error != null
                ? ErrorView(error: _error, onRetry: _load)
                : _buildResult(),
      ),
    );
  }

  Widget _buildResult() {
    final IconData icon;
    final Color color;
    final Color bg;
    final String title;
    final String message;
    if (_paid) {
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
      bg = AppColors.successLight;
      title = 'Thanh toán thành công!';
      message = 'Bạn đã sở hữu khóa học. Bắt đầu lộ trình học ngay hôm nay!';
    } else if (_pending) {
      icon = Icons.hourglass_top_rounded;
      color = AppColors.warning;
      bg = AppColors.warningLight;
      title = 'Đơn hàng chưa được thanh toán';
      message = 'Bạn chưa hoàn tất thanh toán. Đơn được giữ trong 15 phút, bạn có thể thanh toán lại.';
    } else {
      icon = Icons.cancel_rounded;
      color = AppColors.error;
      bg = AppColors.errorLight;
      title = _status == 'expired' ? 'Đơn hàng đã hết hạn' : 'Thanh toán không thành công';
      message = 'Không có khoản tiền nào bị trừ. Giỏ hàng của bạn vẫn được giữ nguyên để thử lại.';
    }

    final total = JsonUtils.asDouble(_order['total']);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 56),
            ),
            const SizedBox(height: AppDimens.p20),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppDimens.p8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
            if (_order.isNotEmpty) ...[
              const SizedBox(height: AppDimens.p16),
              Text('Mã đơn: ${widget.orderId}',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
              if (total > 0 || _paid)
                Text('Tổng tiền: ${AppFormatters.formatCurrency(total)}',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: AppDimens.p32),
            if (_paid) ...[
              AppButton(text: 'Vào học', onPressed: _goToMyCourses),
              const SizedBox(height: AppDimens.p12),
              AppButton(text: 'Về trang chủ', type: AppButtonType.secondary, onPressed: _goHome),
            ] else ...[
              AppButton(
                text: 'Thử thanh toán lại',
                // Quay về giỏ hàng, nơi tạo đơn / link thanh toán mới
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppDimens.p12),
              if (_pending) ...[
                AppButton(text: 'Kiểm tra lại trạng thái', type: AppButtonType.secondary, onPressed: _load),
                const SizedBox(height: AppDimens.p12),
              ],
              AppButton(text: 'Về trang chủ', type: AppButtonType.ghost, onPressed: _goHome),
            ],
          ],
        ),
      ),
    );
  }
}
