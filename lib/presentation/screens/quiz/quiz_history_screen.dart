import 'package:flutter/material.dart';
import '../../../core/utils/json_utils.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/state_views.dart';
import 'quiz_result_screen.dart';
import 'quiz_take_screen.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({
    super.key,
    required this.courseId,
    required this.repository,
  });
  final String courseId;
  final QuizRepository repository;
  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  List<Map<String, dynamic>>? _items;
  Object? _error;
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.history(widget.courseId);
      if (mounted) {
        setState(() {
          _items = data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      if (item['submittedAt'] == null) {
        Map<String, dynamic> attempt;
        try {
          attempt = await widget.repository.resume(
            JsonUtils.asInt(item['attemptId']),
          );
        } on ApiException catch (error) {
          if (error.code == 'QUIZ_FINISHED') {
            final result = await widget.repository.result(
              JsonUtils.asInt(item['attemptId']),
            );
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => QuizResultScreen(
                  courseId: widget.courseId,
                  result: result,
                  repository: widget.repository,
                  readOnly: true,
                ),
              ),
            );
            if (mounted) await _load();
            return;
          }
          if (error.code != 'QUIZ_SESSION_ACTIVE' || !mounted) rethrow;
          final transfer = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Chuyển lượt thi sang đây?'),
              content: const Text(
                'Phiên cũ sẽ mất quyền sửa. Thời gian và đáp án được giữ nguyên.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Chuyển sang đây'),
                ),
              ],
            ),
          );
          if (transfer != true || !mounted) return;
          attempt = await widget.repository.resume(
            JsonUtils.asInt(item['attemptId']),
            takeover: true,
          );
        }
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => QuizTakeScreen(
              courseId: widget.courseId,
              attempt: attempt,
              repository: widget.repository,
              title: JsonUtils.asString(
                attempt['title'],
                fallback: 'Quiz cuối khóa',
              ),
            ),
          ),
        );
      } else {
        final result = await widget.repository.result(
          JsonUtils.asInt(item['attemptId']),
        );
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => QuizResultScreen(
              courseId: widget.courseId,
              result: result,
              repository: widget.repository,
              readOnly: true,
            ),
          ),
        );
      }
      if (mounted) await _load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch sử quiz')),
    body: _error != null
        ? ErrorView(error: _error!, onRetry: _load)
        : _items == null
        ? const LoadingView()
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_items!.isEmpty)
                  const EmptyView(
                    title: 'Chưa có lượt làm bài',
                    message: 'Lịch sử xuất hiện sau khi bạn bắt đầu quiz.',
                  ),
                for (final item in _items!)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(
                        '${JsonUtils.asBool(item['isVerification']) ? 'Làm lại' : 'Lượt thi'} #${JsonUtils.asInt(item['attemptId'])}',
                      ),
                      subtitle: Text(
                        JsonUtils.asBool(item['isVoided'])
                            ? 'Kết quả hết hiệu lực'
                            : JsonUtils.asBool(item['pendingReview'])
                            ? 'Chờ giáo viên xem xét'
                            : item['submittedAt'] == null
                            ? 'Đang làm bài'
                            : '${JsonUtils.asMap(item['result'])['score']} /10',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _opening ? null : () => _open(item),
                    ),
                  ),
              ],
            ),
          ),
  );
}
