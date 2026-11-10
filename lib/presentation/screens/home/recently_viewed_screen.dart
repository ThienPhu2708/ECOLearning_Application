import 'package:flutter/material.dart';

import '../../../data/models/course.dart';
import '../../../data/models/home_feed.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/home_repository.dart';
import '../../widgets/course_card.dart';
import '../../widgets/state_views.dart';
import '../course_detail/course_detail_screen.dart';

/// History supplied by /home; the server currently returns up to ten entries.
class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({super.key, this.repository, this.onOpenCourse});
  final HomeRepository? repository;
  final Future<void> Function(Course)? onOpenCourse;

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  late final HomeRepository _repository = widget.repository ?? HomeRepository();
  List<HomeCourseItem> _items = [];
  Object? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feed = await _repository.home();
      if (!mounted || request != _request) return;
      setState(() => _items = feed.section('recently-viewed')?.courses ?? []);
    } catch (error) {
      if (mounted && request == _request) setState(() => _error = error);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _open(Course course) async {
    if (widget.onOpenCourse != null) {
      await widget.onOpenCourse!(course);
    } else {
      await CourseDetailScreen.open(context, course, ClickSource.home);
    }
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đã xem gần đây')),
    body: _loading
        ? const LoadingView()
        : _error != null
        ? ErrorView(error: _error, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Text('Hiển thị tối đa 10 khóa học gần đây.'),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: EmptyView(title: 'Chưa có khóa học xem gần đây'),
                  ),
                for (final item in _items) ...[
                  CourseCard(
                    course: item.course,
                    layout: CourseCardLayout.listHorizontal,
                    badges: [if (item.badge != null) item.badge!],
                    onTap: () => _open(item.course),
                  ),
                  if (item.note?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(item.note!),
                    ),
                ],
              ],
            ),
          ),
  );
}
