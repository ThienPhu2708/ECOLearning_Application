import 'dart:async';
import 'package:flutter/material.dart';
import '../learning_support/learning_data_scope.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import 'certificate_review_screen.dart';
import 'quiz_skills_card.dart';
import 'quiz_support_screen.dart';
import 'quiz_report_sheet.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';

class QuizResultScreen extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic> result;
  final QuizRepository? repository;
  final CourseRepository? courses;
  final ReviewRepository? reviews;
  final bool readOnly;
  const QuizResultScreen({
    super.key,
    required this.courseId,
    required this.result,
    this.repository,
    this.courses,
    this.reviews,
    this.readOnly = false,
  });
  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with WidgetsBindingObserver {
  late Map<String, dynamic> _result = widget.result;
  bool _refreshing = false;
  Timer? _timer;
  late final _repository =
      widget.repository ??
      LearningDataScope.read(context)?.quiz ??
      QuizRepository();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          (ModalRoute.of(context)?.isCurrent ?? false) &&
          JsonUtils.asBool(_result['pendingReview'])) {
        unawaited(_refresh(silent: true));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing ||
        !JsonUtils.asBool(_result['supportsQuizReview']) ||
        JsonUtils.asInt(_result['attemptId']) == 0) {
      return;
    }
    _refreshing = true;
    try {
      final data = await _repository.result(
        JsonUtils.asInt(_result['attemptId']),
      );
      if (mounted) setState(() => _result = data);
    } catch (e) {
      if (mounted && !silent) showErrorSnackBar(context, e);
    } finally {
      _refreshing = false;
    }
  }

  bool _claiming = false;
  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      final data =
          await (widget.repository ??
                  LearningDataScope.read(context)?.quiz ??
                  QuizRepository())
              .claimCertificate(widget.courseId);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => CertificateReviewScreen(
              certificate: data,
              courseId: widget.courseId,
              courses:
                  widget.courses ??
                  LearningDataScope.read(context)?.courses ??
                  CourseRepository(),
              reviews:
                  widget.reviews ??
                  LearningDataScope.read(context)?.reviews ??
                  ReviewRepository(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = JsonUtils.asBool(_result['pendingReview']);
    final voided = JsonUtils.asBool(_result['isVoided']);
    final passed = !pending && !voided && JsonUtils.asBool(_result['passed']);
    final color = passed ? AppColors.success : AppColors.warning;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kết quả quiz'),
        actions: [
          if (JsonUtils.asBool(_result['supportsQuizReview']))
            IconButton(
              onPressed: _refresh,
              tooltip: 'Cập nhật kết quả',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: ListView(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: passed
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pending
                        ? Icons.hourglass_top_rounded
                        : passed
                        ? Icons.task_alt_rounded
                        : Icons.replay_rounded,
                    color: color,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  pending
                      ? 'Chờ giáo viên xem xét'
                      : voided
                      ? 'Kết quả hết hiệu lực'
                      : passed
                      ? 'Bạn đã đạt bài quiz'
                      : 'Bài quiz chưa đạt',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  pending
                      ? 'Bạn đã rời ứng dụng hoặc trang làm bài từ 3 lần. Kết quả cần giáo viên xem xét trước khi được công nhận và nhận chứng chỉ.'
                      : voided
                      ? 'Giáo viên đã yêu cầu làm lại. Kết quả mới thay thế bài này để xét chứng chỉ.'
                      : passed
                      ? (widget.readOnly
                            ? 'Kết quả lượt làm quiz gần nhất của bạn.'
                            : 'Bạn có thể nhận chứng chỉ khóa học.')
                      : 'Xem lại bài học và kiểm tra số lượt còn lại trước khi thử lại.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  pending
                      ? '— /10'
                      : '${JsonUtils.asDouble(_result['score']).toStringAsFixed(1)}/10',
                  style: TextStyle(
                    fontSize: 44,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  pending
                      ? 'Bài làm đã được lưu'
                      : '${JsonUtils.asInt(_result['correct'])}/${JsonUtils.asInt(_result['total'])} câu trả lời đúng',
                ),
                const Divider(height: 40),
                Text(
                  'Ngưỡng đạt: ${JsonUtils.asInt(_result['passPercent'])}%',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (JsonUtils.asBool(_result['timedOut']))
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Bài được nộp khi hết thời gian.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          if (!pending && !voided)
            QuizSkillsCard(
              skills: JsonUtils.asMapList(_result['skillResults']),
              results: true,
            ),
          for (final question in JsonUtils.asMapList(_result['review']))
            Card(
              child: ExpansionTile(
                title: Text(
                  'Câu ${JsonUtils.asInt(question['index']) + 1}: ${question['text']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  for (
                    int i = 0;
                    i < JsonUtils.asStringList(question['options']).length;
                    i++
                  )
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        i == JsonUtils.asInt(question['correctAnswer'])
                            ? Icons.check_circle_outline
                            : i ==
                                  JsonUtils.asInt(
                                    question['yourAnswer'],
                                    fallback: -1,
                                  )
                            ? Icons.cancel_outlined
                            : Icons.radio_button_unchecked,
                        color: i == JsonUtils.asInt(question['correctAnswer'])
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        '${String.fromCharCode(65 + i)}. ${JsonUtils.asStringList(question['options'])[i]}',
                      ),
                      subtitle:
                          i ==
                              JsonUtils.asInt(
                                question['yourAnswer'],
                                fallback: -1,
                              )
                          ? const Text('Bạn đã chọn')
                          : null,
                    ),
                  if (JsonUtils.asString(question['explanation']).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        JsonUtils.asString(question['explanation']),
                        style: const TextStyle(height: 1.6),
                      ),
                    ),
                  if (JsonUtils.asInt(question['questionId']) > 0)
                    TextButton.icon(
                      onPressed: () async {
                        final sent = await showQuizReport(
                          context,
                          widget.repository ??
                              LearningDataScope.read(context)?.quiz ??
                              QuizRepository(),
                          JsonUtils.asInt(_result['attemptId']),
                          JsonUtils.asInt(question['questionId']),
                          JsonUtils.asString(question['text']),
                        );
                        if (sent && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã gửi báo lỗi.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('Báo lỗi câu hỏi'),
                    ),
                ],
              ),
            ),
          if (JsonUtils.asBool(_result['supportsQuizReview']))
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => QuizSupportScreen(
                    courseId: widget.courseId,
                    repository:
                        widget.repository ??
                        LearningDataScope.read(context)?.quiz ??
                        QuizRepository(),
                    initialTab: voided ? 0 : 2,
                  ),
                ),
              ),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Phúc khảo & phản hồi giáo viên'),
            ),
          const SizedBox(height: 24),
          if (passed && !widget.readOnly)
            AppButton(
              text: 'Nhận chứng chỉ',
              icon: const Icon(Icons.workspace_premium_outlined),
              isLoading: _claiming,
              onPressed: _claiming ? null : _claim,
            ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Quay lại',
            type: AppButtonType.secondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
