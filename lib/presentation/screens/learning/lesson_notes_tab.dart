import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/app_button.dart';

class LessonNotesTab extends StatefulWidget {
  final String userId, courseId, lessonId, lessonTitle;
  final int Function() position;
  final Future<void> Function(int seconds)? onSeek;
  const LessonNotesTab({
    super.key,
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
  String get _key =>
      'lesson_notes_${jsonEncode([widget.userId, widget.courseId, widget.lessonId])}';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonDecode(prefs.getString(_key) ?? '[]') as List;
      if (mounted) {
        setState(() {
          _loadFailed = false;
          _notes = raw.map((v) => Map<String, dynamic>.from(v as Map)).toList();
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _error = 'Chưa đọc được ghi chú. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist(
    List<Map<String, dynamic>> next, {
    bool clear = false,
  }) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_key, jsonEncode(next))) {
        throw Exception('Save failed');
      }
      if (mounted) {
        setState(() {
          _notes = next;
          if (clear) _text.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa lưu được ghi chú. Nội dung của bạn vẫn được giữ lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add() {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung ghi chú.');
      return;
    }
    final next = [
      ..._notes,
      {
        'time': widget.position(),
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
    next.sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));
    _persist(next, clear: true);
  }

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.lessonTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ghi chú riêng cho bài học này, lưu trên thiết bị.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _text,
          enabled: !_saving && !_loadFailed,
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
          text: 'Lưu ghi chú tại mốc hiện tại',
          icon: const Icon(Icons.push_pin_outlined, size: 18),
          isLoading: _saving,
          onPressed: _loadFailed ? null : _add,
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
                      tooltip: 'Xóa ghi chú',
                      onPressed: _saving
                          ? null
                          : () => _persist([..._notes]..removeAt(i)),
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
    );
  }
}
