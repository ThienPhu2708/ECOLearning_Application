import 'package:flutter/material.dart';

import '../../widgets/under_construction.dart';

/// Kết quả thanh toán (Task_Tuan10.docx mục 2.2). Phụ trách: Thư – việc T-7 – API F4.
/// Hiện trạng thái đơn: paid → thành công, xóa khóa đã mua khỏi giỏ, nút "Vào học"; failed / expired → thất bại, nút "Thử lại".
class PaymentResultScreen extends StatelessWidget {
  final String orderId;

  const PaymentResultScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return const UnderConstructionScaffold(
      title: 'Kết quả thanh toán',
      owner: 'Thư',
      taskCode: 'T-7',
      apiCodes: 'F4',
      description: 'Hiện trạng thái đơn: paid → thành công, xóa khóa đã mua khỏi giỏ, nút "Vào học"; failed / expired → thất bại, nút "Thử lại".',
    );
  }
}
