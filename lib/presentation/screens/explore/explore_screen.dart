import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/mock_data.dart';
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

  bool get _hasActiveFilter =>
      _filterCriteria.minRating > 0 ||
      _filterCriteria.level != 'Tất cả' ||
      _filterCriteria.onlyFree;

  List<Course> get _filteredCourses {
    return MockData.allCourses.where((course) {
      // 1. Lọc theo từ khóa tìm kiếm (Title, Instructor, Category)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = course.title.toLowerCase().contains(q);
        final matchInstructor = course.instructor.toLowerCase().contains(q);
        final matchCat = course.category.toLowerCase().contains(q);
        if (!matchTitle && !matchInstructor && !matchCat) return false;
      }

      // 2. Lọc theo xếp hạng sao
      if (course.rating < _filterCriteria.minRating) return false;

      // 3. Lọc theo cấp độ
      if (_filterCriteria.level != 'Tất cả' &&
          !course.level.toLowerCase().contains(_filterCriteria.level.toLowerCase())) {
        return false;
      }

      // 4. Lọc theo giá miễn phí
      if (_filterCriteria.onlyFree && !course.isFree) return false;

      return true;
    }).toList();
  }

  void _openFilter() {
    FilterBottomSheet.show(
      context,
      initialCriteria: _filterCriteria,
      onApply: (newCriteria) {
        setState(() {
          _filterCriteria = newCriteria;
        });
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
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
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
                itemCount: MockData.trendingKeywords.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppDimens.p8),
                itemBuilder: (context, index) {
                  final tag = MockData.trendingKeywords[index];
                  final isCurrent = _searchQuery.toLowerCase() == tag.toLowerCase();

                  return GestureDetector(
                    onTap: () => _applyKeyword(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(999.0),
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: AppTypography.captionTiny.copyWith(
                          color: isCurrent ? Colors.white : AppColors.textSecondary,
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
              child: courses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimens.p16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return CourseCard(
                          course: course,
                          layout: CourseCardLayout.listHorizontal,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CourseDetailScreen(course: course),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
