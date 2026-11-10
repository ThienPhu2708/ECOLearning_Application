import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/course_repository.dart';
import '../../widgets/state_views.dart';

class CoursePreviewScreen extends StatefulWidget {
  const CoursePreviewScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.title,
  });
  final String courseId, lessonId, title;
  @override
  State<CoursePreviewScreen> createState() => _CoursePreviewScreenState();
}

class _CoursePreviewScreenState extends State<CoursePreviewScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _video;
  Object? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    VideoPlayerController? next;
    try {
      final data = await CourseRepository().preview(
        widget.courseId,
        widget.lessonId,
      );
      final url = JsonUtils.asString(data['videoUrl']);
      if (url.isEmpty) throw StateError('Bài học chưa có video xem thử.');
      next = VideoPlayerController.networkUrl(
        Uri.parse(ApiConfig.resolveMediaUrl(url)),
      );
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      await _video?.dispose();
      _video = next;
      next.addListener(_update);
    } catch (e) {
      await next?.dispose();
      if (mounted) _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _video?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.removeListener(_update);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(error: _error, onRetry: _load)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: video!.value.aspectRatio,
                    child: VideoPlayer(video),
                  ),
                  VideoProgressIndicator(
                    video,
                    allowScrubbing: true,
                    padding: const EdgeInsets.all(16),
                  ),
                  IconButton(
                    onPressed: () =>
                        video.value.isPlaying ? video.pause() : video.play(),
                    icon: Icon(
                      video.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
