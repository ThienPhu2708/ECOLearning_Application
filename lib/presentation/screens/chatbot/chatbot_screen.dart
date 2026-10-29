import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/chatbot_repository.dart';
import '../../../data/repositories/course_repository.dart';
import '../../widgets/chatbot_bubble.dart';
import '../../widgets/state_views.dart';
import '../course_detail/course_detail_screen.dart';

/// Trợ lý Elearning (K1–K3): cùng chatbot và cùng giao diện với cửa sổ chat của website
/// (Views/Shared/_ChatBubble.cshtml, assets/css/chat-bubble.css — trên điện thoại web cũng mở toàn màn hình).
/// Đã đăng nhập thì server nhớ cuộc trò chuyện (mở lại vẫn thấy); khách thì mỗi câu là một lượt mới.
class ChatbotScreen extends StatefulWidget {
  final ChatbotRepository? repository;

  /// Mặc định: có token đăng nhập
  final bool Function()? isLoggedIn;

  /// Mặc định: mở màn chi tiết khóa học
  final void Function(BuildContext context, Course course)? onOpenCourse;

  const ChatbotScreen({
    super.key,
    this.repository,
    this.isLoggedIn,
    this.onOpenCourse,
  });

  /// Lời chào khi bắt đầu cuộc trò chuyện (giống LOI_CHAO của website)
  static const greeting =
      'Xin chào! Mình là **Trợ lý Elearning**. Mình có thể giúp bạn tìm khóa học theo chủ đề, giá hoặc cấp độ. Bạn muốn học gì hôm nay?';

  /// Gợi ý nhanh (giống các nút gợi ý của website)
  static const suggestions = [
    'Mình mới học lập trình, nên bắt đầu từ khóa nào?',
    'Có khóa Python nào dưới 300.000đ không?',
    'Khóa học miễn phí nào đáng học?',
    'Khóa nào được đánh giá cao nhất?',
  ];

