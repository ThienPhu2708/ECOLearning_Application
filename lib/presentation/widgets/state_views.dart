import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import 'app_button.dart';

/// 3 trạng thái bắt buộc của mọi màn hình dùng API (Task_Tuan10.docx mục 9):
/// đang tải [LoadingView], danh sách rỗng [EmptyView], lỗi [ErrorView] có nút "Thử lại".

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: AppDimens.p12),
            Text(message!, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: AppDimens.p16),
            Text(title, textAlign: TextAlign.center, style: AppTypography.titleMedium),
            if (message != null) ...[
              const SizedBox(height: AppDimens.p8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppDimens.p20),
              AppButton(text: actionText!, onPressed: onAction, width: 220),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;

  const ErrorView({super.key, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isNetwork = error is ApiException && (error as ApiException).isNetwork;
    return EmptyView(
      icon: isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: isNetwork ? 'Lỗi kết nối mạng' : 'Không tải được dữ liệu',
      message: errorMessage(error),
      actionText: onRetry == null ? null : 'Thử lại',
      onAction: onRetry,
    );
  }
}

/// Câu thông báo lỗi tiếng Việt cho người dùng từ bất kỳ lỗi nào
String errorMessage(Object? error) {
  if (error is ApiException) return error.message;
  return 'Có lỗi xảy ra, vui lòng thử lại.';
}

/// Hiện lỗi dạng SnackBar (dùng khi thao tác thất bại nhưng vẫn ở lại màn hình, vd: thả tim, áp mã)
void showErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(errorMessage(error)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
}
