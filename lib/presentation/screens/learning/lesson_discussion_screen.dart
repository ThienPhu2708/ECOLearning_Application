import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/lesson_discussion_repository.dart';
import '../../widgets/state_views.dart';

class LessonDiscussionScreen extends StatefulWidget {
  const LessonDiscussionScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.lessonTitle,
    this.repository,
  });
  final String courseId, lessonId, lessonTitle;
  final LessonDiscussionRepository? repository;
  @override
  State<LessonDiscussionScreen> createState() => _LessonDiscussionScreenState();
}

class _LessonDiscussionScreenState extends State<LessonDiscussionScreen>
    with WidgetsBindingObserver {
  late final LessonDiscussionRepository repo =
      widget.repository ?? LessonDiscussionRepository();
  final input = TextEditingController();
  final scroll = ScrollController();
  final busyLikes = <int>{};
  final images = <int, Future<Uint8List>>{};
  List<DiscussionComment> items = [];
  DiscussionComment? reply;
  String? replyName;
  Uint8List? image;
  String? filename;
  Object? error;
  bool loading = false, sending = false, foreground = true;
  bool refreshPending = false;
  int page = 0, pages = 0, total = 0, generation = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (foreground && !sending && !loading) load(silent: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground && !sending && !loading) load(silent: true);
  }

  Future<void> load({bool more = false, bool silent = false}) async {
    if (loading) {
      if (!more) refreshPending = true;
      return;
    }
    final request = ++generation;
    final firstLoad = page == 0;
    final oldExtent = scroll.hasClients ? scroll.position.maxScrollExtent : 0.0;
    final oldOffset = scroll.hasClients ? scroll.offset : 0.0;
    final nearBottom = !scroll.hasClients || oldExtent - oldOffset < 100;
    if (!silent) {
      setState(() {
        loading = true;
        error = null;
      });
    } else {
      loading = true;
    }
    try {
      final result = await repo.timeline(
        widget.courseId,
        widget.lessonId,
        page: more ? page + 1 : 1,
      );
      if (!mounted || request != generation) return;
      setState(() {
        final merged = <int, DiscussionComment>{};
        for (final item
            in more
                ? [...result.items, ...items]
                : [...items, ...result.items]) {
          merged[item.id] = item;
        }
        items = merged.values.toList()
          ..sort((a, b) {
            final aTime = a.createdAt;
            final bTime = b.createdAt;
            final order = aTime != null && bTime != null
                ? aTime.compareTo(bTime)
                : 0;
            return order != 0 ? order : a.id.compareTo(b.id);
          });
        page = more ? result.page : (page == 0 ? 1 : page);
        pages = result.totalPages;
        total = result.totalComments;
        error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !scroll.hasClients) return;
        if (more) {
          scroll.jumpTo(
            (oldOffset + scroll.position.maxScrollExtent - oldExtent).clamp(
              0,
              scroll.position.maxScrollExtent,
            ),
          );
        } else if (firstLoad || nearBottom) {
          scroll.jumpTo(scroll.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (mounted && request == generation && !silent) {
        setState(() => error = e);
      }
    } finally {
      if (mounted && request == generation) {
        setState(() => loading = false);
        if (refreshPending) {
          refreshPending = false;
          unawaited(load(silent: true));
        }
      }
    }
  }

  Future<void> pick() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final name = file.name.toLowerCase();
      if (!(name.endsWith('.jpg') ||
              name.endsWith('.jpeg') ||
              name.endsWith('.png')) ||
          await file.length() > 5 * 1024 * 1024) {
        throw const FormatException();
      }
      final bytes = await file.readAsBytes();
      final isPng =
          bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47 &&
          name.endsWith('.png');
      final isJpeg =
          bytes.length >= 3 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[2] == 0xff &&
          (name.endsWith('.jpg') || name.endsWith('.jpeg'));
      if (!isPng && !isJpeg) throw const FormatException();
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        final pixels = frame.image.width * frame.image.height;
        frame.image.dispose();
        if (pixels > 20000000) throw const FormatException();
      } finally {
        codec.dispose();
      }
      if (mounted) {
        setState(() {
          image = bytes;
          filename = file.name;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chọn ảnh JPG hoặc PNG hợp lệ, tối đa 5 MB và 20 megapixel.',
            ),
          ),
        );
      }
    }
  }

  Future<void> pickEmoji() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Center(
          heightFactor: 1,
          child: SizedBox(
            width: 300,
            child: GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final value in [
                  '😀',
                  '😂',
                  '😊',
                  '😍',
                  '🥰',
                  '😎',
                  '🤔',
                  '😳',
                  '😮',
                  '😅',
                  '👍',
                  '👎',
                  '❤️',
                  '🎉',
                  '👏',
                  '🙏',
                  '🔥',
                  '✅',
                  '💡',
                  '💯',
                ])
                  InkWell(
                    onTap: () => Navigator.pop(context, value),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(value, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || emoji == null) return;
    final value = input.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final text = value.text.replaceRange(selection.start, selection.end, emoji);
    if (text.length > (image == null ? 2000 : 1943)) return;
    input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  Future<void> send() async {
    if (sending ||
        input.value.composing.isValid && !input.value.composing.isCollapsed) {
      return;
    }
    final content = input.text.trim();
    if (content.isEmpty && image == null) return;
    if (content.length > (image == null ? 2000 : 1943)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nội dung vượt quá giới hạn cho phép.')),
      );
      return;
    }
    setState(() => sending = true);
    try {
      await repo.send(
        widget.courseId,
        widget.lessonId,
        content,
        reply == null ? null : (reply!.parentId ?? reply!.id),
        image: image,
        filename: filename,
      );
      if (!mounted) return;
      input.clear();
      setState(() {
        image = null;
        filename = null;
        reply = null;
        replyName = null;
      });
      await load();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) {
          scroll.jumpTo(scroll.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
        await load(silent: true);
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  KeyEventResult handleInputKey(FocusNode node, KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    final value = input.value;
    if (value.composing.isValid && !value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      final selection = value.selection.isValid
          ? value.selection
          : TextSelection.collapsed(offset: value.text.length);
      final text = value.text.replaceRange(
        selection.start,
        selection.end,
        '\n',
      );
      if (text.length <= (image == null ? 2000 : 1943)) {
        input.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: selection.start + 1),
        );
      }
    } else {
      unawaited(send());
    }
    return KeyEventResult.handled;
  }

  Future<void> like(DiscussionComment comment) async {
    if (!busyLikes.add(comment.id)) return;
    setState(() {});
    try {
      final result = await repo.toggle(
        widget.courseId,
        widget.lessonId,
        comment.id,
      );
      if (mounted) {
        setState(() {
          for (final item in items.where((item) => item.id == comment.id)) {
            item.likes = JsonUtils.asInt(result['likeCount']);
            item.liked = JsonUtils.asBool(result['likedByMe']);
          }
        });
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      busyLikes.remove(comment.id);
      if (mounted) setState(() {});
    }
  }

  String time(DateTime? date) {
    if (date == null) return '';
    final age = DateTime.now().difference(date);
    if (age.inDays >= 7) return '${age.inDays ~/ 7} tuần trước';
    if (age.inDays > 0) return '${age.inDays} ngày trước';
    if (age.inHours > 0) return '${age.inHours} giờ trước';
    if (age.inMinutes > 0) return '${age.inMinutes} phút trước';
    return 'Vừa xong';
  }

  TextTheme get _textTheme => Theme.of(context).textTheme;

  Widget comment(DiscussionComment c) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: c.avatar == null
                      ? const Icon(Icons.person)
                      : ClipOval(
                          child: Image.network(
                            ApiConfig.resolveMediaUrl(c.avatar!),
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.person),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: _textTheme.titleMedium),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (c.isTeacher)
                            Text(
                              'Giáo viên',
                              style: _textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          if (c.createdAt != null)
                            Text(
                              time(c.createdAt),
                              style: _textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (c.parentId != null &&
                (c.replyToAuthor != null || c.replyToContent != null))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.replyToAuthor != null)
                      Text(
                        'Phản hồi ${c.replyToAuthor}',
                        style: _textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    if (c.replyToContent != null)
                      Text(
                        c.replyToContent!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            if (c.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Text(
                  c.content,
                  style: _textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),
              ),
            if (c.hasImage)
              FutureBuilder<Uint8List>(
                future: images.putIfAbsent(
                  c.id,
                  () async => Uint8List.fromList(
                    await repo.image(widget.courseId, widget.lessonId, c.id),
                  ),
                ),
                builder: (_, snapshot) => snapshot.hasData
                    ? Image.memory(
                        snapshot.data!,
                        height: 180,
                        fit: BoxFit.contain,
                        gaplessPlayback: false,
                      )
                    : snapshot.hasError
                    ? const Text('Không tải được ảnh')
                    : const CircularProgressIndicator(),
              ),
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: busyLikes.contains(c.id) ? null : () => like(c),
                  icon: Icon(
                    c.liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 17,
                  ),
                  label: Text('Thích (${c.likes})'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    reply = c;
                    replyName = c.name;
                  }),
                  child: const Text('Phản hồi'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  @override
  void dispose() {
    generation++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Thảo luận bài học')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.lessonTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _textTheme.titleMedium,
                  ),
                ),
                if (page > 0) ...[
                  const SizedBox(width: 12),
                  Text('$total bình luận', style: _textTheme.labelSmall),
                ],
              ],
            ),
          ),
          Expanded(
            child: page == 0 && loading
                ? const LoadingView()
                : page == 0 && error != null
                ? ErrorView(error: error, onRetry: load)
                : RefreshIndicator(
                    onRefresh: load,
                    child: ListView(
                      controller: scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('Chưa có bình luận nào.'),
                            ),
                          ),
                        if (page < pages)
                          TextButton(
                            onPressed: loading ? null : () => load(more: true),
                            child: const Text('Tải thêm'),
                          ),
                        if (error != null) Text(errorMessage(error)),
                        for (final c in items) comment(c),
                      ],
                    ),
                  ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (reply != null)
            ListTile(
              dense: true,
              title: Text('Đang trả lời ${replyName ?? reply!.name}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  reply = null;
                  replyName = null;
                }),
              ),
            ),
          if (image != null)
            Row(
              children: [
                Image.memory(image!, width: 64, height: 64, fit: BoxFit.cover),
                IconButton(
                  onPressed: () => setState(() {
                    image = null;
                    filename = null;
                  }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                tooltip: 'Chọn ảnh',
                onPressed: sending ? null : pick,
                icon: const Icon(Icons.image_outlined),
              ),
              IconButton(
                tooltip: 'Biểu cảm',
                onPressed: sending ? null : pickEmoji,
                icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
              ),
              Expanded(
                child: Focus(
                  onKeyEvent: handleInputKey,
                  child: TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: image == null ? 2000 : 1943,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => send(),
                    decoration: const InputDecoration(
                      hintText: 'Viết bình luận...',
                      counterText: '',
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: sending ? null : send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
