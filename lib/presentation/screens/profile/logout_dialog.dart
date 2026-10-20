import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/app_button.dart';
import '../auth/login_screen.dart';

/// Modal Hộp thoại xác nhận Đăng xuất theo QuyChuanThietKe_App.md Mục 4.8 & UC2
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LogoutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppDimens.radiusCard),
      contentPadding: const EdgeInsets.all(AppDimens.p24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 32,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Xác nhận đăng xuất',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Bạn có chắc chắn muốn kết thúc phiên làm việc của tài khoản này?',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Hủy',
                  type: AppButtonType.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: AppButton(
                  text: 'Đăng xuất',
                  type: AppButtonType.danger,
                  onPressed: () {
                    Navigator.of(context).pop(); // pop dialog
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
