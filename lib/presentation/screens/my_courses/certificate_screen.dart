import 'package:flutter/material.dart';
import '../learning_support/learning_data_scope.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/json_utils.dart';
import 'web_certificate_canvas.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';

class CertificateScreen extends StatefulWidget {
  final Course? course;
  final String? courseId;
  final bool? quizAvailable;
  final Map<String, dynamic>? certificate;
  final QuizRepository? repository;
  const CertificateScreen({
    super.key,
    this.course,
    this.courseId,
    this.quizAvailable,
    this.certificate,
    this.repository,
  }) : assert(course != null || courseId != null || certificate != null);
  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  Map<String, dynamic>? _data;
  Object? _error;
  bool _loading = true;
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
      final data =
          widget.certificate ??
          await (widget.repository ??
                  LearningDataScope.read(context)?.quiz ??
                  QuizRepository())
              .certificate(widget.courseId ?? widget.course!.id);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _zoom() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Chứng chỉ khóa học')),
          body: SafeArea(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: WebCertificateCanvas(certificate: _data!),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data ?? {};
    final code = JsonUtils.asString(data['code']);
    final error = _error;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chứng chỉ khóa học')),
      body: _loading
          ? const LoadingView()
          : error is ApiException &&
                error.isNotFound &&
                error.code == 'CERTIFICATE_NOT_FOUND'
          ? EmptyView(
              icon: Icons.verified_outlined,
              title: 'Chưa có chứng chỉ',
              message: switch (widget.quizAvailable) {
                true => 'Xem trạng thái Quiz cuối khóa để biết bước tiếp theo.',
                false =>
                  'Hệ thống chưa xác nhận đủ điều kiện cấp chứng chỉ. '
                      'Bạn có thể kiểm tra lại tiến độ và trạng thái khóa học.',
                null => 'Kiểm tra tiến độ học và yêu cầu của khóa học.',
              },
              actionText: 'Kiểm tra lại',
              onAction: _load,
            )
          : error != null
          ? ErrorView(
              error: error,
              onRetry:
                  error is ApiException &&
                      (error.isUnauthorized || error.isForbidden)
                  ? null
                  : _load,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF059669),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Chứng chỉ số được xác thực',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chứng Chỉ Hoàn Thành Khóa Học',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mã xác thực trực tuyến:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SelectableText(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textHeading,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: 'Chứng chỉ hoàn thành khóa học. Mở để phóng to.',
                  button: true,
                  child: GestureDetector(
                    onTap: _zoom,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: WebCertificateCanvas(certificate: data),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _zoom,
                    icon: const Icon(Icons.zoom_in_rounded),
                    label: const Text('Phóng to chứng chỉ'),
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Sao chép mã',
                  type: AppButtonType.secondary,
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: code.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép mã chứng chỉ.'),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
    );
  }
}
