import 'package:flutter/material.dart';

import '../../widgets/under_construction.dart';

/// Quiz cuối khóa (Task_Tuan10.docx mục 2.2). Phụ trách: Ngọc – việc N-5 – API H1, H2.
/// Số câu, thời gian, ngưỡng đạt, lượt còn lại. canStart = false thì hiện reason. Nút "Bắt đầu" / "Tiếp tục làm bài".
class QuizIntroScreen extends StatelessWidget {
  final String courseId;

  const QuizIntroScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return const UnderConstructionScaffold(
      title: 'Quiz cuối khóa',
      owner: 'Ngọc',
      taskCode: 'N-5',
      apiCodes: 'H1, H2',
      description: 'Số câu, thời gian, ngưỡng đạt, lượt còn lại. canStart = false thì hiện reason. Nút "Bắt đầu" / "Tiếp tục làm bài".',
    );
  }
}
