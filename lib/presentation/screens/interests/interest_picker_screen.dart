import 'package:flutter/material.dart';

import '../../widgets/under_construction.dart';

/// Chọn lĩnh vực quan tâm (Task_Tuan10.docx mục 2.2). Phụ trách: Thư – việc T-3 – API C2, C3, C4.
/// Hiện lần đầu sau khi đăng nhập nếu needSurvey = true. Chọn tối đa 3 lĩnh vực, có nút Bỏ qua.
class InterestPickerScreen extends StatelessWidget {
  const InterestPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnderConstructionScaffold(
      title: 'Chọn lĩnh vực quan tâm',
      owner: 'Thư',
      taskCode: 'T-3',
      apiCodes: 'C2, C3, C4',
      description: 'Hiện lần đầu sau khi đăng nhập nếu needSurvey = true. Chọn tối đa 3 lĩnh vực, có nút Bỏ qua.',
    );
  }
}
