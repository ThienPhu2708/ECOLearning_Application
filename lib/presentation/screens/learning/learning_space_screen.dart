import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lesson_video_player.dart';
import '../learning_support/learning_data_scope.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/course.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/learning_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../widgets/state_views.dart';
import '../quiz/quiz_intro_screen.dart';
import 'learning_controller.dart';
import 'rating_dialog.dart';
import 'lesson_notes_tab.dart';
import '../../session/current_user.dart';

class LearningSpaceScreen extends StatefulWidget {
  final Course course;
  final LearningRepository? repository;
  final ReviewRepository? reviews;
  final VideoPlayerController Function(Uri)? videoControllerFactory;
  const LearningSpaceScreen({
    super.key,
    required this.course,
    this.repository,
    this.reviews,
    this.videoControllerFactory,
  });
  @override
  State<LearningSpaceScreen> createState() => _LearningSpaceScreenState();
}

class _LearningSpaceScreenState extends State<LearningSpaceScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final LearningController _learning;
  late final TabController _tabs;
  VideoPlayerController? _video;
  Timer? _saveTimer;
  Object? _videoError;
  bool _videoLoading = false;
  bool _leaving = false;
  bool _allowPop = false;
  bool _switching = false;
  bool _completionSaveRequested = false;
  int _videoRequest = 0;
  bool _fullscreenOpen = false;
  Course get _course => widget.course;
  Lesson get _currentLesson => _learning.current!;
  List<Chapter> get _chapters => _learning.chapters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: 3, vsync: this);
    _learning = LearningController(
      widget.repository ??
          LearningDataScope.read(context)?.learning ??
          LearningRepository(),
      _course.id,
    );
    _learning.addListener(_update);
    _load();
    _saveTimer = Timer.periodic(ApiConfig.progressSaveInterval, (_) {
      if (_video?.value.isPlaying ?? false) unawaited(_saveProgress());
    });
  }

  void _update() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await _learning.load();
    if (mounted && _learning.current != null && _learning.error == null) {
      await _openVideo();
    }
  }

  Future<void> _openVideo() async {
    final request = ++_videoRequest;
    final old = _video;
    _video = null;
    if (old != null) {
      old.removeListener(_onVideo);
      await old.dispose();
    }
    if (!mounted || request != _videoRequest) return;
    setState(() {
      _videoLoading = true;
      _videoError = null;
      _completionSaveRequested = false;
    });
    VideoPlayerController? next;
    try {
      final url = Uri.tryParse(_currentLesson.videoUrl ?? '');
      if (url == null ||
          !url.hasAuthority ||
          !['http', 'https'].contains(url.scheme)) {
        throw StateError('Bài học chưa có đường dẫn video hợp lệ.');
      }
      next =
          widget.videoControllerFactory?.call(url) ??
          VideoPlayerController.networkUrl(url);
      await next.initialize();
      if (!mounted || request != _videoRequest) {
        await next.dispose();
        return;
      }
      final duration = next.value.duration.inSeconds;
      final resume = _currentLesson.lastPositionSeconds.clamp(0, duration);
      // A new stream already starts at zero. Seeking again can issue another
      // media request and unnecessarily delay the first frame.
      if (resume > 0) {
        await next.seekTo(Duration(seconds: resume));
      }
      if (!mounted || request != _videoRequest) {
        await next.dispose();
        return;
      }
      _video = next;
      next.addListener(_onVideo);
      setState(() => _videoLoading = false);
    } catch (e) {
      await next?.dispose();
      if (mounted && request == _videoRequest) {
        setState(() {
          _videoLoading = false;
          _videoError = e;
        });
      }
    }
  }

  void _onVideo() {
    if (!mounted) return;
    final v = _video?.value;
    if (v == null) return;
    setState(() {});
    // Ask the server as soon as the real playback position reaches 80%.
    // No completion or next-lesson access is granted before its response.
    if (!_completionSaveRequested &&
        v.isInitialized &&
        !v.hasError &&
        v.duration.inMilliseconds > 0 &&
        v.position.inMilliseconds >= v.duration.inMilliseconds * .8) {
      _completionSaveRequested = true;
      unawaited(_saveProgress());
    }
    if (v.hasError && _videoError == null) {
      _videoError = StateError('Không phát được video. Vui lòng thử lại.');
      unawaited(_saveProgress());
    }
  }

  Future<void> _saveProgress() {
    final video = _video;
    final lesson = _learning.current;
    if (video == null || lesson == null || !video.value.isInitialized) {
      return Future.value();
    }
    return _learning.save(
      lesson.id,
      video.value.position.inSeconds,
      video.value.duration.inSeconds,
    );
  }

  Future<void> _seekToNote(int seconds) async {
    final video = _video;
    if (video == null ||
        !video.value.isInitialized ||
        _videoError != null ||
        _switching ||
        _videoLoading) {
      throw StateError('Video chưa sẵn sàng.');
    }
    if (seconds < 0 || seconds > video.value.duration.inSeconds) {
      throw StateError('Mốc ghi chú không nằm trong video này.');
    }
    // Only persisted note timestamps are clickable; the scrub bar stays read-only.
    await video.seekTo(Duration(seconds: seconds));
  }

  Future<void> _selectLesson(Lesson lesson) async {
    if (_switching ||
        _learning.selecting ||
        _videoLoading ||
        lesson.id == _learning.current?.id) {
      return;
    }
    _switching = true;
    try {
      await _video?.pause();
      await _saveProgress();
      if (!mounted) return;
      final selected = await _learning.select(lesson);
      if (!mounted) return;
      if (selected) {
        await _openVideo();
      } else {
        showErrorSnackBar(context, _learning.error!);
      }
    } finally {
      _switching = false;
    }
  }

  Future<void> _togglePlayback() async {
    final video = _video;
    if (video == null) return;
    try {
      if (video.value.isPlaying) {
        await video.pause();
        await _saveProgress();
      } else {
        await video.play();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_video?.pause());
      unawaited(_saveProgress());
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    await _video?.pause();
    await _saveProgress();
    if (!mounted) return;
    if (_learning.progressError != null) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chưa lưu được tiến độ'),
          content: const Text(
            'Mốc xem mới nhất chưa được gửi lên máy chủ. Bạn muốn thoát hay ở lại để thử lưu lại?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thoát'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ở lại'),
            ),
          ],
        ),
      );
      if (leave != true) {
        _leaving = false;
        return;
      }
    }
    if (mounted) {
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _openQuiz() async {
    await _video?.pause();
    await _saveProgress();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizIntroScreen(courseId: _course.id),
      ),
    );
    if (mounted) await _load();
  }

  void _openRatingDialog() {
    if (!_learning.canReview) return;
    RatingDialog.show(
      context,
      course: _course,
      onSubmit: (rating, comment) async {
        await (widget.reviews ??
                LearningDataScope.read(context)?.reviews ??
                ReviewRepository())
            .submit(_course.id, rating: rating.toInt(), comment: comment);
        if (!mounted) return;
        setState(() {
          _course.myReviewRating = rating;
          _course.myReviewComment = comment;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu đánh giá của bạn.')),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoRequest++;
    _saveTimer?.cancel();
    unawaited(_saveProgress());
    _video?.removeListener(_onVideo);
    unawaited(_video?.dispose());
    _learning.removeListener(_update);
    _learning.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_fullscreenOpen) {
      body = const ColoredBox(color: Colors.black);
    } else if (_learning.loading) {
      body = const LoadingView(message: 'Đang tải nội dung khóa học…');
    } else if (_learning.current == null) {
      body = _learning.error != null
          ? ErrorView(error: _learning.error, onRetry: _load)
          : const EmptyView(title: 'Khóa học chưa có bài giảng');
    } else {
      body = Column(
        children: [
          _buildCustomVideoPlayer(),
          if (_learning.progressError != null)
            MaterialBanner(
              content: const Text(
                'Chưa lưu được mốc xem. Vui lòng kiểm tra kết nối.',
              ),
              actions: [
                TextButton(
                  onPressed: _learning.retryProgress,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          _buildLessonHeaderBar(),
          if (_learning.overview?.quizAvailable ?? false)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openQuiz,
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: const Text('Quiz cuối khóa'),
              ),
            ),
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Bài học'),
                Tab(text: 'Tài liệu'),
                Tab(text: 'Ghi chú'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildLessonAccordionTab(),
                const EmptyView(
                  icon: Icons.folder_open_outlined,
                  title: 'Chưa có tài liệu',
                  message: 'Tài liệu bài học sẽ hiển thị khi được cung cấp.',
                ),
                LessonNotesTab(
                  key: ValueKey(
                    '${(currentUser(context)?.id ?? 'guest')}/${_course.id}/${_currentLesson.id}',
                  ),
                  userId: (currentUser(context)?.id ?? 'guest'),
                  courseId: _course.id,
                  lessonId: _currentLesson.id,
                  lessonTitle: _currentLesson.title,
                  position: () => _video?.value.isInitialized == true
                      ? _video!.value.position.inSeconds
                      : 0,
                  onSeek:
                      _video?.value.isInitialized == true && _videoError == null
                      ? _seekToNote
                      : null,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _learning.current == null
            ? AppBar(
                title: Text(_course.title),
                leading: BackButton(onPressed: _leave),
              )
            : null,
        body: SafeArea(child: body),
      ),
    );
  }

  Widget _buildCustomVideoPlayer() {
    final lessons = _chapters.expand((c) => c.lessons).toList();
    final index = lessons.indexWhere((l) => l.id == _currentLesson.id);
    final previous = index > 0 ? lessons[index - 1] : null;
    final next = index >= 0 && index + 1 < lessons.length
        ? lessons[index + 1]
        : null;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LessonVideoPlayer(
        controller: _video,
        title: _currentLesson.title,
        posterUrl: _course.imageUrl,
        loading: _videoLoading || _learning.selecting,
        error: _videoError,
        onBack: _leave,
        onRetry: _openVideo,
        onPlayPause: _togglePlayback,
        onFullscreen: _showFullscreen,
        onPrevious:
            previous != null &&
                _learning.isUnlocked(previous.id) &&
                !_videoLoading &&
                !_learning.selecting
            ? () => _selectLesson(previous)
            : null,
        onNext:
            next != null &&
                _learning.isUnlocked(next.id) &&
                !_videoLoading &&
                !_learning.selecting
            ? () => _selectLesson(next)
            : null,
      ),
    );
  }

  Future<void> _showFullscreen() async {
    final video = _video;
    if (_fullscreenOpen || video == null || !video.value.isInitialized) return;
    setState(() => _fullscreenOpen = true);
    var retry = false;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (fullscreenContext) => Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: LessonVideoPlayer(
                controller: video,
                title: _currentLesson.title,
                fullscreen: true,
                loading: false,
                error: null,
                onBack: () => Navigator.pop(fullscreenContext),
                onRetry: () {
                  retry = true;
                  Navigator.pop(fullscreenContext);
                },
                onPlayPause: _togglePlayback,
                onFullscreen: () => Navigator.pop(fullscreenContext),
              ),
            ),
          ),
        ),
      );
    } finally {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (mounted) setState(() => _fullscreenOpen = false);
    }
    if (retry && mounted) await _openVideo();
  }

  // Khối thông tin bài học & Thanh tiến độ khóa học
  Widget _buildLessonHeaderBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _course.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionTiny.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentLesson.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.p8),
              // Chỉ hiện đánh giá sau khi hoàn thành bài học và đạt quiz.
              if (_learning.canReview)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: AppColors.warning),
                  ),
                  icon: const Icon(
                    Icons.star_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  label: Text(
                    _course.myReviewRating != null
                        ? '${_course.myReviewRating!.toInt()}★ Đã đánh giá'
                        : 'Đánh giá',
                    style: AppTypography.captionTiny.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: _learning.canReview ? _openRatingDialog : null,
                ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Thanh tiến độ tổng thể khóa học
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999.0),
                  child: LinearProgressIndicator(
                    value: _learning.progress / 100.0,
                    backgroundColor: AppColors.surfaceSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6.0,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Text(
                '${_learning.progress.toInt()}% khóa học',
                style: AppTypography.captionTiny.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Xem đủ 80% để hoàn thành và mở bài tiếp theo.',
                  style: AppTypography.captionTiny.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tab 1: Đề cương Accordion
  Widget _buildLessonAccordionTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.p16),
      children: [
        for (final chapter in _chapters)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.p12),
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppDimens.radiusCard,
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    chapter.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                  children: [
                    for (final lesson in chapter.lessons)
                      ListTile(
                        tileColor: lesson.id == _currentLesson.id
                            ? AppColors.primaryLight
                            : null,
                        leading: Icon(
                          lesson.isCompleted
                              ? Icons.check_circle_rounded
                              : !_learning.isUnlocked(lesson.id)
                              ? Icons.lock_outline_rounded
                              : lesson.id == _currentLesson.id
                              ? Icons.play_circle_fill_rounded
                              : Icons.play_circle_outline_rounded,
                          color: lesson.isCompleted
                              ? AppColors.success
                              : lesson.id == _currentLesson.id
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        title: Text(
                          lesson.title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: lesson.id == _currentLesson.id
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _learning.isUnlocked(lesson.id)
                              ? lesson.duration
                              : '${lesson.duration} · Hoàn thành 80% bài trước để mở',
                          style: AppTypography.captionTiny.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: lesson.id == _currentLesson.id
                            ? const Icon(
                                Icons.equalizer_rounded,
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: _learning.selecting || _videoLoading
                            ? null
                            : () => _selectLesson(lesson),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
