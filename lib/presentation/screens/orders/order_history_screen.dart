import 'package:flutter/material.dart';

import '../../widgets/under_construction.dart';

/// Lịch sử đơn hàng (Task_Tuan10.docx mục 2.2). Phụ trách: Ngọc – việc N-8 – API F5, F4.
/// Thay hộp thoại dữ liệu giả trong Hồ sơ. Danh sách đơn (phân trang), bấm vào xem chi tiết đơn (F4).
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnderConstructionScaffold(
      title: 'Lịch sử đơn hàng',
      owner: 'Ngọc',
      taskCode: 'N-8',
      apiCodes: 'F5, F4',
      description: 'Thay hộp thoại dữ liệu giả trong Hồ sơ. Danh sách đơn (phân trang), bấm vào xem chi tiết đơn (F4).',
    );
  }
}
