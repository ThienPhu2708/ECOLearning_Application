import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/google_sign_in_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../interests/interest_picker_screen.dart';
import 'forgot_password_sheet.dart';
import 'register_screen.dart';

/// Màn hình Đăng nhập (UC1 & Section 4.1)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailError;
  String? _passwordError;

  Future<void> _onLogin() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Vui lòng nhập email' : null;
      _passwordError = pass.isEmpty ? 'Vui lòng nhập mật khẩu' : null;
      _errorMessage = null;
    });
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ Email và Mật khẩu!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().login(email, pass);
      if (!mounted) return;
      await InterestGate.enter(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _emailError = e.fieldError('email');
        _passwordError = e.fieldError('password');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chưa đăng nhập được. Vui lòng thử lại.';
      });
    }
  }

  /// Đăng nhập Google (A12): lấy ID token từ Google rồi gửi cho server
  Future<void> _onGoogleLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final idToken = await GoogleSignInService.instance.signIn();
      if (idToken == null) {
        if (mounted) setState(() => _isLoading = false);
        return; // người dùng tự hủy
      }
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.applySession(await AuthRepository().loginWithGoogle(idToken));
      if (!mounted) return;
      await InterestGate.enter(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.statusCode == 404
            ? 'Máy chủ chưa hỗ trợ đăng nhập Google.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chưa đăng nhập được. Vui lòng thử lại.';
      });
    }
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
                    // Logo giống website: icon sách mở (bi-book-half)
                    child: const Icon(
                      BootstrapIcons.book_half,
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
                  decoration: InputDecoration(
                    hintText: 'Nhập email...',
                    errorText: _emailError,
                    prefixIcon: const Icon(
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
                    errorText: _passwordError,
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
                  onPressed: _isLoading ? null : _onGoogleLogin,
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
