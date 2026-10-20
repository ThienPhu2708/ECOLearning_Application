import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/course.dart';
import '../../../data/models/lesson.dart';
import 'rating_dialog.dart';

/// Màn hình Không gian học tập & Trình phát Video Player
/// Hiện thực hóa đầy đủ Trigger T07 (tích xanh >= 80%), T09 (đánh giá >= 70%), UC5 & UC6
class LearningSpaceScreen extends StatefulWidget {
  final Course course;

  const LearningSpaceScreen({super.key, required this.course});

  @override
  State<LearningSpaceScreen> createState() => _LearningSpaceScreenState();
}

class _LearningSpaceScreenState extends State<LearningSpaceScreen>
    with SingleTickerProviderStateMixin {
  late Course _course;
  late List<Chapter> _chapters;
  late Lesson _currentLesson;

  // Trạng thái Video Player
  bool _isPlaying = true;
  int _currentSeconds = 120; // Giả lập bắt đầu tại 02:00
  int _totalSeconds = 760;   // 12:40
  double _playbackSpeed = 1.0;
  bool _showControls = true;
  Timer? _playbackTimer;
  Timer? _controlsTimer;

  // Tab controller bên dưới Video
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _chapters = _course.chapters.isNotEmpty
        ? _course.chapters
        : MockData.createFlutterChapters();

    // Tìm bài học đang học dở hoặc bài đầu tiên
    _currentLesson = _chapters.first.lessons.firstWhere(
      (l) => l.isCurrent,
      orElse: () => _chapters.first.lessons.first,
    );
    _totalSeconds = _currentLesson.durationSeconds;
    if (_currentLesson.lastPositionSeconds > 0) {
      _currentSeconds = _currentLesson.lastPositionSeconds;
    }

    _tabController = TabController(length: 3, vsync: this);
    _startPlaybackSimulation();
    _resetControlsTimer();
  }

  // Giả lập phát video thời gian thực
  void _startPlaybackSimulation() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          if (_currentSeconds < _totalSeconds) {
            _currentSeconds += 1;
            _checkCompletionRule();
          } else {
            _isPlaying = false;
          }
        });
      }
    });
  }

  // Tự động ẩn controls sau 4 giây
  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  // QUY TẮC TRIGGER T07: Tích xanh tự động khi xem >= 80%
  void _checkCompletionRule() {
    final progressRatio = _currentSeconds / _totalSeconds;
    if (progressRatio >= 0.8 && !_currentLesson.isCompleted) {
      setState(() {
        _currentLesson.isCompleted = true;
        _recalculateCourseProgress();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: AppDimens.p8),
              Expanded(
                child: Text(
                  '🎉 Xuất sắc! Bạn đã hoàn thành bài giảng (≥ 80% thời lượng)',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // QUY TẮC TRIGGER T09: Kích hoạt đánh giá khi tiến độ toàn khóa >= 70%
      if (_course.progress >= 70.0 && _course.myReviewRating == null) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _openRatingDialog();
          }
        });
      }
    }
  }

  // Tính lại phần trăm hoàn thành của toàn khóa
  void _recalculateCourseProgress() {
    int totalLessons = 0;
    int completedLessons = 0;
    for (var ch in _chapters) {
      for (var les in ch.lessons) {
        totalLessons++;
        if (les.isCompleted) completedLessons++;
      }
    }
    if (totalLessons > 0) {
      _course.progress = (completedLessons / totalLessons) * 100.0;
    }
  }

  // Chọn phát bài học khác
  void _selectLesson(Lesson lesson) {
    setState(() {
      for (var ch in _chapters) {
        for (var l in ch.lessons) {
          l.isCurrent = (l.id == lesson.id);
        }
      }
      _currentLesson = lesson;
      _totalSeconds = lesson.durationSeconds;
      _currentSeconds = lesson.lastPositionSeconds;
      _isPlaying = true;
      _showControls = true;
    });
    _resetControlsTimer();
  }

  // Mở Dialog Đánh giá 5 sao
  void _openRatingDialog() {
    RatingDialog.show(
      context,
      course: _course,
      onSubmit: (rating, comment) {
        setState(() {
          _course.myReviewRating = rating;
          _course.myReviewComment = comment;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cảm ơn bạn đã đánh giá ${rating.toInt()} sao!'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  // Giả lập thông báo mất kết nối mạng
  void _simulateNetworkError() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppColors.errorLight,
        leading: const Icon(Icons.wifi_off_rounded, color: AppColors.error),
        content: Text(
          'Lỗi kết nối mạng! Hệ thống đã tự động lưu mốc xem tại ${AppFormatters.formatDurationFromSeconds(_currentSeconds)}.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _controlsTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Trình phát Video Player tùy biến 16:9
            _buildCustomVideoPlayer(),

            // 2. Thanh thông tin tiến độ bài học & nút đánh giá
            _buildLessonHeaderBar(),

            // 3. Tab Bar (Bài học, Tài liệu, Hỏi đáp)
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3.0,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Bài học'),
                  Tab(text: 'Tài liệu (3)'),
                  Tab(text: 'Hỏi đáp Q&A'),
                ],
              ),
            ),

            // 4. Nội dung tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLessonAccordionTab(),
                  _buildDocumentsTab(),
                  _buildQnATab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Khung phát Video Player 16:9 với các nút tua 10s, tốc độ, slider
  Widget _buildCustomVideoPlayer() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) _resetControlsTimer();
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Nền video
              Image.network(
                _course.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                color: Colors.black.withValues(alpha: _showControls ? 0.6 : 0.2),
              ),

              // Controls lớp phủ khi chạm vào video
              if (_showControls) ...[
                // Nút Back trên góc trái
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // Cụm nút tốc độ & mạng góc phải
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      // Nút giả lập mất mạng
                      IconButton(
                        icon: const Icon(Icons.wifi_tethering_error_rounded, color: Colors.white70),
                        tooltip: 'Mô phỏng mất mạng',
                        onPressed: _simulateNetworkError,
                      ),
                      // Nút tốc độ phát
                      PopupMenuButton<double>(
                        initialValue: _playbackSpeed,
                        tooltip: 'Tốc độ phát',
                        icon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white70),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_playbackSpeed}x',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        onSelected: (speed) {
                          setState(() => _playbackSpeed = speed);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                          const PopupMenuItem(value: 1.0, child: Text('1.0x (Chuẩn)')),
                          const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                          const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                          const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cụm điều khiển ở giữa: Tua lùi 10s - Play/Pause - Tua tới 10s
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tua lùi 10s
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _currentSeconds = (_currentSeconds - 10).clamp(0, _totalSeconds);
                        });
                        _resetControlsTimer();
                      },
                    ),
                    const SizedBox(width: 24),

                    // Play / Pause
                    GestureDetector(
                      onTap: () {
                        setState(() => _isPlaying = !_isPlaying);
                        _resetControlsTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Tua tới 10s
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _currentSeconds = (_currentSeconds + 10).clamp(0, _totalSeconds);
                          _checkCompletionRule();
                        });
                        _resetControlsTimer();
                      },
                    ),
                  ],
                ),

                // Thanh Scrubbing Slider ở đáy video
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 3.0,
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _currentSeconds.toDouble().clamp(0.0, _totalSeconds.toDouble()),
                          max: _totalSeconds.toDouble(),
                          onChanged: (val) {
                            setState(() {
                              _currentSeconds = val.toInt();
                              _checkCompletionRule();
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppFormatters.formatDurationFromSeconds(_currentSeconds),
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            Text(
                              AppFormatters.formatDurationFromSeconds(_totalSeconds),
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Khối thông tin bài học & Thanh tiến độ khóa học
  Widget _buildLessonHeaderBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              // Nút đánh giá khóa học
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: AppColors.warning),
                ),
                icon: const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                label: Text(
                  _course.myReviewRating != null
                      ? '${_course.myReviewRating!.toInt()}★ Đã đánh giá'
                      : 'Đánh giá 5★',
                  style: AppTypography.captionTiny.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: _openRatingDialog,
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
                    value: _course.progress / 100.0,
                    backgroundColor: AppColors.surfaceSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6.0,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Text(
                '${_course.progress.toInt()}% Hoàn thành',
                style: AppTypography.captionTiny.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
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
      children: _chapters.map((chapter) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimens.p12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.radiusCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                chapter.title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading,
                ),
              ),
              children: chapter.lessons.map((lesson) {
                final isCurrent = lesson.id == _currentLesson.id;
                return Material(
                  color: isCurrent ? AppColors.primaryLight : Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectLesson(lesson),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p16,
                        vertical: AppDimens.p12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            lesson.isCompleted
                                ? Icons.check_circle_rounded
                                : (isCurrent
                                    ? Icons.play_arrow_rounded
                                    : Icons.radio_button_unchecked_rounded),
                            color: lesson.isCompleted
                                ? AppColors.success
                                : (isCurrent ? AppColors.primary : AppColors.textMuted),
                            size: 20.0,
                          ),
                          const SizedBox(width: AppDimens.p12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.title,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight:
                                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : AppColors.textBody,
                                  ),
                                ),
                                if (lesson.isCompleted)
                                  Text(
                                    'Đã hoàn thành (≥ 80%)',
                                    style: AppTypography.captionTiny.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            lesson.duration,
                            style: AppTypography.captionTiny.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Tab 2: Tài liệu đính kèm
  Widget _buildDocumentsTab() {
    final docs = [
      {'title': 'Slide bài giảng toàn khóa (PDF)', 'size': '15.4 MB', 'type': 'PDF'},
      {'title': 'Kho mã nguồn mẫu GitHub Repository', 'size': '4.2 MB', 'type': 'ZIP'},
      {'title': 'Bảng tóm tắt Cheat Sheet Design Tokens', 'size': '1.8 MB', 'type': 'PDF'},
    ];

    return ListView(
      padding: const EdgeInsets.all(AppDimens.p16),
      children: docs.map((doc) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimens.p12),
          padding: const EdgeInsets.all(AppDimens.p16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.radiusCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.file_download_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['title']!,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${doc['type']} • ${doc['size']}',
                      style: AppTypography.captionTiny.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đang tải ${doc['title']}...')),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Tab 3: Hỏi đáp Q&A
  Widget _buildQnATab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.p16),
            children: [
              _buildQnAItem(
                'Lê Thành Nam',
                'Thầy ơi cho em hỏi nếu xem video bị giật lag thì đổi độ phân giải ở đâu ạ?',
                'Chào bạn, hệ thống hiện tự động điều chỉnh bit-rate thích ứng theo băng thông mạng của bạn nhé!',
              ),
              const Divider(color: AppColors.border, height: 24),
              _buildQnAItem(
                'Trần Bảo Trâm',
                'Phần thiết lập ThemeData em thấy rất tiện, cảm ơn thầy nhiều ạ.',
                'Cảm ơn Trâm, chúc bạn hoàn thành tốt đồ án nhé!',
              ),
            ],
          ),
        ),
        // Khung gửi câu hỏi
        Container(
          padding: const EdgeInsets.all(AppDimens.p12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Đặt câu hỏi cho giảng viên...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.p8),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi câu hỏi của bạn lên diễn đàn!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQnAItem(String user, String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4.0),
        Text(question, style: AppTypography.bodyMedium),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.reply_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  answer,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textBody),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
