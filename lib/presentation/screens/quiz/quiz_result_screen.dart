import 'package:flutter/material.dart';
import '../learning_support/learning_data_scope.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import 'certificate_review_screen.dart';
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

class _QuizResultScreenState extends State<QuizResultScreen> {
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
    final passed = JsonUtils.asBool(widget.result['passed']);
    final color = passed ? AppColors.success : AppColors.warning;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kết quả quiz')),
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
                    passed ? Icons.task_alt_rounded : Icons.replay_rounded,
                    color: color,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  passed ? 'Bạn đã đạt bài quiz' : 'Bài quiz chưa đạt',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  passed
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
                  '${JsonUtils.asDouble(widget.result['score']).toStringAsFixed(1)}/10',
                  style: TextStyle(
                    fontSize: 44,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${JsonUtils.asInt(widget.result['correct'])}/${JsonUtils.asInt(widget.result['total'])} câu trả lời đúng',
                ),
                const Divider(height: 40),
                Text(
                  'Ngưỡng đạt: ${JsonUtils.asInt(widget.result['passPercent'])}%',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (JsonUtils.asBool(widget.result['timedOut']))
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
