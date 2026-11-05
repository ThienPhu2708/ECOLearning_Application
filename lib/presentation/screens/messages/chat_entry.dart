import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/repositories/teacher_chat_repository.dart';
import 'conversation_screen.dart';
import 'inbox_screen.dart';

class ChatEntry extends StatefulWidget {
  final String? courseId;
  final Future<void> Function()? beforeOpen;
  const ChatEntry({super.key, this.courseId, this.beforeOpen});
  @override
  State<ChatEntry> createState() => _ChatEntryState();
}

class _ChatEntryState extends State<ChatEntry> with WidgetsBindingObserver {
  final _repository = TeacherChatRepository();
  Timer? _timer;
  int _count = 0;
  bool _busy = false, _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_active && ModalRoute.of(context)?.isCurrent == true) {
        unawaited(_load());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) unawaited(_load());
  }

  Future<void> _load() async {
    if (_busy || !TokenStorage.instance.hasToken) return;
    _busy = true;
    try {
      final id = widget.courseId;
      final count = id == null
          ? await _repository.unreadCount()
          : (await _repository.conversations(
              courseId: id,
            )).fold<int>(0, (sum, c) => sum + c.unreadCount);
      if (mounted) setState(() => _count = count);
    } catch (_) {
      /* The destination screen provides a retryable API error. */
    } finally {
      _busy = false;
    }
  }

  Future<void> _open() async {
    await widget.beforeOpen?.call();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => widget.courseId == null
            ? const InboxScreen()
            : ConversationScreen(courseId: widget.courseId),
      ),
    );
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Badge(
      isLabelVisible: _count > 0,
      label: Text(_count > 99 ? '99+' : '$_count'),
      child: const Icon(Icons.forum_outlined),
    );
    if (widget.courseId != null) {
      return TextButton.icon(
        onPressed: _open,
        icon: icon,
        label: const Text('Hỏi giáo viên'),
      );
    }
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: icon,
        title: const Text(
          'Tin nhắn của tôi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _open,
      ),
    );
  }
}
