import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../interests/interest_picker_screen.dart';

/// Màn hình Đăng ký tài khoản Học viên quy trình 3 bước (UC1 & Section 4.1)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 1;
  final AuthRepository _authRepo = AuthRepository();
  bool _busy = false;

  // Controllers Step 1
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _step1Error;

  // Controllers Step 2
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());
  int _countdown = 60;
  Timer? _timer;
  String? _step2Error;

  // Controllers Step 3
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  String? _step3Error;

  @override
  void initState() {
    super.initState();
  }

  void _startOtpTimer() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // Bước 1 -> 2: gửi OTP về email (A2)
  Future<void> _onStep1Next() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (name.isEmpty) {
      setState(() => _step1Error = 'Vui lòng nhập họ và tên của bạn');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _step1Error = 'Vui lòng nhập địa chỉ email hợp lệ');
      return;
    }

    await _sendOtp(goNext: true);
  }

  Future<void> _sendOtp({bool goNext = false}) async {
    setState(() {
      _busy = true;
      _step1Error = null;
      _step2Error = null;
    });
    try {
      await _authRepo.sendRegisterOtp(
        fullName: _nameController.text,
        email: _emailController.text.toLowerCase(),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (goNext) _currentStep = 2;
      });
      _startOtpTimer();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        final msg = e.fieldError('email') ?? e.message;
        if (goNext) {
          _step1Error = msg;
        } else {
          _step2Error = msg;
        }
      });
    }
  }

  // Bước 2 -> 3: xác minh OTP (A3)
  Future<void> _onStep2Verify() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _step2Error = 'Vui lòng nhập đủ 6 chữ số mã xác thực');
      return;
    }

    setState(() {
      _busy = true;
      _step2Error = null;
    });
    try {
      final valid = await _authRepo.verifyRegisterOtp(email: _emailController.text.toLowerCase(), otp: otp);
      if (!mounted) return;
      if (!valid) {
        setState(() {
          _busy = false;
          _step2Error = 'Mã xác thực không đúng hoặc đã hết hạn';
        });
        return;
      }
      _timer?.cancel();
      setState(() {
        _busy = false;
        _currentStep = 3;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step2Error = e.fieldError('otp') ?? e.message;
      });
    }
  }

  // Tính toán độ mạnh mật khẩu (Yếu: Đỏ, Trung bình: Cam, Mạnh: Xanh)
  int _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[a-zA-Z]'))) {
      strength++;
    }
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength++;
    }
    return strength;
  }

  // Hoàn tất đăng ký (A4): tạo tài khoản và đăng nhập luôn
  Future<void> _onFinishRegister() async {
    final pass = _passController.text;
    final confirmPass = _confirmPassController.text;

    if (pass.length < 8 || _getPasswordStrength(pass) < 3 || !pass.contains(RegExp(r'[A-Z]'))) {
      setState(() => _step3Error = 'Mật khẩu tối thiểu 8 ký tự, gồm chữ in hoa, chữ số và ký tự đặc biệt');
      return;
    }
    if (pass != confirmPass) {
      setState(() => _step3Error = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      _busy = true;
      _step3Error = null;
    });
    try {
      await context.read<AuthProvider>().register(
            fullName: _nameController.text,
            email: _emailController.text.toLowerCase(),
            otp: _otpControllers.map((c) => c.text).join(),
            password: pass,
          );
      if (!mounted) return;
      await InterestGate.enter(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step3Error = e.fieldError('password') ?? e.message;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Đăng ký tài khoản',
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
              // Thanh chỉ báo tiến trình 3 bước
              Row(
                children: [
                  _buildStepIndicator(1, 'Thông tin'),
                  _buildStepLine(1),
                  _buildStepIndicator(2, 'Xác thực OTP'),
                  _buildStepLine(2),
                  _buildStepIndicator(3, 'Mật khẩu'),
                ],
              ),
              const SizedBox(height: 32.0),

              // Nội dung hiển thị theo từng bước
              if (_currentStep == 1) _buildStep1UI(),
              if (_currentStep == 2) _buildStep2UI(),
              if (_currentStep == 3) _buildStep3UI(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

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
    final isPassed = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2.0,
        margin: const EdgeInsets.only(bottom: 16.0, left: 4.0, right: 4.0),
        color: isPassed ? AppColors.primary : AppColors.border,
      ),
    );
  }

  // Giao diện Bước 1
  Widget _buildStep1UI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 1: Nhập thông tin cá nhân',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Tạo tài khoản học viên để bắt đầu tiếp cận kho tri thức.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24.0),

        if (_step1Error != null) ...[
          Container(
            padding: const EdgeInsets.all(AppDimens.p12),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: AppDimens.radiusInput,
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: AppDimens.p8),
                Expanded(
                  child: Text(
                    _step1Error!,
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

        Text(
          'Họ và tên',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'VD: Nguyễn Văn A',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 16.0),

        Text(
          'Địa chỉ Email',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'VD: student@gmail.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 28.0),

        AppButton(
          text: 'Tiếp tục',
          isLoading: _busy,
          onPressed: _onStep1Next,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        ),
      ],
    );
  }

  // Giao diện Bước 2: OTP
  Widget _buildStep2UI() {
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
          'Mã xác thực 6 số đã được gửi tới email ${_emailController.text}. Vui lòng nhập mã bên dưới:',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24.0),

        if (_step2Error != null) ...[
          Text(
            _step2Error!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12.0),
        ],

        // 6 ô ký tự riêng biệt
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

        // Đếm ngược 60s
        Center(
          child: _countdown > 0
              ? Text(
                  'Gửi lại mã sau $_countdown giây',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : TextButton(
                  onPressed: _busy ? null : () => _sendOtp(),
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

        AppButton(
          text: 'Xác thực mã OTP',
          isLoading: _busy,
          onPressed: _onStep2Verify,
        ),
      ],
    );
  }

  // Giao diện Bước 3: Mật khẩu & Thước đo độ mạnh
  Widget _buildStep3UI() {
    final strength = _getPasswordStrength(_passController.text);
    Color strengthColor = AppColors.error;
    String strengthLabel = 'Mật khẩu yếu';

    if (strength == 2) {
      strengthColor = AppColors.warning;
      strengthLabel = 'Mật khẩu trung bình';
    } else if (strength >= 3) {
      strengthColor = AppColors.success;
      strengthLabel = 'Mật khẩu mạnh & an toàn';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 3: Thiết lập mật khẩu',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Bảo vệ tài khoản bằng mật khẩu tối thiểu 8 ký tự.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24.0),

        if (_step3Error != null) ...[
          Text(
            _step3Error!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12.0),
        ],

        Text(
          'Mật khẩu mới',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: _passController,
          obscureText: _obscurePass,
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu...',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 8.0),

        // Thanh hiển thị độ mạnh mật khẩu
        if (_passController.text.isNotEmpty) ...[
          Row(
            children: List.generate(3, (index) {
              final active = strength > index;
              return Expanded(
                child: Container(
                  height: 4.0,
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    color: active ? strengthColor : AppColors.border,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4.0),
          Text(
            strengthLabel,
            style: AppTypography.captionTiny.copyWith(
              color: strengthColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16.0),
        ],

        Text(
          'Xác nhận mật khẩu',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: _confirmPassController,
          obscureText: _obscureConfirmPass,
          decoration: InputDecoration(
            hintText: 'Nhập lại mật khẩu...',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            ),
          ),
        ),
        const SizedBox(height: 32.0),

        AppButton(
          text: 'Hoàn tất đăng ký',
          isLoading: _busy,
          onPressed: _onFinishRegister,
        ),
      ],
    );
  }
}
