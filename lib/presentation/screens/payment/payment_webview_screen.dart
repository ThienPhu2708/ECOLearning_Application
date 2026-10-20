import 'package:flutter/material.dart';

import '../../widgets/under_construction.dart';

/// Thanh toán VNPay (Task_Tuan10.docx mục 2.2). Phụ trách: Thư – việc T-7 – API F3, F4.
/// Mở paymentUrl (F3) trong WebView. Gặp địa chỉ chứa ApiConfig.paymentResultPath thì đóng WebView và gọi F4 (mục 6.9).
class PaymentWebViewScreen extends StatelessWidget {
  final String orderId;
  final String paymentUrl;

  const PaymentWebViewScreen({super.key, required this.orderId, required this.paymentUrl});

  @override
  Widget build(BuildContext context) {
    return const UnderConstructionScaffold(
      title: 'Thanh toán VNPay',
      owner: 'Thư',
      taskCode: 'T-7',
      apiCodes: 'F3, F4',
      description: 'Mở paymentUrl (F3) trong WebView. Gặp địa chỉ chứa ApiConfig.paymentResultPath thì đóng WebView và gọi F4 (mục 6.9).',
    );
  }
}
