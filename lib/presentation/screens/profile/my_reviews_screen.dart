import '../../../core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/learning_repository.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../widgets/state_views.dart';
import '../../widgets/pagination_bar.dart';
import '../learning_support/learning_data_scope.dart';
import '../learning/review_flow.dart';

class MyReviewsScreen extends StatefulWidget {
  final LearningRepository? learning;
  final CourseRepository? courses;
  final ReviewRepository? reviews;
  const MyReviewsScreen({super.key, this.learning, this.courses, this.reviews});
  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late final _learning =
      widget.learning ??
      LearningDataScope.read(context)?.learning ??
      LearningRepository();
  late final _courses =
      widget.courses ??
      LearningDataScope.read(context)?.courses ??
      CourseRepository();
  late final _reviews =
      widget.reviews ??
      LearningDataScope.read(context)?.reviews ??
      ReviewRepository();
  List<Course> _items = [];
  bool _loading = true, _opening = false;
  Object? _error;
  final _pages = [1, 1];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final owned = <String, Course>{};
      for (final status in [
        MyCourseStatus.inProgress,
        MyCourseStatus.completed,
        MyCourseStatus.certified,
      ]) {
        var page = 1;
        while (true) {
          final result = await _learning.myCourses(status: status, page: page);
          for (final course in result.items) {
            owned[course.id] = course;
          }
          if (!result.hasMore) break;
          if (result.page < page) {
            throw StateError('Invalid pagination');
          }
          page = result.page + 1;
        }
      }
      final list = owned.values.toList(), details = <Course>[];
      for (var i = 0; i < list.length; i += 4) {
        details.addAll(
          await Future.wait(
            list.skip(i).take(4).map((c) => _courses.detail(c.id)),
          ),
        );
        if (!mounted) return;
      }
      if (mounted) {
        setState(() {
          _items = details;
          _pages[0] = _pages[1] = 1;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Course course) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await openCourseReview(
        context,
        course,
        courses: _courses,
        reviews: _reviews,
      );
      if (mounted) await _load();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Widget _reviewCard(Course course, bool reviewed) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 60,
            height: 70,
            child: course.imageUrl.isEmpty
                ? _cover()
                : Image.network(
                    course.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _cover(),
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
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading,
                ),
              ),
              if (course.instructor.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    course.instructor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (reviewed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8EB),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < course.myReviewRating!.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 13,
                              color: const Color(0xFFE9A020),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${course.myReviewRating!.toInt()}/5',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF99600A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _opening ? null : () => _open(course),
                    child: Text(
                      reviewed ? 'Xem đánh giá' : 'Viết đánh giá',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _cover() => const ColoredBox(
    color: AppColors.primaryLight,
    child: Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 26),
  );

  Widget _list(bool reviewed) {
    final index = reviewed ? 0 : 1;
    final items = _items
        .where(
          (c) => reviewed
              ? c.myReviewRating != null
              : c.myReviewRating == null && c.canReview,
        )
        .toList();
    final totalPages = (items.length / 10).ceil();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Text(
                reviewed
                    ? 'Bạn chưa đánh giá khóa học nào.'
                    : 'Không có khóa học chưa đánh giá.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final course in items.skip((_pages[index] - 1) * 10).take(10))
            _reviewCard(course, reviewed),
          PaginationBar(
            page: _pages[index],
            totalPages: totalPages,
            onPageChanged: (page) => setState(() => _pages[index] = page),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Đánh giá của tôi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEFF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [
                  BoxShadow(color: Color(0x080F172A), blurRadius: 4),
                ],
              ),
              tabs: [
                Tab(
                  text:
                      'Đã đánh giá (${_items.where((c) => c.myReviewRating != null).length})',
                ),
                Tab(
                  text:
                      'Chưa đánh giá (${_items.where((c) => c.myReviewRating == null && c.canReview).length})',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(error: _error, onRetry: _load)
          : TabBarView(children: [_list(true), _list(false)]),
    ),
  );
}
