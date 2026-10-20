import 'package:flutter/material.dart';

import '../../widgets/under_construction.dart';

/// Khóa học yêu thích (Task_Tuan10.docx mục 2.2). Phụ trách: Ngọc – việc N-8 – API D1, D2.
/// Danh sách khóa đã thả tim (phân trang), bỏ tim ngay trong danh sách.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnderConstructionScaffold(
      title: 'Khóa học yêu thích',
      owner: 'Ngọc',
      taskCode: 'N-8',
      apiCodes: 'D1, D2',
      description: 'Danh sách khóa đã thả tim (phân trang), bỏ tim ngay trong danh sách.',
    );
  }
}
