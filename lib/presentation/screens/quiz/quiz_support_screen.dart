import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/state_views.dart';
import 'quiz_take_screen.dart';
import 'quiz_result_screen.dart';

class QuizSupportScreen extends StatefulWidget {
  const QuizSupportScreen({
    super.key,
    required this.courseId,
    required this.repository,
    this.initialTab = 0,
  });
  final String courseId;
  final QuizRepository repository;
  final int initialTab;
  @override
  State<QuizSupportScreen> createState() => _QuizSupportScreenState();
}

class _QuizSupportScreenState extends State<QuizSupportScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _data;
  Object? _error;
  bool _loading = false, _opening = false, _visible = true;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_visible && (ModalRoute.of(context)?.isCurrent ?? false)) {
        unawaited(_load(silent: true));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    if (_visible) unawaited(_load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    try {
      final data = await widget.repository.support(widget.courseId);
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && (!silent || _data == null)) setState(() => _error = error);
    } finally {
      _loading = false;
    }
  }

  Future<void> _appeal() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final attempts = (await widget.repository.history(
        widget.courseId,
      )).where((a) => a['submittedAt'] != null).toList();
      if (!mounted) return;
      final sent = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _AppealForm(
          courseId: widget.courseId,
          attempts: attempts,
          repository: widget.repository,
        ),
      );
      if (sent == true && mounted) await _load();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _retake(Map<String, dynamic> request) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final attemptId = JsonUtils.asInt(request['retakeAttemptId']);
      if (JsonUtils.asBool(request['submitted'])) {
        final result = await widget.repository.result(attemptId);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => QuizResultScreen(
              courseId: widget.courseId,
              result: result,
              repository: widget.repository,
            ),
          ),
        );
      } else {
        if (attemptId == 0) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Bắt đầu bài làm lại?'),
              content: const Text(
                'Kết quả mới thay thế điểm cũ, kể cả thấp hơn. Đồng hồ chạy ngay khi bắt đầu. Từ 3 lần rời ứng dụng, kết quả sẽ chờ giáo viên xem xét.',
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
          if (ok != true || !mounted) return;
        }
        Map<String, dynamic> attempt;
        try {
          attempt = await widget.repository.startRetake(
            widget.courseId,
            JsonUtils.asInt(request['id']),
          );
        } on ApiException catch (e) {
          if (e.code != 'QUIZ_SESSION_ACTIVE' || !mounted) rethrow;
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Chuyển lượt thi sang đây?'),
              content: const Text(
                'Phiên cũ sẽ mất quyền sửa. Thời gian và đáp án đã lưu được giữ nguyên.',
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
          if (ok != true || !mounted) return;
          attempt = await widget.repository.startRetake(
            widget.courseId,
            JsonUtils.asInt(request['id']),
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
              title: 'Quiz làm lại',
            ),
          ),
        );
      }
      if (mounted) await _load();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Widget _card(String title, List<Widget> children, {String? status}) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                status,
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
  Widget _text(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(height: 1.6)),
  );
  Widget _list(List<Widget> children, String empty) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: children.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(30),
                child: Text(empty, textAlign: TextAlign.center),
              ),
            ]
          : children,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final data = _data ?? {};
    final retakes = JsonUtils.asMapList(data['retakes']),
        reports = JsonUtils.asMapList(data['reports']),
        appeals = JsonUtils.asMapList(data['appeals']),
        notices = JsonUtils.asMapList(data['notices']);
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab.clamp(0, 3),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Phản hồi & yêu cầu quiz'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Làm lại (${retakes.length})'),
              Tab(text: 'Báo lỗi (${reports.length})'),
              Tab(text: 'Phúc khảo (${appeals.length})'),
              Tab(text: 'Điều chỉnh điểm (${notices.length})'),
            ],
          ),
        ),
        body: _error != null
            ? ErrorView(error: _error!, onRetry: _load)
            : _data == null
            ? const LoadingView()
            : TabBarView(
                children: [
                  _list(
                    retakes
                        .map(
                          (r) => _card('Yêu cầu cho lượt #${r['attemptId']}', [
                            _text(JsonUtils.asString(r['reason'])),
                            Text(
                              JsonUtils.asString(r['teacherName']),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _text(
                              'Kết quả cũ hết hiệu lực. Chỉ xét chứng chỉ theo kết quả mới.',
                            ),
                            FilledButton.icon(
                              onPressed: _opening ? null : () => _retake(r),
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(
                                JsonUtils.asBool(r['submitted'])
                                    ? 'Xem kết quả làm lại'
                                    : JsonUtils.asInt(r['retakeAttemptId']) > 0
                                    ? 'Tiếp tục làm lại'
                                    : 'Bắt đầu làm lại',
                              ),
                            ),
                          ], status: JsonUtils.asString(r['statusText'])),
                        )
                        .toList(),
                    'Chưa có yêu cầu làm lại.',
                  ),
                  _list(
                    reports
                        .map(
                          (r) => _card(JsonUtils.asString(r['question']), [
                            _text('Lượt #${r['attemptId']} · ${r['reason']}'),
                            if (JsonUtils.asString(r['content']).isNotEmpty)
                              _text(JsonUtils.asString(r['content'])),
                            if (JsonUtils.asString(r['response']).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Phản hồi giáo viên: ${r['response']}',
                                  style: const TextStyle(height: 1.6),
                                ),
                              ),
                          ], status: JsonUtils.asString(r['statusText'])),
                        )
                        .toList(),
                    'Bạn chưa gửi báo lỗi câu hỏi.',
                  ),
                  _list([
                    if (JsonUtils.asBool(data['canAppeal']))
                      _card('Gửi yêu cầu phúc khảo', [
                        _text(
                          'Mỗi học viên được gửi một lần cho khóa học. Nêu rõ câu hỏi và vấn đề cần xem xét.',
                        ),
                        FilledButton.icon(
                          onPressed: _opening ? null : _appeal,
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Gửi phúc khảo'),
                        ),
                      ]),
                    if (appeals.isEmpty && !JsonUtils.asBool(data['canAppeal']))
                      _text('Phúc khảo được mở sau khi bạn nộp bài.'),
                    for (final r in appeals)
                      _card(
                        'Phúc khảo lượt #${r['attemptId']}',
                        [
                          _text(JsonUtils.asString(r['content'])),
                          for (final reply in JsonUtils.asMapList(r['replies']))
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    JsonUtils.asString(reply['teacherName']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    JsonUtils.asString(reply['content']),
                                    style: const TextStyle(height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Bạn đã dùng lượt phúc khảo của khóa học này.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        status: r['status'] == 'Answered'
                            ? 'Đã phản hồi'
                            : r['status'] == 'Processing'
                            ? 'Đang xem xét'
                            : 'Chờ xử lý',
                      ),
                  ], 'Chưa có yêu cầu phúc khảo.'),
                  _list(
                    notices
                        .map(
                          (r) => _card('Điều chỉnh lượt #${r['attemptId']}', [
                            _text(JsonUtils.asString(r['reason'])),
                            Text(
                              '${r['oldScore']} → ${r['score']} /10',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              JsonUtils.asString(r['teacherName']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ]),
                        )
                        .toList(),
                    'Chưa có thông báo điều chỉnh điểm.',
                  ),
                ],
              ),
      ),
    );
  }
}

class _AppealForm extends StatefulWidget {
  const _AppealForm({
    required this.courseId,
    required this.attempts,
    required this.repository,
  });
  final String courseId;
  final List<Map<String, dynamic>> attempts;
  final QuizRepository repository;
  @override
  State<_AppealForm> createState() => _AppealFormState();
}

class _AppealFormState extends State<_AppealForm> {
  final _form = GlobalKey<FormState>();
  final _content = TextEditingController();
  int? _attemptId;
  bool _sending = false;
  @override
  void initState() {
    super.initState();
    if (widget.attempts.isNotEmpty) {
      _attemptId = JsonUtils.asInt(widget.attempts.first['attemptId']);
    }
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !_form.currentState!.validate() || _attemptId == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.repository.appeal(
        widget.courseId,
        _attemptId!,
        _content.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      24,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Yêu cầu phúc khảo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text('Chỉ gửi một lần cho khóa học này.'),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: _attemptId,
            decoration: const InputDecoration(
              labelText: 'Lượt thi cần xem xét',
            ),
            items: widget.attempts
                .map(
                  (a) => DropdownMenuItem(
                    value: JsonUtils.asInt(a['attemptId']),
                    child: Text('Lượt #${a['attemptId']}'),
                  ),
                )
                .toList(),
            onChanged: _sending
                ? null
                : (value) => setState(() => _attemptId = value),
            validator: (value) => value == null ? 'Chọn lượt thi.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _content,
            maxLength: 2000,
            maxLines: 5,
            enabled: !_sending,
            decoration: const InputDecoration(
              labelText: 'Nội dung cần xem xét',
              alignLabelWithHint: true,
            ),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Nhập nội dung phúc khảo.'
                : null,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? 'Đang gửi…' : 'Gửi đến giáo viên'),
          ),
        ],
      ),
    ),
  );
}
