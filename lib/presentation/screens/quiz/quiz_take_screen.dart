import 'dart:async';
import 'package:flutter/material.dart';
import '../learning_support/learning_data_scope.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/state_views.dart';
import 'quiz_controller.dart';
import 'quiz_result_screen.dart';
import 'quiz_report_sheet.dart';

class QuizTakeScreen extends StatefulWidget {
  final String courseId;
  final String title;
  final Map<String, dynamic> attempt;
  final QuizRepository? repository;
  const QuizTakeScreen({
    super.key,
    required this.courseId,
    required this.attempt,
    this.title = 'Quiz cuối khóa',
    this.repository,
  });
  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen>
    with WidgetsBindingObserver {
  QuizController? _quiz;
  Object? _error;
  late final QuizRepository _repo =
      widget.repository ??
      LearningDataScope.read(context)?.quiz ??
      QuizRepository();
  final _keys = <GlobalKey>[];
  bool _allowPop = false;
  bool _leaving = false;
  bool _showNumbers = true;
  bool _resultOpened = false;
  int _active = 0;
  final _reported = <int>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _quiz = QuizController(_repo, widget.attempt);
      _keys.addAll(List.generate(_quiz!.questions.length, (_) => GlobalKey()));
      _quiz!.addListener(_update);
      _quiz!.startTimer();
      if (_quiz!.supportsReview) _quiz!.resume();
    } catch (e) {
      _error = e;
    }
  }

  void _update() {
    if (!mounted) return;
    setState(() {});
    if (_quiz?.result != null && !_resultOpened) {
      _resultOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final route = ModalRoute.of(context);
          if (route == null || !route.isActive) return;
          // An automatic submission may finish while a confirmation dialog is open.
          Navigator.of(context).popUntil((candidate) => candidate == route);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) => QuizResultScreen(
                courseId: widget.courseId,
                result: _quiz!.result!,
                repository: _repo,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _quiz?.resume();
    } else {
      _quiz?.depart();
      unawaited(_quiz?.saveDraft());
    }
  }

  Future<void> _leave() async {
    final q = _quiz;
    if (_leaving || (q?.submitting ?? false)) return;
    _leaving = true;
    try {
      if (q != null && !q.sessionLost) {
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tạm rời bài quiz?'),
            content: const Text(
              'Đồng hồ vẫn tiếp tục chạy. Đáp án sẽ được lưu nháp để bạn có thể quay lại trước khi hết giờ.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Làm tiếp'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lưu và thoát'),
              ),
            ],
          ),
        );
        if (leave != true) return;
        q.depart();
        await q.flushVisibility();
        await q.saveDraft();
        if (q.draftError != null) {
          if (mounted) showErrorSnackBar(context, q.draftError!);
          return;
        }
      }
      if (!mounted || _resultOpened) return;
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    } finally {
      _leaving = false;
    }
  }

  Future<void> _submit() async {
    final q = _quiz!;
    if (q.submitting) return;
    if (!q.expired) {
      final unanswered = q.questions.length - q.answered;
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.task_alt, color: AppColors.primary, size: 34),
          title: const Text('Nộp bài quiz?'),
          content: Text(
            unanswered > 0
                ? 'Bạn còn $unanswered câu chưa trả lời. Nộp bài sẽ kết thúc lượt làm này.'
                : 'Bạn đã trả lời đủ câu hỏi. Nộp bài để xem kết quả.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kiểm tra lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Nộp bài'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await q.submit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quiz?.removeListener(_update);
    _quiz?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _quiz;
    if (_error != null || q == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz cuối khóa')),
        body: ErrorView(error: _error, onRetry: () => Navigator.pop(context)),
      );
    }
    final left = q.secondsLeft;
    final time =
        '${(left ~/ 60).toString().padLeft(2, '0')}:${(left % 60).toString().padLeft(2, '0')}';
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: BackButton(onPressed: _leave),
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: Icon(
                  Icons.schedule,
                  size: 17,
                  color: left <= 60 ? AppColors.error : AppColors.primary,
                ),
                label: Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: left <= 60 ? AppColors.error : AppColors.primary,
                  ),
                ),
                backgroundColor: left <= 60
                    ? AppColors.errorLight
                    : AppColors.primaryLight,
                side: BorderSide.none,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (q.expired)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Đã hết giờ. Bài làm đang chờ được nộp.',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showNumbers = !_showNumbers),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.grid_view_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Câu hỏi',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              '${q.answered}/${q.questions.length}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Icon(
                              _showNumbers
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showNumbers)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 130),
                        child: SingleChildScrollView(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(q.questions.length, (i) {
                                final answered = q.answers[i] >= 0;
                                return Semantics(
                                  label:
                                      'Câu ${i + 1}, ${answered ? 'đã trả lời' : 'chưa trả lời'}',
                                  button: true,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      setState(() => _active = i);
                                      final target = _keys[i].currentContext;
                                      if (target != null) {
                                        Scrollable.ensureVisible(
                                          target,
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          alignment: .04,
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: answered
                                            ? AppColors.primary
                                            : AppColors.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _active == i
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          color: answered
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (q.sessionLost)
                MaterialBanner(
                  content: const Text(
                    'Lượt thi đã được chuyển sang phiên khác. Phiên này đã ngừng nhận đáp án.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: _leave,
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              if (q.supportsReview)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    q.departures >= 3
                        ? 'Đã ghi nhận ${q.departures} lần rời ứng dụng. Kết quả sẽ chờ giáo viên xem xét.'
                        : 'Rời ứng dụng từ 3 lần: kết quả chờ giáo viên xem xét. Đồng hồ vẫn chạy.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: q.departures >= 3
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              if (q.visibilityError != null)
                MaterialBanner(
                  content: const Text(
                    'Chưa gửi được nhật ký rời ứng dụng. Cần gửi lại trước khi nộp bài.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: q.flushVisibility,
                      child: const Text('Gửi lại'),
                    ),
                  ],
                ),
              if (q.draftError != null)
                MaterialBanner(
                  content: const Text(
                    'Chưa lưu được đáp án. Bài làm vẫn được giữ trên màn hình này.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: q.submitting ? null : q.saveDraft,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              if (q.submitError != null)
                MaterialBanner(
                  content: Text(errorMessage(q.submitError!)),
                  actions: [
                    TextButton(
                      onPressed: q.submitting ? null : q.submit,
                      child: const Text('Nộp lại'),
                    ),
                  ],
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (int i = 0; i < q.questions.length; i++)
                        Container(
                          key: _keys[i],
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Câu ${i + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (q.supportsReview && q.questions[i].id > 0)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed:
                                        q.submitting ||
                                            q.expired ||
                                            _reported.contains(
                                              q.questions[i].id,
                                            )
                                        ? null
                                        : () async {
                                            final sent = await showQuizReport(
                                              context,
                                              _repo,
                                              q.attemptId,
                                              q.questions[i].id,
                                              q.questions[i].text,
                                            );
                                            if (sent &&
                                                mounted &&
                                                context.mounted) {
                                              setState(
                                                () => _reported.add(
                                                  q.questions[i].id,
                                                ),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Đã gửi báo lỗi đến giáo viên.',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.flag_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _reported.contains(q.questions[i].id)
                                          ? 'Đã báo lỗi'
                                          : 'Báo lỗi câu hỏi',
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                q.questions[i].text,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 16),
                              for (
                                int option = 0;
                                option < q.questions[i].options.length;
                                option++
                              )
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Semantics(
                                    checked: q.answers[i] == option,
                                    enabled:
                                        !q.sessionLost &&
                                        !q.expired &&
                                        !q.submitting,
                                    child: Material(
                                      color: q.answers[i] == option
                                          ? AppColors.primaryLight
                                          : AppColors.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: q.answers[i] == option
                                              ? AppColors.primary
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap:
                                            q.sessionLost ||
                                                q.expired ||
                                                q.submitting
                                            ? null
                                            : () => q.choose(i, option),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                q.answers[i] == option
                                                    ? Icons.radio_button_checked
                                                    : Icons.radio_button_off,
                                                size: 20,
                                                color: q.answers[i] == option
                                                    ? AppColors.primary
                                                    : AppColors.textMuted,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  '${String.fromCharCode(65 + option)}. ${q.questions[i].options[option]}',
                                                  style: const TextStyle(
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    q.saving
                        ? 'Đang lưu đáp án…'
                        : q.dirty
                        ? 'Đáp án chưa được lưu'
                        : 'Đã lưu đáp án',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: q.submitting ? null : _submit,
                  icon: q.submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(q.submitting ? 'Đang nộp…' : 'Nộp bài'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
