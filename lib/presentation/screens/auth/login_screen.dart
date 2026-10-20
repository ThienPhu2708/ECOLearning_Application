import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/app_button.dart';
import '../main_navigation.dart';
import 'forgot_password_sheet.dart';
import 'register_screen.dart';

/// Màn hình Đăng nhập (UC1 & Section 4.1)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController =
      TextEditingController(text: 'anh675262@gmail.com');
  final _passwordController = TextEditingController(text: '12345678@Abc');
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _onLogin() {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ Email và Mật khẩu!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Giả lập xác thực người dùng
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    });
  }

  void _onGoogleLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppDimens.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & Header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 40.0,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                Center(
                  child: Text(
                    'Đăng nhập tài khoản',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Center(
                  child: Text(
                    'Chào mừng học viên đã quay trở lại !',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),

                // Cảnh báo lỗi nếu có
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimens.p12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: AppDimens.radiusInput,
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimens.p8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],

                // Input Email
                Text(
                  'Email của bạn',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Nhập email...',
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Input Password
                Text(
                  'Mật khẩu',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu...',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),

                // Quên mật khẩu link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ForgotPasswordSheet.show(context),
                    child: Text(
                      'Quên mật khẩu?',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Nút Đăng nhập chính
                AppButton(
                  text: 'Đăng nhập',
                  isLoading: _isLoading,
                  onPressed: _onLogin,
                ),
                const SizedBox(height: 16.0),

                // Đăng nhập nhanh Google
                AppButton(
                  text: 'Đăng nhập nhanh với Google',
                  type: AppButtonType.secondary,
                  icon: const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                  onPressed: _onGoogleLogin,
                ),
                const SizedBox(height: 24.0),

                // Điều hướng sang Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Đăng ký ngay',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
