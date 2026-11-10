import 'package:flutter/material.dart';
import '../../../data/repositories/lesson_resources_repository.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/app_button.dart';

class LessonNotesTab extends StatefulWidget {
  final String userId, courseId, lessonId, lessonTitle;
  final LessonResourcesRepository? repository;
  final bool active;
  final int Function() position;
  final Future<void> Function(int seconds)? onSeek;
  const LessonNotesTab({
    super.key,
    this.repository,
    this.active = true,
    required this.userId,
    required this.courseId,
    required this.lessonId,
    required this.lessonTitle,
    required this.position,
    this.onSeek,
  });
  @override
  State<LessonNotesTab> createState() => _LessonNotesTabState();
}

class _LessonNotesTabState extends State<LessonNotesTab> {
  final _text = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true, _saving = false, _loadFailed = false, _seeking = false;
  String? _error;
  late final _repository = widget.repository ?? LessonResourcesRepository();
  int? _editingId, _editingTime;
  Map<String, dynamic> _display(Map<String, dynamic> n) => {
    ...n,
    'time': (n['positionSeconds'] as num?)?.toInt() ?? 0,
    'text': n['content']?.toString() ?? '',
  };
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LessonNotesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active && !_saving) _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await _repository.notes(widget.courseId, widget.lessonId);
      if (mounted) {
        setState(() {
          _loadFailed = false;
          _notes = raw.map(_display).toList();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _error = e is ApiException
              ? e.message
              : 'Chưa đọc được ghi chú. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Chưa lưu được ghi chú. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add() {
    final content = _text.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung ghi chú.');
      return;
    }
    final seconds = _editingTime ?? widget.position();
    _mutate(() async {
      final note = _display(
        await _repository.saveNote(
          widget.courseId,
          widget.lessonId,
          content,
          seconds,
          id: _editingId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _notes.removeWhere((n) => n['id'] == note['id']);
        _notes.add(note);
        _notes.sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));
        _editingId = null;
        _editingTime = null;
        _text.clear();
      });
    });
  }

  void _delete(Map<String, dynamic> note) => _mutate(() async {
    await _repository.deleteNote(note['id'] as int);
    if (mounted) {
      setState(() {
        _notes.removeWhere((n) => n['id'] == note['id']);
        if (_editingId == note['id']) {
          _editingId = null;
          _editingTime = null;
          _text.clear();
        }
      });
    }
  });

  Future<void> _openNote(int seconds) async {
    final seek = widget.onSeek;
    if (seek == null || _seeking) return;
    setState(() {
      _seeking = true;
      _error = null;
    });
    try {
      await seek(seconds);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa quay lại được mốc ghi chú. Vui lòng thử lại khi video sẵn sàng.',
        );
      }
    } finally {
      if (mounted) setState(() => _seeking = false);
    }
  }

  String _time(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.lessonTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            enabled: !_saving && !_loadFailed,
            maxLength: 1000,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Nhập điều bạn muốn ghi nhớ…',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: _editingId == null
                ? 'Lưu ghi chú tại mốc hiện tại'
                : 'Lưu thay đổi',
            icon: const Icon(Icons.push_pin_outlined, size: 18),
            isLoading: _saving,
            onPressed: _loadFailed ? null : _add,
          ),
          if (_editingId != null)
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                      _editingId = null;
                      _editingTime = null;
                      _text.clear();
                    }),
              child: const Text('Hủy chỉnh sửa'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  if (_notes.isEmpty)
                    TextButton(
                      onPressed: _saving ? null : _load,
                      child: const Text('Thử lại'),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (_notes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 36,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chưa có ghi chú',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          for (int i = 0; i < _notes.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(14, 4, 6, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: widget.onSeek == null || _seeking
                            ? null
                            : () => _openNote(_notes[i]['time'] as int),
                        icon: const Icon(Icons.access_time_rounded, size: 15),
                        label: Text(_time(_notes[i]['time'] as int)),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Sửa ghi chú',
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _editingId = _notes[i]['id'] as int;
                                _editingTime = _notes[i]['time'] as int;
                                _text.text = _notes[i]['text'] as String;
                              }),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                      IconButton(
                        tooltip: 'Xóa ghi chú',
                        onPressed: _saving ? null : () => _delete(_notes[i]),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _notes[i]['text'] as String,
                      style: const TextStyle(
                        height: 1.5,
                        color: AppColors.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
