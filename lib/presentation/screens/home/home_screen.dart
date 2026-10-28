import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../category/category_courses_screen.dart';
import '../learning_support/learning_data_scope.dart';
import '../../widgets/course_favorite_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/config/api_config.dart';
import '../../../data/models/category.dart';
import '../../../core/network/paged_result.dart';
import '../../../data/models/course.dart';
import '../../../data/models/coupon.dart';
import '../../../data/repositories/coupon_repository.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/recommendation_repository.dart';
import '../../navigation/app_navigator.dart';
import '../../providers/auth_provider.dart';
import '../coupons/coupon_details_screen.dart';
import '../coupons/coupon_wallet_screen.dart';
import '../../widgets/state_views.dart';
import '../../widgets/course_card.dart';
import '../../widgets/coupon_voucher_card.dart';
import '../../../data/models/home_feed.dart';
import '../../../data/repositories/home_repository.dart';
import '../../widgets/home_feed_sections.dart';
import '../../widgets/home_hero_carousel.dart';
import '../../widgets/home_highlights.dart';
import '../../widgets/instructor_strip.dart';
import '../../widgets/price_display.dart';
import '../../widgets/rating_stars.dart';
import '../course_detail/course_detail_screen.dart';
import '../learning/learning_space_screen.dart';

/// Tab 1: Màn hình Trang chủ theo QuyChuanThietKe_App.md Mục 4.2 & UC7
class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  CourseRepository get _courseRepo =>
      LearningDataScope.read(context)?.courses ?? CourseRepository();
  RecommendationRepository get _recoRepo =>
      LearningDataScope.read(context)?.recommendations ??
      RecommendationRepository();
  final CouponRepository _couponRepo = CouponRepository();
  final HomeRepository _homeRepo = HomeRepository();

  // Danh mục bấm ở "Danh mục phổ biến" mở màn riêng nên khối khám phá bên dưới luôn hiện tất cả
  final String _selectedCategory = 'all';

  bool _loading = true;
  Object? _error;
  List<Category> _categories = [];
  RecommendationResult? _recommend;
  List<Course> _popular = [];
  List<Coupon> _promotions = [];
  HomeFeed? _feed; // GET /home: các mục cá nhân hóa; lỗi thì chỉ mất các mục này

  // Khối "Khám phá khóa học" theo danh mục đang chọn (B2)
  bool _loadingCourses = false;
  Object? _coursesError;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadPromotions();
    _loadFeed();
  }

  /// Tải song song: danh mục (B1), gợi ý (C1), khóa học phổ biến (B2 sort=popular), danh sách khóa học (B2)
  /// Làm mới dữ liệu. [silent] = true (kéo xuống để làm mới, quay lại từ màn khác) thì giữ nguyên
  /// nội dung đang hiện, không thay bằng vòng tải toàn trang.
  Future<void> reload() async {
    await Future.wait([_load(silent: true), _loadPromotions(), _loadFeed()]);
  }

  Future<void> _loadFeed() async {
    try {
      final feed = await _homeRepo.home();
      if (!mounted) return;
      setState(() => _feed = feed);
    } catch (_) {
      // Các mục bổ sung của Trang chủ; lỗi API không được chặn trang khóa học.
    }
  }

  Future<void> _openContinue(HomeContinueItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningSpaceScreen(course: item.toCourse()),
      ),
    );
    if (mounted) _loadFeed(); // tiến độ vừa đổi
  }

  /// Mục khóa học của /home theo `key`, hoặc null nếu không có.
  Widget? _feedRail(String key) {
    final section = _feed?.section(key);
    if (section == null || section.courses.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: HomeCourseRail(
        section: section,
        onTap: (course) => _navigateToDetail(course, ClickSource.home),
        onSeeAll: () => widget.onNavigateTab?.call(1),
      ),
    );
  }

  Future<void> _loadPromotions() async {
    try {
      final result = await _couponRepo.collectable();
      if (!mounted) return;
      setState(() => _promotions = result.coupons);
    } catch (_) {
      // Khuyến mãi là nội dung bổ sung; lỗi API không được chặn trang khóa học.
    }
  }

  Future<void> _savePromotion(Coupon coupon) async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      AppNavigator.toLogin(message: 'Đăng nhập để lưu mã ưu đãi vào ví.');
      return;
    }
    try {
      final result = await _couponRepo.save(coupon.code);
      if (!mounted) return;
      final alreadySaved = result['alreadySaved'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alreadySaved
                ? 'Mã ${coupon.code} đã có trong ví.'
                : 'Đã lưu mã ${coupon.code} vào ví.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadPromotions();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  void _openCouponWallet() {
    if (!context.read<AuthProvider>().isLoggedIn) {
      AppNavigator.toLogin(message: 'Đăng nhập để xem ví mã ưu đãi.');
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CouponWalletScreen()));
  }

  Future<void> _showPromotionDetails(Coupon coupon) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CouponDetailsScreen(code: coupon.code),
      ),
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent || _recommend == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final categories = _courseRepo.categories();
      final recommend = _recoRepo.recommendations(limit: 10);
      final popular = _courseRepo.courses(sort: 'popular', pageSize: 8);
      final courses = _courseRepo.courses(
        categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
        sort: 'newest',
      );
      final values = await Future.wait<Object>([
        categories,
        recommend,
        popular,
        courses,
      ]);
      final c = values[0] as List<Category>;
      final r = values[1] as RecommendationResult;
      final p = values[2] as PagedResult<Course>;
      final l = values[3] as PagedResult<Course>;
      if (!mounted) return;
      setState(() {
        _categories = c;
        _recommend = r;
        _popular = p.items;
        _courses = l.items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silent && _recommend != null) {
        // Làm mới thất bại nhưng vẫn còn dữ liệu cũ: giữ lại và báo lỗi nhẹ
        showErrorSnackBar(context, e);
        return;
      }
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loadingCourses = true;
      _coursesError = null;
    });
    try {
      final page = await _courseRepo.courses(
        categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
        sort: 'newest',
      );
      if (!mounted) return;
      setState(() {
        _courses = page.items;
        _loadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _coursesError = e;
        _loadingCourses = false;
      });
    }
  }

  /// Khóa thuộc danh sách phổ biến (B2 sort=popular) thì hiện nhãn "Phổ biến" ở mọi mục của Trang chủ
  bool _isPopular(Course c) => _popular.any((p) => p.id == c.id);

  Future<void> _navigateToDetail(Course course, String source) async {
    await CourseDetailScreen.open(context, course, source);
    // Quay lại từ chi tiết: lượt xem / thả tim vừa rồi có thể làm đổi gợi ý
    if (mounted) _load(silent: true);
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
              onRefresh: reload,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(bottom: AppDimens.p24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Banner nhiều slide (giống banner trên web)
                    HomeHeroCarousel(onNavigateTab: widget.onNavigateTab),
                    const SizedBox(height: 24.0),

                    // 1b. TIẾP TỤC HỌC (khóa đang học dở)
                    if (_feed?.section('continue-learning') case final cont?) ...[
                      HomeContinueSection(
                        section: cont,
                        onOpen: _openContinue,
                      ),
                      const SizedBox(height: 24.0),
                    ],

                    if (_promotions.isNotEmpty) ...[
                      _buildPromotionSection(),
                      const SizedBox(height: 24.0),
                    ],

                    // 2. GỢI Ý RIÊNG CHO BẠN (tiêu đề đổi theo type của C1)
                    if (_recommend != null && _recommend!.items.isNotEmpty) ...[
                      _buildTopMatchSection(),
                      if (_recommend!.items.length > 1) ...[
                        const SizedBox(height: 16.0),
                        _buildRecommendedList(),
                      ],
                      const SizedBox(height: 24.0),
                    ],

                    // 3. DANH MỤC PHỔ BIẾN
                    _buildCategoriesSection(),
                    const SizedBox(height: 24.0),

                    // 4. BÁN CHẠY TUẦN NÀY (server); chưa có thì dùng danh sách phổ biến
                    if (_feedRail('best-sellers') case final rail?)
                      rail
                    else if (_popular.isNotEmpty) ...[
                      _buildTrendingSection(),
                      const SizedBox(height: 24.0),
                    ],

                    // 4a. VÌ BẠN ĐÃ HỌC ...
                    ?_feedRail('because-you-learned'),

                    // 4b. KHÓA HỌC ĐANG GIẢM GIÁ
                    if (_saleCourses.isNotEmpty) ...[
                      _buildSaleSection(),
                      const SizedBox(height: 24.0),
                    ],

                    // 4c. ĐÁNH GIÁ CAO, MỚI RA MẮT, YÊU THÍCH, ĐÃ XEM GẦN ĐÂY
                    ?_feedRail('top-rated'),
                    ?_feedRail('new-releases'),
                    ?_feedRail('favorites'),
                    ?_feedRail('recently-viewed'),

                    // 4d. GIẢNG VIÊN NỔI BẬT
                    if (_instructors.isNotEmpty) ...[
                      _buildInstructorSection(),
                      const SizedBox(height: 24.0),
                    ],

                    // 5. KHÁM PHÁ THÊM KHÓA HỌC
                    _buildAllCoursesSection(),
                    const SizedBox(height: 32.0),

                    // 6. SỐ LIỆU, GIÁ TRỊ CỐT LÕI VÀ QUY TRÌNH (giống trang chủ web)
                    const HomeWhySection(),
                    const SizedBox(height: 24.0),
                    const HomeStatsBand(),
                    const SizedBox(height: 24.0),
                    const HomeStepsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // Khối Hero Banner Gradient tím
  Widget _buildPromotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ƯU ĐÃI DÀNH CHO BẠN',
                      style: AppTypography.captionTiny.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Mã khuyến mãi',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _openCouponWallet,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Ví mã của tôi'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: CouponVoucherCard.height,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            scrollDirection: Axis.horizontal,
            itemCount: _promotions.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimens.p12),
            itemBuilder: (context, index) {
              final coupon = _promotions[index];
              return CouponVoucherCard(
                width: 330,
                coupon: coupon,
                onDetails: () => _showPromotionDetails(coupon),
                onSave: coupon.saved ? null : () => _savePromotion(coupon),
              );
            },
          ),
        ),
      ],
    );
  }

  // Khối đề xuất Collaborative Filtering (Top Match 98%)
  Widget _buildTopMatchSection() {
    final reco = _recommend!;
    final course = reco.items.first;

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
                reco.title.toUpperCase(),
                style: AppTypography.captionTiny.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            reco.subtitle,
            style: AppTypography.captionTiny.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10.0),

          // Card nổi bật khóa gợi ý đầu tiên
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
                onTap: () => _navigateToDetail(course, ClickSource.recommend),
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
                            reco.badge,
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
                                  child: CachedNetworkImage(
                                    imageUrl: course.imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => Container(
                                      color: AppColors.surfaceSubtle,
                                      child: const Icon(
                                        Icons.image_outlined,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
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
                            spacing: 8,
                            runSpacing: 6,
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
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              PriceDisplay(
                                price: course.price,
                                originalPrice: course.originalPrice,
                                stacked: true,
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size(120, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppDimens.radiusButton,
                                  ),
                                ),
                                onPressed: () => _navigateToDetail(
                                  course,
                                  ClickSource.recommend,
                                ),
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

  // Các khóa còn lại trong danh sách gợi ý (C1)
  Widget _buildRecommendedList() {
    final reco = _recommend!;
    final items = reco.items.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          child: Text(
            'Các khóa khác cùng gợi ý cho bạn',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 310,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimens.p12),
            itemBuilder: (context, index) => CourseCard(
              course: items[index],
              isPopular: _isPopular(items[index]),
              onTap: () =>
                  _navigateToDetail(items[index], ClickSource.recommend),
            ),
          ),
        ),
      ],
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
            itemCount: _categories.length + 1,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimens.p8),
            itemBuilder: (context, index) {
              final cat = index == 0
                  ? const Category(
                      id: 'all',
                      name: 'Tất cả',
                      icon: Icons.apps_rounded,
                      emoji: '✨',
                    )
                  : _categories[index - 1];
              // Bấm một danh mục thì mở danh sách khóa học của danh mục đó (giống web);
              // "Tất cả" chuyển sang tab Khám phá
              return ActionChip(
                label: Text(cat.name),
                backgroundColor: AppColors.surface,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHeading,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  side: const BorderSide(color: AppColors.border),
                ),
                onPressed: () {
                  if (index == 0) {
                    widget.onNavigateTab?.call(1);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryCoursesScreen(category: cat),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Các khóa đang giảm giá gom từ những danh sách đã tải (gợi ý, phổ biến, mới nhất); API chưa có bộ lọc giảm giá
  List<Course> get _saleCourses {
    final seen = <String>{};
    final all = [...?_recommend?.items, ..._popular, ..._courses];
    return all
        .where(
          (c) => SaleBadge.isOnSale(c.price, c.originalPrice) && seen.add(c.id),
        )
        .take(10)
        .toList();
  }

  /// Giảng viên gom từ những danh sách đã tải (API chưa có endpoint giảng viên)
  List<InstructorEntry> get _instructors {
    final teachers = _feed?.section('featured-teachers')?.teachers;
    if (teachers != null && teachers.isNotEmpty) {
      return [
        for (final t in teachers) InstructorEntry(t.toCourse(), t.coursesCount),
      ];
    }
    return InstructorEntry.group([
      ...?_recommend?.items,
      ..._popular,
      ..._courses,
    ]).take(10).toList();
  }

  Widget _buildInstructorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          child: Text(
            'Giảng viên nổi bật',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        InstructorStrip(instructors: _instructors),
      ],
    );
  }

  Widget _buildSaleSection() {
    final items = _saleCourses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          child: Text(
            'Đang giảm giá 🏷️',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 310,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimens.p12),
            itemBuilder: (context, index) => CourseCard(
              course: items[index],
              isPopular: _isPopular(items[index]),
              onTap: () => _navigateToDetail(items[index], ClickSource.home),
            ),
          ),
        ),
      ],
    );
  }

  // Khối Khóa học Bán chạy nhất 🔥
  Widget _buildTrendingSection() {
    final trendingCourses = _popular;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Khóa học phổ biến 🔥',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
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
          height: 310,
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
                isPopular: _isPopular(course),
                onTap: () => _navigateToDetail(course, ClickSource.home),
              );
            },
          ),
        ),
      ],
    );
  }

  // Khối tất cả khóa học theo danh mục đang chọn
  Widget _buildAllCoursesSection() {
    final courses = _courses;
    final source = _selectedCategory == 'all'
        ? ClickSource.home
        : ClickSource.category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khám phá khóa học',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12.0),
          if (_loadingCourses)
            const Padding(
              padding: EdgeInsets.all(AppDimens.p24),
              child: LoadingView(),
            )
          else if (_coursesError != null)
            ErrorView(error: _coursesError, onRetry: _loadCourses)
          else if (courses.isEmpty)
            const EmptyView(
              icon: Icons.school_outlined,
              title: 'Chưa có khóa học',
              message: 'Danh mục này chưa có khóa học nào đang mở bán.',
            )
          else
            ...courses.map(
              (c) => CourseCard(
                course: c,
                isPopular: _isPopular(c),
                layout: CourseCardLayout.listHorizontal,
                onTap: () => _navigateToDetail(c, source),
              ),
            ),
          if (!_loadingCourses &&
              _coursesError == null &&
              courses.length >= ApiConfig.defaultPageSize)
            Center(
              child: TextButton(
                onPressed: () => widget.onNavigateTab?.call(1),
                child: const Text('Xem thêm khóa học trong Khám phá'),
              ),
            ),
        ],
      ),
    );
  }
}
