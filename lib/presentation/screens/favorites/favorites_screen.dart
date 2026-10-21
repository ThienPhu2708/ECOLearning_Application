import '../../widgets/pagination_bar.dart';
import 'package:flutter/material.dart';
import '../learning_support/learning_data_scope.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../widgets/state_views.dart';
import '../course_detail/course_detail_screen.dart';
import '../learning_support/paged_collection.dart';
import '../learning_support/favorite_coordinator.dart';

class FavoritesScreen extends StatefulWidget {
  final FavoriteRepository? repository;
  final Future<void> Function(Course course)? onOpenCourse;
  const FavoritesScreen({super.key, this.repository, this.onOpenCourse});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoriteRepository _repo =
      widget.repository ??
      LearningDataScope.read(context)?.favorites ??
      FavoriteCoordinator.api.repository;
  late final PagedCollection<Course> _list = PagedCollection(
    (page) => _repo.list(page: page),
    (c) => c.id,
  );
  final Set<String> _removing = {};
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    _list.addListener(_update);
    _list.load();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  Future<void> _remove(Course course) async {
    if (_removing.contains(course.id)) return;
    setState(() => _removing.add(course.id));
    try {
      final favorite = await FavoriteCoordinator.forRepository(
        _repo,
      ).toggle(course);
      if (!mounted) return;
      if (!favorite) {
        _list.remove(course.id);
        await _list.load();
      } else {
        await _list.load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _removing.remove(course.id));
    }
  }

  Future<void> _open(Course course) async {
    if (_opening) return;
    _opening = true;
    try {
      if (widget.onOpenCourse != null) {
        await widget.onOpenCourse!(course);
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => CourseDetailScreen(course: course),
          ),
        );
      }
      if (mounted) await _list.load();
    } finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    _list.removeListener(_update);
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Khóa học yêu thích')),
    body: _list.loading && _list.items.isEmpty
        ? const LoadingView()
        : _list.error != null && _list.items.isEmpty
        ? ErrorView(error: _list.error, onRetry: _list.load)
        : RefreshIndicator(
            onRefresh: _list.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_list.items.isEmpty)
                  const SizedBox(
                    height: 380,
                    child: EmptyView(
                      icon: Icons.favorite_border,
                      title: 'Chưa có khóa học yêu thích',
                      message: 'Lưu các khóa học bạn quan tâm để dễ tìm lại.',
                    ),
                  ),
                if (_list.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                    child: Text(
                      '${_list.total} khóa học đã lưu',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                for (final course in _list.items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _open(course),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 88,
                                  height: 88,
                                  child: course.imageUrl.isEmpty
                                      ? _cover()
                                      : Image.network(
                                          course.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, error, trace) =>
                                              _cover(),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      course.instructor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppFormatters.formatCurrency(
                                        course.price,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                height: 40,
                                child: _removing.contains(course.id)
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : IconButton(
                                        padding: EdgeInsets.zero,
                                        tooltip: 'Bỏ yêu thích ${course.title}',
                                        onPressed: () => _remove(course),
                                        icon: const Icon(
                                          Icons.favorite_rounded,
                                          color: AppColors.error,
                                          size: 22,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_list.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      errorMessage(_list.error!),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                if (_list.error != null)
                  TextButton(
                    onPressed: () => _list.load(),
                    child: const Text('Tải lại danh sách'),
                  ),
                PaginationBar(
                  page: _list.page,
                  totalPages: _list.totalPages,
                  enabled: !_list.loading,
                  onPageChanged: (page) => _list.load(targetPage: page),
                ),
              ],
            ),
          ),
  );
  Widget _cover() => const ColoredBox(
    color: AppColors.primaryLight,
    child: Icon(Icons.school_outlined, color: AppColors.primary),
  );
}
