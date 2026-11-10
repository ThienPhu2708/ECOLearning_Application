import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/support_repository.dart';
import '../../session/current_user.dart';
import '../../widgets/app_button.dart';

/// Liên hệ hỗ trợ (J3, giống form Liên hệ của website): gửi email tới hộp thư hỗ trợ.
/// Đã đăng nhập thì không cần nhập họ tên / email, server lấy theo tài khoản.
class ContactScreen extends StatefulWidget {
  final SupportRepository? repository;

  /// Mặc định: tài khoản đang đăng nhập (null = khách)
  final User? user;

  const ContactScreen({super.key, this.repository, this.user});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  static const _maxContent = 5000;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _content = TextEditingController();
  bool _sending = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  late final User? _user = widget.user ?? currentUser(context);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final errors = <String, String>{
      if (_user == null && _name.text.trim().isEmpty)
        'fullName': 'Vui lòng nhập Họ và tên!',
      if (_user == null && _email.text.trim().isEmpty)
        'email': 'Email không được để trống!',
      if (_content.text.trim().isEmpty)
        'content': 'Vui lòng nhập Nội dung liên hệ!',
    };
    setState(() {
      _fieldErrors = errors;
      _error = null;
    });
    if (errors.isNotEmpty) return;

    setState(() => _sending = true);
    try {
      await (widget.repository ?? SupportRepository()).contact(
        fullName: _user == null ? _name.text : null,
        email: _user == null ? _email.text : null,
        subject: _subject.text,
        content: _content.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Đã gửi tin nhắn liên hệ thành công! Đội ngũ hỗ trợ sẽ phản hồi qua email sớm nhất.',
            ),
          ),
        );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _fieldErrors = e.errors;
        _error = e.errors.isEmpty ? e.message : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Liên hệ hỗ trợ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Gửi câu hỏi hoặc góp ý cho đội ngũ E-Learning. Chúng mình sẽ phản hồi qua email của bạn.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (user != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gửi từ tài khoản: ${user.fullName} (${user.email})',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _field(_name, 'Họ và tên', 'fullName'),
              const SizedBox(height: 12),
              _field(
                _email,
                'Email nhận phản hồi',
                'email',
                keyboard: TextInputType.emailAddress,
              ),
            ],
            const SizedBox(height: 12),
            _field(_subject, 'Tiêu đề (không bắt buộc)', 'subject'),
            const SizedBox(height: 12),
            _field(
              _content,
              'Nội dung',
              'content',
              lines: 6,
              maxLength: _maxContent,
            ),
            const SizedBox(height: 8),
            AppButton(
              text: 'Gửi liên hệ',
              isLoading: _sending,
              onPressed: _sending ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String key, {
    int lines = 1,
    int? maxLength,
    TextInputType? keyboard,
  }) => TextField(
    controller: controller,
    enabled: !_sending,
    minLines: lines,
    maxLines: lines,
    maxLength: maxLength,
    keyboardType: keyboard,
    decoration: InputDecoration(
      labelText: label,
      alignLabelWithHint: lines > 1,
      errorText: _fieldErrors[key],
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
