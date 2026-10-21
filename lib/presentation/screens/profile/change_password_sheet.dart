import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../widgets/app_button.dart';

class ChangePasswordSheet extends StatefulWidget {
  final Future<void> Function(String current, String next)? onSubmit;
  const ChangePasswordSheet({super.key, this.onSubmit});
  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _controllers = List.generate(3, (_) => TextEditingController());
  final _hidden = [true, true, true];
  bool _submitted = false;
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _submitted = true;
      _error = null;
      _fieldErrors = {};
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (widget.onSubmit == null) {
      setState(
        () => _error =
            'Chưa kết nối dịch vụ đổi mật khẩu. Mật khẩu của bạn chưa thay đổi.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit!(_controllers[0].text, _controllers[1].text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Chưa đổi được mật khẩu. Vui lòng thử lại.';
          _fieldErrors = e is ApiException ? e.errors : {};
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(int index, String label, String hint) {
    final field = ['currentPassword', 'newPassword', 'confirmPassword'][index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controllers[index],
            enabled: !_saving,
            obscureText: _hidden[index],
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: index == 2
                ? TextInputAction.done
                : TextInputAction.next,
            autofillHints: [
              index == 0 ? AutofillHints.password : AutofillHints.newPassword,
            ],
            onFieldSubmitted: (_) {
              if (index == 2) _save();
            },
            onChanged: (_) => setState(() {
              _fieldErrors.remove(field);
              _error = null;
            }),
            validator: (value) {
              final text = value ?? '';
              if (text.isEmpty) return 'Vui lòng nhập ${label.toLowerCase()}.';
              if (index == 1 && text.length < 8) {
                return 'Mật khẩu mới cần ít nhất 8 ký tự.';
              }
              if (index == 1 && text == _controllers[0].text) {
                return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
              }
              if (index == 2 && text != _controllers[1].text) {
                return 'Mật khẩu xác nhận chưa khớp.';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              errorText: _fieldErrors[field],
              errorMaxLines: 3,
              filled: true,
              fillColor: AppColors.background,
              prefixIcon: Icon(
                index == 0 ? Icons.lock_outline_rounded : Icons.key_rounded,
                size: 20,
              ),
              suffixIcon: IconButton(
                tooltip: _hidden[index] ? 'Hiện $label' : 'Ẩn $label',
                onPressed: _saving
                    ? null
                    : () => setState(() => _hidden[index] = !_hidden[index]),
                icon: Icon(
                  _hidden[index]
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .94,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Form(
          key: _form,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Đổi mật khẩu',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Sử dụng mật khẩu riêng để bảo vệ tài khoản của bạn.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              _field(0, 'Mật khẩu hiện tại', 'Nhập mật khẩu đang sử dụng'),
              _field(1, 'Mật khẩu mới', 'Ít nhất 8 ký tự'),
              _field(2, 'Xác nhận mật khẩu mới', 'Nhập lại mật khẩu mới'),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              AppButton(
                text: 'Lưu mật khẩu mới',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
