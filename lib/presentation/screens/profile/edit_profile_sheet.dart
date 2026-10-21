import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/user.dart';
import '../../widgets/app_button.dart';

class EditProfileSheet extends StatefulWidget {
  final User user;
  final Future<User> Function(
    String name,
    String phone,
    String? gender,
    DateTime? birthDate,
  )
  onSave;
  const EditProfileSheet({super.key, required this.user, required this.onSave});
  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(text: widget.user.phone);
  late String? _gender = ['Nam', 'Nữ', 'Khác'].contains(widget.user.gender)
      ? widget.user.gender
      : null;
  late DateTime? _birthDate = widget.user.birthDate;
  bool _saving = false;
  bool _submitted = false;
  String? _error;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _submitted = true;
      _error = null;
      _errors = {};
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final user = await widget.onSave(
        _name.text.trim(),
        _phone.text.trim(),
        _gender,
        _birthDate,
      );
      if (mounted) Navigator.pop(context, user);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Chưa lưu được thông tin. Vui lòng thử lại.';
          _errors = e is ApiException ? e.errors : {};
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate:
          _birthDate == null ||
              _birthDate!.isAfter(now) ||
              _birthDate!.year < 1900
          ? DateTime(now.year - 20)
          : _birthDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (date != null && mounted) {
      setState(() {
        _birthDate = date;
        _errors.remove('birthDate');
      });
    }
  }

  InputDecoration _decoration(String hint, IconData icon, String field) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.background,
        errorText: _errors[field],
        errorMaxLines: 3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      );

  Widget _label(String text, Widget field) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        field,
      ],
    ),
  );

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
                      Icons.manage_accounts_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Thông tin cá nhân',
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
                'Cập nhật thông tin để hồ sơ của bạn luôn chính xác.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              _label(
                'Họ và tên',
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  onChanged: (_) => setState(() {
                    _errors.remove('fullName');
                    _error = null;
                  }),
                  decoration: _decoration(
                    'Nhập họ và tên',
                    Icons.person_outline_rounded,
                    'fullName',
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Vui lòng nhập họ và tên.'
                      : null,
                ),
              ),
              _label(
                'Email',
                TextFormField(
                  initialValue: widget.user.email,
                  readOnly: true,
                  decoration:
                      _decoration(
                        '',
                        Icons.mail_outline_rounded,
                        'email',
                      ).copyWith(
                        suffixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                        ),
                        helperText: 'Email được dùng để đăng nhập.',
                        helperMaxLines: 2,
                      ),
                ),
              ),
              _label(
                'Số điện thoại',
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  onChanged: (_) => setState(() {
                    _errors.remove('phone');
                    _error = null;
                  }),
                  decoration: _decoration(
                    'Nhập số điện thoại',
                    Icons.phone_outlined,
                    'phone',
                  ),
                  validator: (v) {
                    final phone = (v ?? '').replaceAll(RegExp(r'[\s().-]'), '');
                    if (phone.isNotEmpty &&
                        !RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)) {
                      return 'Số điện thoại cần có 9–15 chữ số.';
                    }
                    return null;
                  },
                ),
              ),
              _label(
                'Giới tính',
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  isExpanded: true,
                  decoration: _decoration(
                    'Chưa chọn',
                    Icons.badge_outlined,
                    'gender',
                  ),
                  items: const ['Nam', 'Nữ', 'Khác']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (v) => setState(() {
                          _gender = v;
                          _errors.remove('gender');
                        }),
                ),
              ),
              _label(
                'Ngày sinh',
                InkWell(
                  onTap: _saving ? null : _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration:
                        _decoration(
                          '',
                          Icons.calendar_today_outlined,
                          'birthDate',
                        ).copyWith(
                          suffixIcon: _birthDate == null
                              ? const Icon(Icons.expand_more)
                              : IconButton(
                                  tooltip: 'Xóa ngày sinh',
                                  onPressed: _saving
                                      ? null
                                      : () => setState(() => _birthDate = null),
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                        ),
                    child: Text(
                      _birthDate == null
                          ? 'Chọn ngày sinh'
                          : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                      style: TextStyle(
                        color: _birthDate == null
                            ? AppColors.textMuted
                            : AppColors.textHeading,
                      ),
                    ),
                  ),
                ),
              ),
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
                text: 'Lưu thay đổi',
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
