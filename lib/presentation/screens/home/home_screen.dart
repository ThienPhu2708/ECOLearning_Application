import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/recommendation_repository.dart';
import '../learning_support/learning_data_scope.dart';
import '../../widgets/state_views.dart';
import '../../../data/models/course.dart';
import '../../widgets/course_card.dart';
import '../../widgets/course_favorite_button.dart';
import '../../widgets/rating_stars.dart';
import '../course_detail/course_detail_screen.dart';

/// Tab 1: Màn hình Trang chủ theo QuyChuanThietKe_App.md Mục 4.2 & UC7
class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';
  List<Course> _apiCourses = [];
  List<Category> _apiCategories = [];
  Course? _topMatch;
  bool _loading = true;
  Object? _error;
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
      final injected = LearningDataScope.read(context)?.courses;
      final repo = injected ?? CourseRepository();
      final categories = await repo.categories();
      final page = await repo.courses(
        categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
        pageSize: 50,
        sort: 'popular',
      );
      Course? recommended = page.items.firstOrNull;
      if (injected == null) {
        try {
          recommended = (await RecommendationRepository().recommendations(
            limit: 1,
          )).items.firstOrNull;
        } catch (_) {
          /* Catalog remains available if recommendations fail. */
        }
      }
      if (mounted && request == _request) {
        setState(() {
          _apiCategories = [
            const Category(
              id: 'all',
              name: 'Tất cả',
              icon: Icons.apps_rounded,
              emoji: '📚',
            ),
            ...categories.where((c) => c.id != 'all'),
          ];
          _apiCourses = page.items;
          _topMatch = recommended;
        });
      }
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  List<Course> get _filteredCourses => _apiCourses;

  void _navigateToDetail(Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(error: _error, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppDimens.p24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Khối Hero Banner
                    _buildHeroBanner(),
                    const SizedBox(height: 24.0),

                    // 2. GỢI Ý RIÊNG CHO BẠN (COLLABORATIVE FILTERING: 98% FIT)
                    _buildTopMatchSection(),
                    const SizedBox(height: 24.0),

                    // 3. DANH MỤC PHỔ BIẾN
                    _buildCategoriesSection(),
                    const SizedBox(height: 24.0),

                    // 4. KHÓA HỌC BÁN CHẠY NHẤT 🔥 (Top Trending)
                    _buildTrendingSection(),
                    const SizedBox(height: 24.0),

                    // 5. KHÁM PHÁ THÊM KHÓA HỌC
                    _buildAllCoursesSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // Khối Hero Banner Gradient tím
  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1B4B), // Deep Indigo
            AppColors.primary, // Electric Indigo
          ],
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag viên thuốc nổi bật
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(999.0),
            ),
            child: Text(
              '✨ LEARNING, MADE PERSONAL',
              style: AppTypography.captionTiny.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // Headline
          Text(
            'Nâng tầm kỹ năng nghề nghiệp của bạn',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Khám phá lộ trình học tập cá nhân hóa chuẩn xác với đề xuất thông minh.',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16.0),

          // Nút Khám phá ngay
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            icon: const Icon(Icons.explore_rounded, size: 18),
            label: Text(
              'Khám phá ngay →',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              if (widget.onNavigateTab != null) {
                widget.onNavigateTab!(1); // Nhảy sang Tab 2: Khám phá
              }
            },
          ),
        ],
      ),
    );
  }

  // Khối đề xuất Collaborative Filtering (Top Match 98%)
  Widget _buildTopMatchSection() {
    final course = _topMatch;
    if (course == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppDimens.p8),
              Text(
                'GỢI Ý KHÓA HỌC',
                style: AppTypography.captionTiny.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Card đặc biệt nổi bật 98%
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppDimens.radiusCard,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppDimens.radiusCard,
              child: InkWell(
                onTap: () => _navigateToDetail(course),
                borderRadius: AppDimens.radiusCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge 98% Fit
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(14.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: AppDimens.p8),
                          Text(
                            'KHÓA HỌC ĐỀ XUẤT',
                            style: AppTypography.captionTiny.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ảnh & Thông tin
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.p16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    course.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (!course.isEnrolled)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CourseFavoriteButton(course: course),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12.0),

                          Text(
                            course.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17.0,
                            ),
                          ),
                          const SizedBox(height: 6.0),

                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 4,
                            children: [
                              Text(
                                '${course.instructor} • ',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              RatingStars(
                                rating: course.rating,
                                reviewCount: course.reviewCount,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),

                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppFormatters.formatCurrency(course.price),
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.formatCurrency(
                                      course.originalPrice,
                                    ),
                                    style: AppTypography.captionTiny.copyWith(
                                      color: AppColors.textMuted,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size(120, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppDimens.radiusButton,
                                  ),
                                ),
                                onPressed: () => _navigateToDetail(course),
                                child: const Text('Xem chi tiết'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Khối danh mục ngang (Horizontal Chips)
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          child: Text(
            'Danh mục phổ biến',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            scrollDirection: Axis.horizontal,
            itemCount: _apiCategories.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimens.p8),
            itemBuilder: (context, index) {
              final cat = _apiCategories[index];
              final isSelected = cat.id == _selectedCategory;

              return FilterChip(
                label: Text('${cat.emoji} ${cat.name}'),
                selected: isSelected,
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textHeading,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                onSelected: (val) {
                  setState(() {
                    _selectedCategory = cat.id;
                  });
                  _load();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Khối Khóa học Bán chạy nhất 🔥
  Widget _buildTrendingSection() {
    final trendingCourses = _apiCourses
        .where((c) => c.tag.contains('BÁN CHẠY') || c.rating >= 4.85)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Khóa học bán chạy nhất 🔥',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  }
                },
                child: Text(
                  'Xem tất cả >',
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
        SizedBox(
          height: 330,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            scrollDirection: Axis.horizontal,
            itemCount: trendingCourses.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimens.p12),
            itemBuilder: (context, index) {
              final course = trendingCourses[index];
              return CourseCard(
                course: course,
                onTap: () => _navigateToDetail(course),
              );
            },
          ),
        ),
      ],
    );
  }

  // Khối tất cả khóa học theo danh mục đang chọn
  Widget _buildAllCoursesSection() {
    final courses = _filteredCourses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khám phá khóa học (${courses.length})',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12.0),
          ...courses.map(
            (c) => CourseCard(
              course: c,
              layout: CourseCardLayout.listHorizontal,
              onTap: () => _navigateToDetail(c),
            ),
          ),
        ],
      ),
    );
  }
}
