import 'package:flutter/material.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/state_views.dart';
import '../learning_support/learning_data_scope.dart';
import 'quiz_result_screen.dart';

/// Reads the last completed attempt supplied by H1; never starts a new attempt.
class QuizResultsScreen extends StatefulWidget {
  final String courseId;
  final QuizRepository? repository;
  const QuizResultsScreen({super.key, required this.courseId, this.repository});
  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  late final _repo =
      widget.repository ??
      LearningDataScope.read(context)?.quiz ??
      QuizRepository();
  bool _loading = true;
  Object? _error;
  Map<String, dynamic> _result = {};
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
      final info = await _repo.info(widget.courseId);
      if (mounted) {
        setState(() => _result = JsonUtils.asMap(info['lastResult']));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _error == null && _result.isNotEmpty) {
      return QuizResultScreen(
        courseId: widget.courseId,
        result: _result,
        repository: _repo,
        readOnly: true,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả quiz')),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(error: _error, onRetry: _load)
          : const EmptyView(
              title: 'Chưa có kết quả quiz',
              message: 'Kết quả xuất hiện sau khi bạn nộp bài.',
            ),
    );
  }
}