  static const footer =
      'Trợ lý AI có thể nhầm lẫn, hãy kiểm tra lại thông tin quan trọng.';

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late final ChatbotRepository _repo = widget.repository ?? ChatbotRepository();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];

  /// Tin nhắn báo lỗi (tô đỏ), không phải câu trả lời của trợ lý
  final _errors = <ChatMessage>{};

  bool _loading = true;
  bool _disabled = false;
  bool _waiting = false;
  bool _showChips = true;

  bool get _loggedIn =>
      (widget.isLoggedIn ?? () => TokenStorage.instance.hasToken)();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Có lịch sử thì hiện lại (ẩn gợi ý); chưa có thì bắt đầu bằng lời chào như website
  Future<void> _loadHistory() async {
    try {
      final history = await _repo.history();
      if (!mounted) return;
      setState(() {
        if (history.isEmpty) {
          _startNew();
        } else {
          _messages.addAll(history);
          _showChips = false;
        }
      });
      _scrollToEnd();
    } on ApiException catch (e) {
      if (!mounted) return;
      // Không tải được lịch sử thì vẫn cho hỏi tiếp; chỉ 404 (trợ lý đang tắt) mới chặn
      setState(() => e.isNotFound ? _disabled = true : _startNew());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startNew() {
    _messages
      ..clear()
      ..add(const ChatMessage(fromUser: false, content: ChatbotScreen.greeting));
    _errors.clear();
    _showChips = true;
  }

  Future<void> _send([String? preset]) async {
    final question = (preset ?? _input.text).trim();
    if (question.isEmpty || _waiting) return;
    if (question.length > ChatbotRepository.maxQuestionLength) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Câu hỏi hơi dài, bạn rút gọn dưới ${ChatbotRepository.maxQuestionLength} ký tự giúp mình nhé.',
            ),
          ),
        );
      return;
    }
    _input.clear();
    setState(() {
      _messages.add(ChatMessage(fromUser: true, content: question));
      _waiting = true;
      _showChips = false;
    });
    _scrollToEnd();
    try {
      final reply = await _repo.ask(question);
      if (!mounted) return;
      setState(() => _messages.add(reply));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.isNotFound) {
          _disabled = true;
        } else {
          _addError(e.message);
        }
      });
    } catch (_) {
      // Giống website khi gọi lỗi: báo bằng tin nhắn đỏ, vẫn hỏi tiếp được
      if (mounted) setState(() => _addError('Không kết nối được máy chủ, bạn thử lại nhé.'));
    } finally {
      if (mounted) setState(() => _waiting = false);
      _scrollToEnd();
    }
  }

  void _addError(String message) {
    final error = ChatMessage(fromUser: false, content: message);
    _messages.add(error);
    _errors.add(error);
  }

  /// Nút "Bắt đầu cuộc trò chuyện mới": xóa lịch sử rồi hiện lại lời chào (lỗi cũng bắt đầu lại như website)
  Future<void> _newChat() async {
    if (_waiting) return;
    try {
      if (_loggedIn) await _repo.clearHistory();
    } on ApiException catch (_) {
      // Giống website: xóa không được vẫn bắt đầu lại trên màn hình
    }
    if (mounted) setState(_startNew);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openCourse(Course course) {
    final open = widget.onOpenCourse;
    if (open != null) {
      open(context, course);
    } else {
      CourseDetailScreen.open(context, course, ClickSource.chatbot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: _loading
                ? const ColoredBox(
                    color: ChatbotColors.logBackground,
                    child: LoadingView(),
                  )
                : _disabled
                ? const ColoredBox(
                    color: ChatbotColors.logBackground,
                    child: EmptyView(
                      icon: Icons.smart_toy_outlined,
                      title: 'Trợ lý Elearning chưa được bật',
                      message:
                          'Chức năng đang tạm tắt, bạn vui lòng quay lại sau nhé.',
                    ),
                  )
                : _log(),
          ),
          if (!_loading && !_disabled) ...[
            if (_showChips) _chips(),
            _form(),
            _footer(),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header (.eco-cb-head)
  Widget _header() => Container(
    decoration: const BoxDecoration(gradient: ChatbotColors.headerGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const ChatbotRobot(size: 28),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Trợ lý Elearning',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 10,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: ChatbotColors.statusDot,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ChatbotColors.statusDot.withValues(alpha: .3),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _disabled ? 'Tạm tắt' : 'Đang hoạt động',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_disabled)
              _headIcon(
                Icons.refresh_rounded,
                'Bắt đầu cuộc trò chuyện mới',
                _waiting || _loading ? null : _newChat,
              ),
            _headIcon(
              Icons.keyboard_arrow_down_rounded,
              'Thu nhỏ',
              () => Navigator.maybePop(context),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _headIcon(IconData icon, String tooltip, VoidCallback? onPressed) =>
      IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        disabledColor: Colors.white54,
        iconSize: 22,
        style: IconButton.styleFrom(
          minimumSize: const Size(34, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon),
      );

  // ---------------------------------------------------------------- khung tin nhắn (.eco-cb-log)
  Widget _log() => ColoredBox(
    color: ChatbotColors.logBackground,
    child: ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      children: [
        for (final m in _messages) ...[
          _row(m),
          if (m.courses.isNotEmpty) _cards(m.courses),
        ],
        if (_waiting) _row(null),
      ],
    ),
  );

  /// Một dòng tin nhắn; [m] = null là dòng "đang trả lời" (3 chấm)
  Widget _row(ChatMessage? m) {
    final fromUser = m?.fromUser ?? false;
    final isError = m != null && _errors.contains(m);
    final maxWidth = MediaQuery.sizeOf(context).width * .8;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: fromUser
            ? ChatbotColors.blue
            : isError
            ? ChatbotColors.errorBackground
            : Colors.white,
        border: fromUser
            ? null
            : Border.all(
                color: isError ? ChatbotColors.errorBorder : ChatbotColors.border,
              ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(fromUser ? 16 : 4),
          bottomRight: Radius.circular(fromUser ? 4 : 16),
        ),
      ),
      child: m == null
          ? const _TypingDots()
          : Text.rich(
              TextSpan(
                children: fromUser
                    ? [TextSpan(text: m.content)]
                    : replySpans(m.content),
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: fromUser
                    ? Colors.white
                    : isError
                    ? ChatbotColors.errorText
                    : ChatbotColors.text,
              ),
            ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: fromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!fromUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ChatbotColors.blue2, ChatbotColors.blue],
                ),
              ),
              alignment: Alignment.center,
              child: const ChatbotRobot(size: 19),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }

  /// Thẻ khóa học dưới câu trả lời (.eco-cb-card): ảnh, tên, giáo viên · ★ điểm, giá
  Widget _cards(List<Course> courses) => Padding(
    padding: const EdgeInsets.only(left: 36, bottom: 10),
    child: Column(
      children: [
        for (final c in courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: ChatbotColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openCourse(c),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 68,
                          height: 50,
                          color: ChatbotColors.border,
                          child: c.imageUrl.isEmpty
                              ? null
                              : Image.network(
                                  c.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: ChatbotColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              courseMeta(c),
                              style: const TextStyle(
                                fontSize: 12,
                                color: ChatbotColors.muted,
                              ),
                            ),
                            Text(
                              chatPrice(c.price),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ChatbotColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  // ---------------------------------------------------------------- gợi ý, ô nhập, chân (.eco-cb-chips / form / foot)
  Widget _chips() => Container(
    width: double.infinity,
    color: ChatbotColors.logBackground,
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in ChatbotScreen.suggestions)
          OutlinedButton(
            onPressed: _waiting ? null : () => _send(s),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ChatbotColors.blue,
              side: const BorderSide(color: ChatbotColors.blue),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              // Giữ font của theme (textStyle của nút thay toàn bộ kiểu chữ mặc định)
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(s, textAlign: TextAlign.left),
          ),
      ],
    ),
  );

  Widget _form() => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: ChatbotColors.border)),
    ),
    child: Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _input,
              maxLength: ChatbotRepository.maxQuestionLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi của bạn…',
                counterText: '',
                filled: true,
                fillColor: ChatbotColors.logBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: ChatbotColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: ChatbotColors.blue),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Gửi',
          child: Material(
            color: _waiting
                ? ChatbotColors.blue.withValues(alpha: .5)
                : ChatbotColors.blue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _waiting ? null : _send,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _footer() => Container(
    width: double.infinity,
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Text(
          ChatbotScreen.footer,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: ChatbotColors.footer),
        ),
      ),
    ),
  );
}

