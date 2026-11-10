import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/teacher_chat_repository.dart';
import '../../widgets/state_views.dart';
import 'conversation_screen.dart';

class InboxScreen extends StatefulWidget {
  final TeacherChatRepository? repository;
  const InboxScreen({super.key, this.repository});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with WidgetsBindingObserver {
  late final _repository = widget.repository ?? TeacherChatRepository();
  List<TeacherConversation> _items = [];
  bool _loading = true, _busy = false, _unread = false, _active = true;
  String _query = '';
  Object? _error;
  Timer? _timer;
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
    if (_busy) return;
    _busy = true;
    try {
      final items = await _repository.conversations();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items
        .where(
          (item) =>
              (!_unread || item.unreadCount > 0) &&
              '${item.participantName} ${item.courseName}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fc),
      appBar: AppBar(title: const Text('Tin nhắn của tôi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Tìm người nhắn, khóa học...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: !_unread,
                  onSelected: (_) => setState(() => _unread = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    'Chưa đọc (${_items.where((c) => c.unreadCount > 0).length})',
                  ),
                  selected: _unread,
                  onSelected: (_) => setState(() => _unread = true),
                ),
              ],
            ),
          ),
          if (_error != null && _items.isNotEmpty)
            MaterialBanner(
              content: const Text('Chưa cập nhật được danh sách tin nhắn.'),
              actions: [
                TextButton(onPressed: _load, child: const Text('Thử lại')),
              ],
            ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null && _items.isEmpty
                ? ErrorView(error: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: items.isEmpty ? 1 : items.length,
                      itemBuilder: (context, index) {
                        if (items.isEmpty) {
                          return SizedBox(
                            height: 300,
                            child: EmptyView(
                              icon: Icons.chat_bubble_outline,
                              title: _unread
                                  ? 'Không có tin chưa đọc'
                                  : 'Chưa có hội thoại phù hợp',
                              message:
                                  'Vào bài học và bấm Hỏi giáo viên để bắt đầu.',
                            ),
                          );
                        }
                        final item = items[index];
                        final fresh = item.unreadCount > 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: fresh
                                ? const Color(0xffefedff)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xffe7e3ff),
                                child: Text(
                                  item.participantName.isEmpty
                                      ? '?'
                                      : item.participantName.characters.first,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(
                                item.participantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: fresh
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    [item.participantRoleLabel, item.courseName]
                                        .where((text) => text.isNotEmpty)
                                        .join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.lastMessage.isEmpty
                                        ? 'Chưa có tin nhắn'
                                        : item.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: fresh
                                          ? AppColors.textHeading
                                          : AppColors.textSecondary,
                                      fontWeight: fresh
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (item.lastMessageAt != null)
                                    Text(
                                      DateFormat(
                                        'dd/MM',
                                      ).format(item.lastMessageAt!),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  if (fresh)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Badge(
                                        label: Text(
                                          item.unreadCount > 99
                                              ? '99+'
                                              : '${item.unreadCount}',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ConversationScreen(
                                      conversation: item,
                                      repository: _repository,
                                    ),
                                  ),
                                );
                                if (mounted) await _load();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
