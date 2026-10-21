import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/repositories/course_repository.dart';
import '../learning_support/learning_data_scope.dart';
import '../../widgets/state_views.dart';
import '../../../data/models/course.dart';
import '../../widgets/course_card.dart';
import '../course_detail/course_detail_screen.dart';
import 'filter_bottom_sheet.dart';

/// Tab 2: Màn hình Khám phá & Tìm kiếm nâng cao theo QuyChuanThietKe_App.md Mục 4.3 & UC4
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  FilterCriteria _filterCriteria = FilterCriteria();

  List<Course> _apiCourses = [];
  List<String> _keywords = [];
  bool _loading = true, _loadingMore = false, _hasMore = false;
  Object? _error;
  int _page = 1, _request = 0;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_schedule);
    _load();
  }

  void _schedule() {
    setState(() => _searchQuery = _searchController.text.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load());
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loading || _loadingMore || !_hasMore)) return;
    final request = more ? _request : ++_request;
    final page = more ? _page + 1 : 1;
    setState(() {
      _error = null;
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
      }
    });
    try {
      final repo =
          LearningDataScope.read(context)?.courses ?? CourseRepository();
      final result = await repo.courses(
        q: _searchQuery,
        page: page,
        minRating: _filterCriteria.minRating > 0
            ? _filterCriteria.minRating
            : null,
        level: _filterCriteria.level == 'Tất cả' ? null : _filterCriteria.level,
        price: _filterCriteria.onlyFree ? 'free' : null,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _apiCourses = more ? [..._apiCourses, ...result.items] : result.items;
        _page = result.page;
        _hasMore = result.hasMore;
      });
      if (_keywords.isEmpty) {
        final categories = await repo.categories();
        if (mounted && request == _request) {
          setState(
            () => _keywords = categories.map((c) => c.name).take(8).toList(),
          );
        }
      }
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  bool get _hasActiveFilter =>
      _filterCriteria.minRating > 0 ||
      _filterCriteria.level != 'Tất cả' ||
      _filterCriteria.onlyFree;

  List<Course> get _filteredCourses => _apiCourses;

  void _openFilter() {
    FilterBottomSheet.show(
      context,
      initialCriteria: _filterCriteria,
      onApply: (newCriteria) {
        setState(() {
          _filterCriteria = newCriteria;
        });
        _load();
      },
    );
  }

  void _applyKeyword(String keyword) {
    setState(() {
      _searchController.text = keyword;
      _searchQuery = keyword;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_schedule);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = _filteredCourses;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thanh tìm kiếm cố định & Nút Filter
            Padding(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm khóa học, giảng viên, kỹ năng...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p8),
                  // Nút mở bộ lọc Modal Bottom Sheet
                  Badge(
                    isLabelVisible: _hasActiveFilter,
                    backgroundColor: AppColors.primary,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: _hasActiveFilter
                            ? AppColors.primaryLight
                            : AppColors.surfaceSubtle,
                        borderRadius: AppDimens.radiusButton,
                        border: Border.all(
                          color: _hasActiveFilter
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: _hasActiveFilter
                              ? AppColors.primary
                              : AppColors.textHeading,
                        ),
                        tooltip: 'Bộ lọc nâng cao',
                        onPressed: _openFilter,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Danh sách từ khóa xu hướng (Trending Tags)
            SizedBox(
              height: 34,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
                scrollDirection: Axis.horizontal,
                itemCount: _keywords.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppDimens.p8),
                itemBuilder: (context, index) {
                  final tag = _keywords[index];
                  final isCurrent =
                      _searchQuery.toLowerCase() == tag.toLowerCase();

                  return GestureDetector(
                    onTap: () => _applyKeyword(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(999.0),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: AppTypography.captionTiny.copyWith(
                          color: isCurrent
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12.0),

            // 3. Số lượng kết quả
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tìm thấy ${courses.length} khóa học phù hợp',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_hasActiveFilter || _searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _filterCriteria = FilterCriteria();
                        });
                      },
                      child: Text(
                        'Xóa bộ lọc',
                        style: AppTypography.captionTiny.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),

            // 4. Danh sách khóa học hoặc Trạng thái rỗng
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                  ? ErrorView(error: _error, onRetry: _load)
                  : courses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimens.p16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: courses.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == courses.length) {
                          return TextButton(
                            onPressed: _loadingMore
                                ? null
                                : () => _load(more: true),
                            child: Text(
                              _loadingMore ? 'Đang tải…' : 'Xem thêm',
                            ),
                          );
                        }
                        final course = courses[index];
                        return CourseCard(
                          course: course,
                          layout: CourseCardLayout.listHorizontal,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CourseDetailScreen(course: course),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Trạng thái rỗng khi không tìm thấy kết quả
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 44,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Không tìm thấy kết quả phù hợp',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Hãy thử thay đổi từ khóa tìm kiếm hoặc nới lỏng các tiêu chí trong bộ lọc nâng cao.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _filterCriteria = FilterCriteria();
                });
              },
              child: const Text('Đặt lại tìm kiếm & Bộ lọc'),
            ),
          ],
        ),
      ),
    );
  }
}
