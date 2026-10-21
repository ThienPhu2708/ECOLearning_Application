import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// Shared controls for the inline and fullscreen player. Progress is read-only.
class LessonVideoPlayer extends StatefulWidget {
  const LessonVideoPlayer({
    super.key,
    required this.controller,
    required this.title,
    required this.loading,
    required this.error,
    required this.onBack,
    required this.onRetry,
    required this.onPlayPause,
    required this.onFullscreen,
    this.posterUrl = '',
    this.fullscreen = false,
    this.onPrevious,
    this.onNext,
  });
  final VideoPlayerController? controller;
  final String title, posterUrl;
  final bool loading, fullscreen;
  final Object? error;
  final VoidCallback onBack, onRetry, onFullscreen;
  final Future<void> Function() onPlayPause;
  final VoidCallback? onPrevious, onNext;
  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  bool _controls = true;
  Timer? _hideTimer;
  void _scheduleHide() {
    _hideTimer?.cancel();
    if (widget.controller?.value.isPlaying != true) return;
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && widget.controller?.value.isPlaying == true) {
        setState(() => _controls = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LessonVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controls = true;
      _scheduleHide();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _settings() async {
    final video = widget.controller;
    if (video == null || !video.value.isInitialized) return;
    _hideTimer?.cancel();
    final speed = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF202126),
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: 420,
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.speed_rounded, color: Colors.white),
                title: Text(
                  'Tốc độ phát',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final rate in [1.0, 1.5, 2.0])
                ListTile(
                  title: Text(
                    rate == 1 ? 'Bình thường · 1x' : '${rate}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: rate == video.value.playbackSpeed
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFFA5B4FC),
                        )
                      : null,
                  onTap: () => Navigator.pop(context, rate),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (!mounted || video != widget.controller) return;
    if (speed != null) {
      try {
        await video.setPlaybackSpeed(speed);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chưa đổi được tốc độ. Vui lòng thử lại.'),
            ),
          );
        }
      }
    }
    if (mounted) _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.controller;
    return video == null
        ? _buildPlayer()
        : AnimatedBuilder(animation: video, builder: (_, _) => _buildPlayer());
  }

  Widget _buildPlayer() {
    final video = widget.controller;
    final error =
        widget.error ??
        (video?.value.hasError == true
            ? StateError('Video playback failed')
            : null);
    final ready = video != null && video.value.isInitialized && error == null;
    final busy = widget.loading || (ready && video.value.isBuffering);
    final visible = _controls || !ready || !video.value.isPlaying;
    final duration = ready ? video.value.duration.inMilliseconds : 0;
    final position = ready ? video.value.position.inMilliseconds : 0;
    double buffered = 0;
    if (ready && duration > 0) {
      for (final range in video.value.buffered) {
        final value = range.end.inMilliseconds / duration;
        if (value > buffered) buffered = value;
      }
    }
    return ColoredBox(
      color: const Color(0xFF101114),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _controls = !_controls);
          _scheduleHide();
        },
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            if (ready)
              Center(
                child: AspectRatio(
                  aspectRatio: video.value.aspectRatio,
                  child: VideoPlayer(video),
                ),
              )
            else if (widget.posterUrl.isNotEmpty)
              Opacity(
                opacity: .35,
                child: Image.network(
                  widget.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => const SizedBox.shrink(),
                ),
              ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xC9000000),
                        Color(0x08000000),
                        Color(0xDE000000),
                      ],
                      stops: [0, .46, 1],
                    ),
                  ),
                ),
              ),
            ),
            if (error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Không tải được video bài học',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: widget.onRetry,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            if (busy && error == null)
              const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            if (ready && !busy)
              Center(
                child: IgnorePointer(
                  ignoring: !visible,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _skipButton(
                          Icons.skip_previous_rounded,
                          'Bài trước',
                          widget.onPrevious,
                        ),
                        const SizedBox(width: 30),
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: IconButton.filled(
                            tooltip: video.value.isPlaying
                                ? 'Tạm dừng'
                                : 'Phát video',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                            iconSize: 40,
                            icon: Icon(
                              video.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            onPressed: () async {
                              await widget.onPlayPause();
                              if (mounted) _scheduleHide();
                            },
                          ),
                        ),
                        const SizedBox(width: 30),
                        _skipButton(
                          Icons.skip_next_rounded,
                          'Bài kế tiếp',
                          widget.onNext,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 4,
              right: 4,
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: widget.fullscreen
                            ? 'Thu nhỏ video'
                            : 'Quay lại',
                        onPressed: widget.onBack,
                        color: Colors.white,
                        icon: Icon(
                          widget.fullscreen
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.arrow_back_rounded,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tốc độ phát',
                        onPressed: ready ? _settings : null,
                        color: Colors.white,
                        disabledColor: Colors.white38,
                        icon: const Icon(Icons.settings_outlined, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 6,
              bottom: 6,
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${AppFormatters.formatDurationFromSeconds(position ~/ 1000)} / ${AppFormatters.formatDurationFromSeconds(duration ~/ 1000)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (ready && video.value.playbackSpeed != 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                '${video.value.playbackSpeed}x',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: widget.fullscreen
                                ? 'Thu nhỏ video'
                                : 'Toàn màn hình',
                            onPressed: widget.onFullscreen,
                            color: Colors.white,
                            icon: Icon(
                              widget.fullscreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SizedBox(
                            height: 3,
                            child: Stack(
                              children: [
                                LinearProgressIndicator(
                                  value: buffered.clamp(0, 1),
                                  backgroundColor: Colors.white24,
                                  color: Colors.white54,
                                  minHeight: 3,
                                ),
                                LinearProgressIndicator(
                                  value: duration > 0
                                      ? (position / duration).clamp(0, 1)
                                      : 0,
                                  backgroundColor: Colors.transparent,
                                  color: AppColors.primary,
                                  minHeight: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skipButton(IconData icon, String tooltip, VoidCallback? action) =>
      IconButton(
        tooltip: tooltip,
        onPressed: action,
        color: Colors.white,
        disabledColor: Colors.white24,
        iconSize: 30,
        icon: Icon(icon),
      );
}
