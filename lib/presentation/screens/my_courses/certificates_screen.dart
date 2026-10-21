import 'package:flutter/material.dart';
import '../learning_support/learning_data_scope.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/state_views.dart';
import 'certificate_screen.dart';

class CertificatesScreen extends StatefulWidget {
  final QuizRepository? repository;
  const CertificatesScreen({super.key, this.repository});
  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late final QuizRepository _repo =
      widget.repository ??
      LearningDataScope.read(context)?.quiz ??
      QuizRepository();
  List<Map<String, dynamic>> _data = [];
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
      final data = await _repo.certificates();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Chứng chỉ của tôi')),
    body: _loading
        ? const LoadingView()
        : _error != null
        ? ErrorView(error: _error, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                if (_data.isEmpty)
                  const SizedBox(
                    height: 380,
                    child: EmptyView(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Chưa có chứng chỉ',
                      message:
                          'Học đủ bài và đạt quiz để nhận chứng chỉ khóa học.',
                    ),
                  ),
                for (final certificate in _data)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xFFD97706),
                          size: 32,
                        ),
                        title: Text(
                          JsonUtils.asString(certificate['courseTitle']),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            JsonUtils.asString(certificate['code']),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                CertificateScreen(certificate: certificate),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}
