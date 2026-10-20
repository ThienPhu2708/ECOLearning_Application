import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/app_button.dart';

/// Modal Bottom Sheet Quên mật khẩu theo QuyChuanThietKe_App.md Mục 4.1
class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ForgotPasswordSheet(),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSent = false;
  String? _errorText;

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorText = 'Vui lòng nhập địa chỉ email hợp lệ';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSent = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: AppDimens.p24,
        left: AppDimens.p24,
        right: AppDimens.p24,
        bottom: AppDimens.p24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusSheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999.0),
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          if (!_isSent) ...[
            Text(
              'Quên mật khẩu?',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Nhập email của bạn để nhận mã xác thực OTP khôi phục quyền truy cập tài khoản.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20.0),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Nhập email của bạn...',
                prefixIcon: const Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.textMuted,
                ),
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 24.0),

            AppButton(
              text: 'Gửi mã xác thực',
              onPressed: _submit,
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Đã gửi mã thành công!',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Mã xác thực đã được gửi đến ${_emailController.text}. Vui lòng kiểm tra hòm thư của bạn.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  AppButton(
                    text: 'Đóng',
                    type: AppButtonType.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
