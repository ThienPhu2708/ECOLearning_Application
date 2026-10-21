import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../core/config/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import 'payment_result_screen.dart';

/// Thanh toán VNPay (Task_Tuan10.docx mục 2.2). Phụ trách: Thư – việc T-7 – API F3, F4.
/// Mở paymentUrl (F3) trong WebView. Gặp địa chỉ chứa ApiConfig.paymentResultPath thì đóng WebView
/// (không tải trang đó) và sang màn kết quả, nơi gọi F4 để lấy trạng thái thật của đơn (mục 6.9).
class PaymentWebViewScreen extends StatefulWidget {
  final String orderId;
  final String paymentUrl;

  /// Các khóa học trong đơn, để màn kết quả xóa khỏi giỏ khi đơn `paid`
  final List<String> courseIds;

  const PaymentWebViewScreen({
    super.key,
    required this.orderId,
    required this.paymentUrl,
    this.courseIds = const [],
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _finished = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (_isResultUrl(request.url)) {
            _finish();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
        // Một số điện thoại Android chưa có gốc chứng chỉ mới của VNPay Sandbox (Sectigo R46) nên WebView từ chối
        // và trang trắng. Chỉ riêng môi trường thử nghiệm của VNPay (không trừ tiền thật) mới được bỏ qua lỗi này;
        // mọi trang khác vẫn bị từ chối.
        onSslAuthError: (error) {
          final failing = Uri.tryParse(error.platform is AndroidSslAuthError
                  ? (error.platform as AndroidSslAuthError).url
                  : '')
              ?.host;
          if (_isSandbox && failing != null && failing.endsWith(_vnpayDomain)) {
            error.proceed();
          } else {
            error.cancel();
            if (mounted) {
              setState(() => _loadError = 'Kết nối tới trang thanh toán không an toàn nên đã bị chặn.');
            }
          }
        },
        onWebResourceError: (error) {
          // Chỉ báo lỗi của trang chính, bỏ qua lỗi ảnh / script phụ
          if (error.isForMainFrame ?? true) {
            if (mounted) setState(() => _loadError = 'Không tải được trang thanh toán. Kiểm tra mạng và thử lại.');
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  static const _vnpayDomain = 'vnpayment.vn';

  /// Trang thanh toán thử nghiệm của VNPay (sandbox.vnpayment.vn)
  bool get _isSandbox => Uri.tryParse(widget.paymentUrl)?.host == 'sandbox.$_vnpayDomain';

  bool _isResultUrl(String url) => url.contains(ApiConfig.paymentResultPath);

  /// Sang màn kết quả. Không kết luận thành công từ URL callback: màn kết quả hỏi lại server bằng F4.
  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentResultScreen(orderId: widget.orderId, courseIds: widget.courseIds),
      ),
    );
  }

  /// Người dùng đóng WebView giữa chừng: vẫn hỏi server trạng thái đơn (F4)
  Future<void> _confirmClose() async {
    final close = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dừng thanh toán?'),
        content: const Text('Đơn hàng sẽ được giữ trong 15 phút nếu bạn chưa thanh toán xong.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Tiếp tục thanh toán')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Đóng')),
        ],
      ),
    );
    if (close == true) _finish();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Thanh toán VNPay', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: _confirmClose),
          bottom: _progress < 100 && _loadError == null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primaryLight,
                  ),
                )
              : null,
        ),
        body: _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(_loadError!, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _loadError = null);
                          _controller.loadRequest(Uri.parse(widget.paymentUrl));
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
