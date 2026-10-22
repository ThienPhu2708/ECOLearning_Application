import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/category.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/course_repository.dart';
import '../../widgets/course_card.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';
import '../course_detail/course_detail_screen.dart';
import '../learning_support/learning_data_scope.dart';

/// Danh sách khóa học của một danh mục, mở khi bấm vào danh mục ở Trang chủ (giống trang
/// `/Course?category=...` trên web). Dùng B2 với `categoryId`, mỗi trang 10 khóa, có sắp xếp.
class CategoryCoursesScreen extends StatefulWidget {
  final Category category;

  /// Cho phép thay repository khi test
  final CourseRepository? repository;

  const CategoryCoursesScreen({super.key, required this.category, this.repository});

  @override
  State<CategoryCoursesScreen> createState() => _CategoryCoursesScreenState();
}

class _CategoryCoursesScreenState extends State<CategoryCoursesScreen> {
  static const _sorts = {
    'popular': 'Phổ biến',
    'newest': 'Mới nhất',
    'rating': 'Đánh giá cao',
    'price_asc': 'Giá tăng dần',
    'price_desc': 'Giá giảm dần',
  };

  final _scroll = ScrollController();

  List<Course> _courses = [];
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  String _sort = 'popular';
  bool _loading = true;
  Object? _error;
  int _requestId = 0; // bỏ qua kết quả của lượt gọi cũ khi đổi trang / sắp xếp nhanh

  CourseRepository get _repo =>
      widget.repository ?? LearningDataScope.read(context)?.courses ?? CourseRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToPage(1));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.courses(categoryId: widget.category.id, sort: _sort, page: page);
      if (!mounted || id != _requestId) return;
      setState(() {
        _courses = result.items;
        _page = result.page;
        _total = result.total;
        _totalPages = result.totalPages < 1 ? 1 : result.totalPages;
        _loading = false;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sắp xếp',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sort,
            onSelected: (value) {
              if (value == _sort) return;
              setState(() => _sort = value);
              _goToPage(1);
            },
            itemBuilder: (context) => [
              for (final e in _sorts.entries) PopupMenuItem(value: e.key, child: Text(e.value)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimens.p16, AppDimens.p12, AppDimens.p16, AppDimens.p4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loading ? 'Đang tải...' : '$_total khóa học (trang $_page/$_totalPages)',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Sắp xếp: ${_sorts[_sort]}',
                  style: AppTypography.captionTiny.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
          if (!_loading && _error == null)
            PaginationBar(page: _page, totalPages: _totalPages, onPageChanged: _goToPage),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(error: _error, onRetry: () => _goToPage(_page));
    if (_courses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _goToPage(1),
        color: AppColors.primary,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: const EmptyView(
                icon: Icons.school_outlined,
                title: 'Danh mục chưa có khóa học',
                message: 'Hiện chưa có khóa học nào đang mở bán trong danh mục này.',
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _goToPage(_page),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(AppDimens.p16),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return CourseCard(
            course: course,
            layout: CourseCardLayout.listHorizontal,
            onTap: () => CourseDetailScreen.open(context, course, ClickSource.category),
          );
        },
      ),
    );
  }
}
