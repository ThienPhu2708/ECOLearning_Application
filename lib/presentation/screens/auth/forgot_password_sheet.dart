import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/app_button.dart';

/// Điểm vào quên mật khẩu: mở màn hình 3 bước [ForgotPasswordScreen].
class ForgotPasswordSheet {
  ForgotPasswordSheet._();

  static Future<void> show(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }
}

/// Quên mật khẩu qua OTP (A5, A6), cùng kiểu với màn Đăng ký:
/// Bước 1 nhập email → gửi OTP (A5), Bước 2 nhập mã OTP, Bước 3 đặt mật khẩu mới (A6).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _repo = AuthRepository();
  int _step = 1;
  bool _busy = false;

  // Bước 1
  final _emailController = TextEditingController();
  String? _step1Error;

  // Bước 2
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _countdown = 0;
  Timer? _timer;
  String? _step2Error;

  // Bước 3
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _step3Error;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        t.cancel();
      }
    });
  }

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
  }

  /// A5. Gửi (hoặc gửi lại) mã OTP về email
  Future<void> _sendOtp({required bool resend}) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _step1Error = 'Vui lòng nhập địa chỉ email hợp lệ');
      return;
    }
    setState(() {
      _busy = true;
      _step1Error = null;
      _step2Error = null;
    });
    try {
      await _repo.sendForgotOtp(email);
      if (!mounted) return;
      if (resend) _clearOtp();
      setState(() {
        _busy = false;
        _step = 2;
      });
      _startCountdown();
      _otpFocusNodes.first.requestFocus();
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.fieldError('email') ?? e.message;
      setState(() {
        _busy = false;
        if (resend) {
          _step2Error = msg;
        } else {
          _step1Error = msg;
        }
      });
    }
  }

  // Bước 2 -> 3: kiểm tra mã ngay tại đây. Nếu server chưa có API kiểm tra thì mã được kiểm ở bước đặt mật khẩu (A6)
  Future<void> _onOtpNext() async {
    if (_otp.length < 6) {
      setState(() => _step2Error = 'Vui lòng nhập đủ 6 chữ số mã xác thực');
      return;
    }
    setState(() {
      _busy = true;
      _step2Error = null;
    });
    try {
      final valid = await _repo.verifyForgotOtp(
        email: _emailController.text,
        otp: _otp,
      );
      if (!mounted) return;
      if (valid == false) {
        setState(() {
          _busy = false;
          _step2Error = 'Mã xác thực không đúng hoặc đã hết hạn';
        });
        return;
      }
      _timer?.cancel();
      setState(() {
        _busy = false;
        _step = 3;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step2Error = e.fieldError('otp') ?? e.message;
      });
    }
  }

  bool _strongPassword(String p) =>
      p.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(p) &&
      RegExp(r'[0-9]').hasMatch(p) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(p);

  /// A6. Đặt mật khẩu mới
  Future<void> _reset() async {
    final pass = _passController.text;
    if (!_strongPassword(pass)) {
      setState(
        () => _step3Error =
            'Mật khẩu tối thiểu 8 ký tự, gồm chữ in hoa, chữ số và ký tự đặc biệt',
      );
      return;
    }
    if (pass != _confirmController.text) {
      setState(() => _step3Error = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      _busy = true;
      _step3Error = null;
    });
    try {
      await _repo.resetPassword(
        email: _emailController.text,
        otp: _otp,
        newPassword: pass,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppNavigator.showMessage(
        'Đặt lại mật khẩu thành công. Hãy đăng nhập bằng mật khẩu mới.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final otpProblem =
          e.fieldError('otp') != null || e.code.toUpperCase().contains('OTP');
      setState(() {
        _busy = false;
        if (otpProblem) {
          // Mã sai / hết hạn: quay lại bước nhập mã
          _step = 2;
          _step2Error = e.fieldError('otp') ?? e.message;
          _clearOtp();
        } else {
          _step3Error =
              e.fieldError('newPassword') ??
              e.fieldError('password') ??
              e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Quên mật khẩu',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(1, 'Email'),
                  _buildStepLine(1),
                  _buildStepIndicator(2, 'Xác thực OTP'),
                  _buildStepLine(2),
                  _buildStepIndicator(3, 'Mật khẩu'),
                ],
              ),
              const SizedBox(height: 32.0),
              if (_step == 1) _buildStep1(),
              if (_step == 2) _buildStep2(),
              if (_step == 3) _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _step >= step;
    final isCurrent = _step == step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.surfaceSubtle,
            border: Border.all(
              color: isCurrent ? AppColors.primary : AppColors.border,
              width: 2.0,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: AppTypography.captionTiny.copyWith(
            color: isActive ? AppColors.primary : AppColors.textMuted,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    return Expanded(
      child: Container(
        height: 2.0,
        margin: const EdgeInsets.only(bottom: 16.0, left: 4.0, right: 4.0),
        color: _step > afterStep ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _errorText(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        message,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 1: Nhập email',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Nhập email đã đăng ký để nhận mã xác thực OTP khôi phục quyền truy cập tài khoản.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24.0),
        _errorText(_step1Error),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Nhập email của bạn...',
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 28.0),
        AppButton(
          text: 'Gửi mã xác thực',
          isLoading: _busy,
          onPressed: () => _sendOtp(resend: false),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 2: Xác thực mã OTP',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Mã xác thực 6 số đã được gửi tới email ${_emailController.text.trim()}. Vui lòng nhập mã bên dưới:',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24.0),
        _errorText(_step2Error),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (val.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24.0),
        Center(
          child: _countdown > 0
              ? Text(
                  'Gửi lại mã sau $_countdown giây',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : TextButton(
                  onPressed: _busy ? null : () => _sendOtp(resend: true),
                  child: Text(
                    'Gửi lại mã OTP',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 24.0),
        AppButton(text: 'Tiếp tục', isLoading: _busy, onPressed: _onOtpNext),
        Center(
          child: TextButton(
            onPressed: _busy ? null : () => setState(() => _step = 1),
            child: const Text('Đổi email khác'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 3: Mật khẩu mới',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Mật khẩu tối thiểu 8 ký tự, gồm chữ in hoa, chữ số và ký tự đặc biệt.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24.0),
        _errorText(_step3Error),
        TextField(
          controller: _passController,
          obscureText: _obscurePass,
          decoration: InputDecoration(
            hintText: 'Mật khẩu mới',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textMuted,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            hintText: 'Nhập lại mật khẩu mới',
            prefixIcon: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.textMuted,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 28.0),
        AppButton(
          text: 'Đặt lại mật khẩu',
          isLoading: _busy,
          onPressed: _reset,
        ),
      ],
    );
  }
}
