import 'package:flutter/material.dart';
import '../learning_support/learning_data_scope.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import 'quiz_take_screen.dart';
import 'quiz_result_screen.dart';

class QuizIntroScreen extends StatefulWidget {
  final String courseId;
  final QuizRepository? repository;
  const QuizIntroScreen({super.key, required this.courseId, this.repository});
  @override
  State<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends State<QuizIntroScreen> {
  late final QuizRepository _repo =
      widget.repository ??
      LearningDataScope.read(context)?.quiz ??
      QuizRepository();
  Map<String, dynamic>? _info;
  Object? _error;
  bool _loading = true;
  bool _starting = false;
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.info(widget.courseId);
      if (mounted) setState(() => _info = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    if (_starting || _confirming) return;
    final active = JsonUtils.asInt(_info?['activeAttemptId']) > 0;
    _confirming = true;
    try {
      if (!active) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.quiz_outlined,
              color: AppColors.primary,
              size: 36,
            ),
            title: const Text('Bắt đầu làm quiz?'),
            content: Text(
              'Bạn có ${JsonUtils.asInt(_info?['minutes'])} phút để hoàn thành bài. Đồng hồ bắt đầu ngay và lượt làm này sẽ được tính vào giới hạn.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Để sau'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Bắt đầu'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      if (!mounted) return;
      setState(() => _starting = true);
      final attempt = await _repo.start(widget.courseId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => QuizTakeScreen(
            courseId: widget.courseId,
            attempt: attempt,
            repository: _repo,
            title: JsonUtils.asString(
              _info?['title'],
              fallback: 'Quiz cuối khóa',
            ),
          ),
        ),
      );
      if (mounted) await _load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      _confirming = false;
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _info ?? {};
    final active = JsonUtils.asInt(data['activeAttemptId']) > 0;
    final allowed = JsonUtils.asInt(data['attemptsAllowed']);
    final used = JsonUtils.asInt(data['attemptsUsed']);
    final last = JsonUtils.asMap(data['lastResult']);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Quiz cuối khóa')),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(error: _error, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.quiz_outlined,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          JsonUtils.asString(
                            data['title'],
                            fallback: 'Quiz cuối khóa',
                          ),
                          style: AppTypography.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kiểm tra kiến thức sau khi hoàn thành khóa học.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _detail(
                          Icons.format_list_numbered,
                          'Số câu hỏi',
                          '${JsonUtils.asInt(data['questionCount'])} câu',
                        ),
                        _detail(
                          Icons.schedule_outlined,
                          'Thời gian',
                          '${JsonUtils.asInt(data['minutes'])} phút',
                        ),
                        _detail(
                          Icons.check_circle_outline,
                          'Điều kiện đạt',
                          'Đúng từ ${JsonUtils.asInt(data['passPercent'])}%',
                        ),
                        _detail(
                          Icons.replay_rounded,
                          'Số lượt đã dùng',
                          '$used / $allowed lượt',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!JsonUtils.asBool(data['canStart']) && !active)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        JsonUtils.asString(
                          data['reason'],
                          fallback: 'Bạn chưa đủ điều kiện làm quiz.',
                        ),
                        style: const TextStyle(color: AppColors.textBody),
                      ),
                    ),
                  if (last.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Icon(
                        JsonUtils.asBool(last['passed'])
                            ? Icons.check_circle_outline
                            : Icons.history,
                        color: AppColors.primary,
                      ),
                      title: const Text('Kết quả gần nhất'),
                      subtitle: Text(
                        '${JsonUtils.asDouble(last['score']).toStringAsFixed(1)}/10 điểm',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => QuizResultScreen(
                            courseId: widget.courseId,
                            result: last,
                            repository: _repo,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppButton(
                    text: active ? 'Tiếp tục làm bài' : 'Bắt đầu quiz',
                    isLoading: _starting,
                    onPressed:
                        !_starting &&
                            (active || JsonUtils.asBool(data['canStart']))
                        ? _start
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kết quả cao nhất được ghi nhận. Học đủ bài và đạt quiz để nhận chứng chỉ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _detail(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
