import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';

/// Khung tạm cho màn hình chưa làm. Ghi rõ người phụ trách, mã việc và API dùng
/// (theo Task_Tuan10.docx) để mở ra là biết cần làm gì. Làm xong màn hình thì bỏ widget này.
class UnderConstructionScaffold extends StatelessWidget {
  final String title;
  final String owner;
  final String taskCode;
  final String apiCodes;
  final String description;

  const UnderConstructionScaffold({
    super.key,
    required this.title,
    required this.owner,
    required this.taskCode,
    required this.apiCodes,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: AppDimens.p16),
              Text('Màn hình đang xây dựng', style: AppTypography.titleMedium),
              const SizedBox(height: AppDimens.p8),
              Text(description,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppDimens.p16),
              Text('Phụ trách: $owner  •  Việc: $taskCode  •  API: $apiCodes',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