/// 3 chấm nhảy khi trợ lý đang soạn câu trả lời (.eco-cb-typing)
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang trả lời',
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) _dot((_controller.value - i * .125) % 1),
        ],
      ),
    ),
  );

  // Giống keyframes eco-cb-dot: nhảy lên ở 30% chu kỳ
  Widget _dot(double t) {
    final up = t < .3 ? t / .3 : (t < .6 ? (.6 - t) / .3 : 0.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Transform.translate(
        offset: Offset(0, -5 * up),
        child: Opacity(
          opacity: .5 + .5 * up,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: ChatbotColors.footer,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Định dạng câu trả lời giống website: `**chữ đậm**`, còn lại giữ nguyên (kể cả xuống dòng)
List<TextSpan> replySpans(String text) {
  final spans = <TextSpan>[];
  var start = 0;
  for (final m in RegExp(r'\*\*(.+?)\*\*').allMatches(text)) {
    if (m.start > start) spans.add(TextSpan(text: text.substring(start, m.start)));
    spans.add(
      TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    start = m.end;
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return spans;
}

/// Giá trên thẻ khóa học: "299.000đ" hoặc "Miễn phí" (giống hàm tien() của website)
String chatPrice(double price) => price > 0
    ? '${NumberFormat.decimalPattern('vi_VN').format(price.round())}đ'
    : 'Miễn phí';

/// "Giáo viên · ★ 4.5" (chỉ hiện điểm khi đã có đánh giá)
String courseMeta(Course c) {
  final rating = c.rating == c.rating.roundToDouble()
      ? c.rating.toStringAsFixed(0)
      : c.rating.toStringAsFixed(1);
  return [
    if (c.instructor.isNotEmpty) c.instructor,
    if (c.reviewCount > 0) '★ $rating',
  ].join(' · ');
}
