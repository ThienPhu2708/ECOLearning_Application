import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/teacher_chat_repository.dart';
import '../../widgets/state_views.dart';
import 'chat_media.dart';

class ConversationScreen extends StatefulWidget {
  final TeacherConversation? conversation;
  final String? courseId;
  final TeacherChatRepository? repository;
  const ConversationScreen({
    super.key,
    this.conversation,
    this.courseId,
    this.repository,
  }) : assert(conversation != null || courseId != null);
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with WidgetsBindingObserver {
  late final _repository = widget.repository ?? TeacherChatRepository();
  TeacherConversation? _conversation;
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <int, TeacherChatMessage>{};
  Timer? _poll;
  Object? _error;
  bool _loading = true,
      _refreshing = false,
      _sending = false,
      _older = false,
      _hasMore = false,
      _active = true;
  List<TeacherChatMessage> get _sorted =>
      _messages.values.toList()..sort((a, b) => b.id.compareTo(a.id));
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _conversation = widget.conversation;
    unawaited(_refresh());
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_active && ModalRoute.of(context)?.isCurrent == true) {
        unawaited(_refresh());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final conversation =
          _conversation ?? await _repository.open(widget.courseId!);
      final page = await _repository.messages(conversation.id);
      if (!mounted) return;
      final atBottom = !_scroll.hasClients || _scroll.offset < 100;
      setState(() {
        _conversation = page.conversation;
        if (_messages.isEmpty) _hasMore = page.messages.length == 50;
        for (final message in page.messages) {
          _messages[message.id] = message;
        }
        _error = null;
        _loading = false;
      });
      if (atBottom) _toBottom();
      if (_active && ModalRoute.of(context)?.isCurrent == true) {
        await _repository.markRead(conversation.id);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _loadOlder() async {
    if (_older || _conversation == null || _messages.isEmpty) return;
    setState(() => _older = true);
    try {
      final page = await _repository.messages(
        _conversation!.id,
        beforeId: _sorted.last.id,
      );
      if (!mounted) return;
      setState(() {
        for (final message in page.messages) {
          _messages[message.id] = message;
        }
        _hasMore = page.messages.length == 50;
      });
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _older = false);
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });
  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is ApiException
              ? error.message
              : 'Có lỗi xảy ra. Vui lòng thử lại.',
        ),
      ),
    );
  }

  Future<void> _send({String? imagePath}) async {
    final text = _draft.text.trim();
    if (_sending ||
        _conversation == null ||
        _conversation!.readOnly ||
        (imagePath == null && text.isEmpty)) {
      return;
    }
    setState(() => _sending = true);
    try {
      final sent = imagePath == null
          ? await _repository.send(_conversation!.id, text)
          : await _repository.sendImage(_conversation!.id, imagePath);
      if (!mounted) return;
      setState(() {
        _messages[sent.message.id] = sent.message;
        if (imagePath == null && _draft.text.trim() == text) _draft.clear();
      });
      _toBottom();
      if (sent.externalPaymentWarning) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chỉ thanh toán trên hệ thống. Không chuyển tiền qua tin nhắn.',
            ),
          ),
        );
      }
      await _refresh();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      if (await image.length() > 5 * 1024 * 1024) {
        throw const ApiException(
          message: 'Ảnh tối đa 5 MB. Vui lòng chọn ảnh nhỏ hơn.',
        );
      }
      if (mounted) await _send(imagePath: image.path);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _emoji() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                [
                      '😀',
                      '😊',
                      '❤️',
                      '👍',
                      '👏',
                      '🎉',
                      '🙏',
                      '🤔',
                      '✅',
                      '💡',
                      '📚',
                      '💪',
                    ]
                    .map(
                      (e) => InkWell(
                        onTap: () => Navigator.pop(context, e),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(e, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
    if (!mounted || emoji == null || _draft.text.length + emoji.length > 2000) {
      return;
    }
    _draft.text += emoji;
    _draft.selection = TextSelection.collapsed(offset: _draft.text.length);
  }

  Future<void> _recall(TeacherChatMessage message) async {
    if (!message.recallAvailable) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thu hồi tin nhắn?'),
        content: const Text('Tin nhắn sẽ được thu hồi ở cả hai phía.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.recall(_conversation!.id, message.id);
      if (mounted) await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _report() async {
    final input = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Báo cáo hội thoại'),
        content: TextField(
          controller: input,
          maxLength: 1000,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Nhập lý do báo cáo...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                Navigator.pop(context, input.text.trim());
              }
            },
            child: const Text('Gửi báo cáo'),
          ),
        ],
      ),
    );
    // The dialog route may still be animating; its field owns this controller until removal.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
    if (!mounted || reason == null) return;
    try {
      await _repository.report(_conversation!.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi báo cáo hội thoại.')),
      );
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;
    final messages = _sorted;
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation?.participantName ?? 'Hỏi giáo viên',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (conversation != null)
              Text(
                conversation.courseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (conversation != null)
            PopupMenuButton<String>(
              onSelected: (_) => _report(),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Báo cáo hội thoại'),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : conversation == null
          ? ErrorView(
              error: _error ?? 'Chưa mở được hội thoại',
              onRetry: _refresh,
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: const Color(0xffeeedff),
                  child: const Text(
                    'Trao đổi về bài học. Thanh toán chỉ thực hiện trên hệ thống.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_error != null)
                  MaterialBanner(
                    content: const Text(
                      'Chưa cập nhật được tin nhắn. Nội dung đang nhập vẫn được giữ.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                Expanded(
                  child: messages.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: const EmptyView(
                                    icon: Icons.forum_outlined,
                                    title: 'Bắt đầu cuộc trò chuyện',
                                    message:
                                        'Gửi câu hỏi về bài học cho giáo viên.',
                                  ),
                                ),
                              ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) =>
                              index == messages.length
                              ? Center(
                                  child: TextButton(
                                    onPressed: _older ? null : _loadOlder,
                                    child: Text(
                                      _older
                                          ? 'Đang tải...'
                                          : 'Xem tin nhắn trước',
                                    ),
                                  ),
                                )
                              : _bubble(messages[index]),
                        ),
                ),
                if (conversation.readOnly)
                  const SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Hội thoại hiện chỉ cho phép xem.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 10, 10, 10),
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Gửi ảnh',
                            onPressed: _sending ? null : _pickImage,
                            icon: const Icon(
                              Icons.image_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Biểu cảm',
                            onPressed: _emoji,
                            icon: const Icon(
                              Icons.sentiment_satisfied_alt_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _draft,
                              minLines: 1,
                              maxLines: 4,
                              maxLength: 2000,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Nhập tin nhắn...',
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.surfaceSubtle,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Gửi',
                            onPressed: _sending ? null : _send,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            icon: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _bubble(TeacherChatMessage message) => Align(
    alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        child: Column(
          crossAxisAlignment: message.isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: message.recallAvailable
                  ? () => _recall(message)
                  : null,
              child: Container(
                padding: EdgeInsets.all(
                  message.imageUrl != null && !message.recalled ? 4 : 12,
                ),
                decoration: BoxDecoration(
                  color: message.recalled
                      ? Colors.transparent
                      : message.isMine
                      ? AppColors.primary
                      : Colors.white,
                  border: message.isMine && !message.recalled
                      ? null
                      : Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: message.recalled
                    ? const Text(
                        'Tin nhắn đã được thu hồi',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : message.imageUrl != null
                    ? ChatMedia(
                        key: ValueKey(message.id),
                        messageId: message.id,
                        repository: _repository,
                      )
                    : Text(
                        message.content,
                        style: TextStyle(
                          color: message.isMine
                              ? Colors.white
                              : AppColors.textHeading,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.sentAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      DateFormat('HH:mm · dd/MM').format(message.sentAt!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (message.recallAvailable)
                  InkWell(
                    onTap: () => _recall(message),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(8, 4, 4, 0),
                      child: Icon(
                        Icons.undo_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
