import 'package:flutter/material.dart';

import '../../widgets/under_construction.dart';

/// Kết quả quiz (Task_Tuan10.docx mục 2.2). Phụ trách: Ngọc – việc N-5 – API H4, H5.
/// Điểm (thang 10), số câu đúng, đạt / chưa đạt. Đạt thì nút "Nhận chứng chỉ" (H5).
class QuizResultScreen extends StatelessWidget {
  final String courseId;
  final Map<String, dynamic> result;

  const QuizResultScreen({super.key, required this.courseId, required this.result});

  @override
  Widget build(BuildContext context) {
    return const UnderConstructionScaffold(
      title: 'Kết quả quiz',
      owner: 'Ngọc',
      taskCode: 'N-5',
      apiCodes: 'H4, H5',
      description: 'Điểm (thang 10), số câu đúng, đạt / chưa đạt. Đạt thì nút "Nhận chứng chỉ" (H5).',
    );
  }
}
