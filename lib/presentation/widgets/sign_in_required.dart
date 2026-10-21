import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SignInRequired extends StatelessWidget {
  const SignInRequired({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 40),
          SizedBox(height: 16),
          Text(
            'Cần đăng nhập',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Đăng nhập để xem khóa học và dữ liệu tài khoản của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
