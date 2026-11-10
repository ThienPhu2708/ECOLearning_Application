import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/support_repository.dart';
import '../../widgets/app_button.dart';

/// Báo cáo vi phạm khóa học đang học (J1, J2 — giống nút "Báo cáo vi phạm" của website).
/// [lessonId] / [lessonTitle]: bài đang mở, người dùng có thể bỏ chọn để báo cáo cả khóa.
Future<void> showReportViolationSheet(
  BuildContext context, {
  required String courseId,
  String? lessonId,
  String? lessonTitle,
  SupportRepository? repository,
}) async {
  final message = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ReportViolationSheet(
      courseId: courseId,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      repository: repository ?? SupportRepository(),
    ),
  );
  if (message != null && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class ReportViolationSheet extends StatefulWidget {
  final String courseId;
  final String? lessonId;
  final String? lessonTitle;
  final SupportRepository repository;

  const ReportViolationSheet({
    super.key,
    required this.courseId,
    required this.repository,
    this.lessonId,
    this.lessonTitle,
  });

  @override
  State<ReportViolationSheet> createState() => _ReportViolationSheetState();
}

class _ReportViolationSheetState extends State<ReportViolationSheet> {
  static const _minLength = 10;
  static const _maxLength = 2000;

  final _description = TextEditingController();
  List<String>? _types;
  Object? _loadError;
  String? _type;
  late bool _aboutLesson = widget.lessonId != null;
  bool _sending = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    setState(() => _loadError = null);
    try {
      final types = await widget.repository.violationTypes();
      if (mounted) setState(() => _types = types);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _submit() async {
    final text = _description.text.trim();
    final errors = <String, String>{
      if (_type == null) 'type': 'Vui lòng chọn loại vi phạm.',
      if (text.length < _minLength)
        'description': 'Vui lòng mô tả cụ thể vi phạm (tối thiểu $_minLength ký tự).',
    };
    setState(() {
      _fieldErrors = errors;
      _error = null;
    });
    if (errors.isNotEmpty) return;

    setState(() => _sending = true);
    try {
      await widget.repository.reportCourse(
        widget.courseId,
        type: _type!,
        description: text,
        lessonId: _aboutLesson ? widget.lessonId : null,
      );
      if (mounted) {
        Navigator.pop(
          context,
          'Đã gửi báo cáo vi phạm. Quản trị viên sẽ xem xét trong thời gian sớm nhất. Cảm ơn bạn!',
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _fieldErrors = e.errors;
        // Lỗi theo trường đã hiện dưới ô nhập; lỗi chung (đã có báo cáo chờ xử lý, chưa đăng ký...) hiện ở đầu form
        _error = e.errors.isEmpty ? e.message : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.flag_outlined, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Báo cáo vi phạm',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Báo cáo được gửi tới quản trị viên để xem xét. Mỗi khóa học chỉ gửi được một báo cáo trong lúc chờ xử lý.',
                style: AppTypography.captionTiny.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
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
              ],
              const SizedBox(height: 16),
              ..._buildTypes(),
              if (widget.lessonId != null)
                CheckboxListTile(
                  value: _aboutLesson,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Liên quan đến bài: ${widget.lessonTitle ?? 'đang học'}',
                    style: AppTypography.bodyMedium,
                  ),
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _aboutLesson = v ?? false),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                enabled: !_sending,
                minLines: 3,
                maxLines: 6,
                maxLength: _maxLength,
                decoration: InputDecoration(
                  labelText: 'Mô tả vi phạm',
                  hintText: 'Ví dụ: Video bài 3 bị mất tiếng từ phút thứ 2...',
                  alignLabelWithHint: true,
                  errorText: _fieldErrors['description'],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_fieldErrors['lessonId'] case final lessonError?)
                Text(
                  lessonError,
                  style: AppTypography.captionTiny.copyWith(
                    color: AppColors.error,
                  ),
                ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Gửi báo cáo',
                type: AppButtonType.danger,
                isLoading: _sending,
                onPressed: _types == null || _sending ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTypes() {
    final types = _types;
    if (types == null) {
      return [
        if (_loadError != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  _loadError is ApiException
                      ? (_loadError as ApiException).message
                      : 'Không tải được danh sách loại vi phạm.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              TextButton(onPressed: _loadTypes, child: const Text('Thử lại')),
            ],
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ];
    }
    return [
      Text(
        'Loại vi phạm',
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      RadioGroup<String>(
        groupValue: _type,
        onChanged: (v) {
          if (!_sending) setState(() => _type = v);
        },
        child: Column(
          children: [
            for (final t in types)
              RadioListTile<String>(
                value: t,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(t, style: AppTypography.bodyMedium),
              ),
          ],
        ),
      ),
      if (_fieldErrors['type'] case final typeError?)
        Text(
          typeError,
          style: AppTypography.captionTiny.copyWith(color: AppColors.error),
        ),
    ];
  }
}
