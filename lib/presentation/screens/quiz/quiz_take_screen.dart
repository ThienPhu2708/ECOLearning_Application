import 'package:flutter/material.dart';

import '../../widgets/under_construction.dart';

/// Làm bài quiz (Task_Tuan10.docx mục 2.2). Phụ trách: Ngọc – việc N-5 – API H2, H3, H4.
/// Đếm giờ theo expiresAt, chọn đáp án (lưu nháp H3), nộp bài H4. Hết giờ thì tự nộp.
class QuizTakeScreen extends StatelessWidget {
  final String courseId;

  const QuizTakeScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return const UnderConstructionScaffold(
      title: 'Làm bài quiz',
      owner: 'Ngọc',
      taskCode: 'N-5',
      apiCodes: 'H2, H3, H4',
      description: 'Đếm giờ theo expiresAt, chọn đáp án (lưu nháp H3), nộp bài H4. Hết giờ thì tự nộp.',
    );
  }
}
