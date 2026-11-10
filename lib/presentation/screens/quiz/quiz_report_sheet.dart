import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/state_views.dart';

Future<bool> showQuizReport(
  BuildContext context,
  QuizRepository repository,
  int attemptId,
  int questionId,
  String question,
) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReportForm(repository, attemptId, questionId, question),
    ) ??
    false;

class _ReportForm extends StatefulWidget {
  const _ReportForm(
    this.repository,
    this.attemptId,
    this.questionId,
    this.question,
  );
  final QuizRepository repository;
  final int attemptId, questionId;
  final String question;
  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _form = GlobalKey<FormState>();
  final _content = TextEditingController();
  String _reason = 'Câu hỏi không rõ';
  bool _sending = false;
  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !_form.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await widget.repository.report(
        widget.attemptId,
        widget.questionId,
        _reason,
        _content.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Báo lỗi câu hỏi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(widget.question, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Vấn đề bạn gặp'),
              items:
                  const [
                        'Câu hỏi không rõ',
                        'Đáp án có vẻ sai',
                        'Nhiều đáp án đúng',
                        'Lỗi hiển thị',
                        'Vấn đề khác',
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: _sending
                  ? null
                  : (value) => setState(() => _reason = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _content,
              maxLines: 4,
              maxLength: 2000,
              enabled: !_sending,
              decoration: InputDecoration(
                labelText: _reason == 'Vấn đề khác'
                    ? 'Mô tả vấn đề *'
                    : 'Mô tả thêm (không bắt buộc)',
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  _reason == 'Vấn đề khác' && (value ?? '').trim().isEmpty
                  ? 'Nhập nội dung vấn đề.'
                  : null,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_sending ? 'Đang gửi…' : 'Gửi đến giáo viên'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Báo lỗi không dừng đồng hồ làm bài.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
