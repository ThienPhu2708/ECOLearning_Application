import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/json_utils.dart';
import '../../../core/utils/html_text.dart';
import '../../../data/models/course.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/course_repository.dart';
import '../../widgets/course_favorite_button.dart';
import '../../widgets/price_display.dart';
import '../../../data/repositories/order_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/course_card.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/review_helpful_bar.dart';
import '../../widgets/state_views.dart';
import '../cart/cart_screen.dart';
import '../instructor/instructor_screen.dart';
import '../learning/learning_space_screen.dart';

/// Màn hình Chi tiết Khóa học theo QuyChuanThietKe_App.md Mục 4.4 & UC4
/// API: B3 (chi tiết), B4 (đánh giá), E2 (đánh giá hữu ích), B6 (click), B7 (tương tự), B8 (xem thử), D1 (yêu thích), F6 (học miễn phí).
class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  /// Mở màn chi tiết và ghi nhận click (B6) để bổ sung dữ liệu cho gợi ý.
  /// [source]: một trong các hằng số của [ClickSource].
  static Future<void> open(BuildContext context, Course course, String source) {
    if (TokenStorage.instance.hasToken) {
      CourseRepository().trackClick(course.id, source);
    }
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(course: course),
      ),
    );
  }

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _courseRepo = CourseRepository();
  final _orderRepo = OrderRepository();

  late Course _course;
  bool _loading = true;
  Object? _error;

  // Đánh giá (B4) và khóa học tương tự (B7)
  List<Map<String, dynamic>> _reviews = [];
  Object? _reviewsError;
  List<Course> _similar = [];

  bool _enrolling = false;

  // Video xem thử (B8)
  VideoPlayerController? _preview;
  bool _previewLoading = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _load();
  }

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _courseRepo.detail(widget.course.id);
      if (!mounted) return;
      setState(() {
        _course = detail;
        _loading = false;
      });
      _loadExtras();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// Đánh giá và khóa học tương tự chỉ là phụ: lỗi thì chỉ ẩn khối đó, không chặn cả màn hình
  Future<void> _loadExtras() async {
    try {
      final data = await _courseRepo.reviews(_course.id);
      if (!mounted) return;
      setState(() {
        _reviews = JsonUtils.asMapList(data['items']);
        _reviewsError = null;
      });
    } catch (e) {
      if (mounted) setState(() => _reviewsError = e);
    }
    try {
      final similar = await _courseRepo.similar(_course.id);
      if (!mounted) return;
      setState(
        () => _similar = similar.where((c) => c.id != _course.id).toList(),
      );
    } catch (_) {}
  }

  Future<void> _onAddToCart() async {
    final cart = context.read<CartProvider>();
    final added = await cart.add(_course);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Đã thêm "${_course.title}" vào giỏ hàng!'
                : 'Khóa học này đã có sẵn trong giỏ hàng.',
          ),
          backgroundColor: added ? AppColors.success : AppColors.primary,
          persist: false,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Xem giỏ',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ),
      );
  }

  Future<void> _onBuyNow() async {
    await context.read<CartProvider>().add(_course);
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CartScreen()));
  }

  Future<void> _onEnrollFree() async {
    if (_enrolling) return;
    setState(() => _enrolling = true);
    try {
      await _orderRepo.enrollFree(_course.id);
      if (!mounted) return;
      setState(() {
        _course = _course.copyWith(isEnrolled: true);
        _enrolling = false;
      });
      context.read<AuthProvider>().refreshUser().catchError((_) {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký khóa học thành công! Chuyển vào bài giảng...'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LearningSpaceScreen(course: _course),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enrolling = false;
        // 409: đã sở hữu khóa học này rồi
        if (e.statusCode == 409) _course = _course.copyWith(isEnrolled: true);
      });
      showErrorSnackBar(context, e);
    }
  }

  /// Bài đầu tiên cho phép xem thử (isPreview)
  Lesson? get _previewLesson {
    for (final chapter in _course.chapters) {
      for (final lesson in chapter.lessons) {
        if (lesson.isFree) return lesson;
      }
    }
    return null;
  }

  Future<void> _playPreview([Lesson? lesson]) async {
    final target = lesson ?? _previewLesson;
    if (target == null || _previewLoading) return;
    setState(() => _previewLoading = true);
    try {
      final data = await _courseRepo.preview(_course.id, target.id);
      final url = JsonUtils.asStringOrNull(data['videoUrl']);
      if (url == null) {
        throw const ApiException(message: 'Bài học này chưa có video xem thử.');
      }
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(ApiConfig.resolveMediaUrl(url)),
      );
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _preview?.dispose();
      setState(() {
        _preview = controller;
        _previewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _previewLoading = false);
      showErrorSnackBar(context, e);
    }
  }

  void _closePreview() {
    _preview?.dispose();
    setState(() => _preview = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.course.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: _loading
            ? const LoadingView()
            : ErrorView(error: _error, onRetry: _load),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Nội dung cuộn
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header Video Trailer / Ảnh bìa
              SliverToBoxAdapter(child: _buildMediaHeader()),

              // 2. Nội dung chi tiết
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag danh mục & Trình độ
                      Row(
                        children: [
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
                              _course.category,
                              style: AppTypography.captionTiny.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimens.p8),
                          if (SaleBadge.isOnSale(
                            _course.price,
                            _course.originalPrice,
                          )) ...[
                            SaleBadge(
                              price: _course.price,
                              originalPrice: _course.originalPrice,
                              compact: true,
                            ),
                            const SizedBox(width: AppDimens.p8),
                          ],
                          if (SaleBadge.showTag(
                            _course.tag,
                            _course.price,
                            _course.originalPrice,
                          ))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: _course.isFree
                                    ? AppColors.successLight
                                    : AppColors.warningLight,
                                borderRadius: BorderRadius.circular(999.0),
                              ),
                              child: Text(
                                _course.tag,
                                style: AppTypography.captionTiny.copyWith(
                                  color: _course.isFree
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      // Tên khóa học
                      Text(
                        _course.title,
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      // Giảng viên (bấm để xem hồ sơ)
                      InkWell(
                        borderRadius: BorderRadius.circular(12.0),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InstructorScreen(course: _course),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20.0,
                                backgroundImage: NetworkImage(
                                  _course.instructorAvatar,
                                ),
                                onBackgroundImageError: (_, _) {},
                              ),
                              const SizedBox(width: AppDimens.p12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _course.instructor,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _course.instructorRole,
                                      style: AppTypography.captionTiny.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Xem hồ sơ',
                                style: AppTypography.captionTiny.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // 3 Thẻ thống kê (Metric Pills)
                      Row(
                        children: [
                          _buildMetricPill(
                            Icons.video_library_outlined,
                            '${_course.lessonsCount} bài học',
                          ),
                          const SizedBox(width: AppDimens.p8),
                          _buildMetricPill(
                            Icons.schedule_rounded,
                            _course.duration,
                          ),
                          const SizedBox(width: AppDimens.p8),
                          _buildMetricPill(
                            Icons.bar_chart_rounded,
                            _course.level,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),

                      // Giới thiệu khóa học
                      Text(
                        'Về khóa học này',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        htmlToPlainText(_course.description),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textBody,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Mục tiêu đầu ra (Outcomes)
                      if (_course.outcomes.isNotEmpty) ...[
                        Text(
                          'Mục tiêu đạt được sau khóa học',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        ..._course.outcomes.map(
                          (outcome) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 20.0,
                                ),
                                const SizedBox(width: AppDimens.p12),
                                Expanded(
                                  child: Text(
                                    outcome,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textBody,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),
                      ],

                      // Đề cương bài giảng dạng Accordion (ExpansionTile)
                      Text(
                        'Đề cương bài học (${_course.lessonsCount} bài)',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      _buildSyllabusAccordion(),
                      const SizedBox(height: 24.0),

                      // Đánh giá & Nhận xét
                      _buildReviewSection(),
                      if (_similar.isNotEmpty) ...[
                        const SizedBox(height: 24.0),
                        _buildSimilarSection(),
                      ],
                      const SizedBox(height: 100.0), // Padding cho sticky bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _coverImage() => Image.network(
    _course.imageUrl,
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => Container(
      color: AppColors.surfaceSubtle,
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: AppColors.textMuted,
      ),
    ),
  );

  // Header: ảnh bìa, hoặc video xem thử (B8) khi người dùng bấm nút phát
  Widget _buildMediaHeader() {
    final hasPreview = _previewLesson != null;
    final preview = _preview;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: preview != null
              ? Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: preview.value.aspectRatio,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            preview.value.isPlaying
                                ? preview.pause()
                                : preview.play();
                          }),
                          child: VideoPlayer(preview),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _closePreview,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    _coverImage(),
                    if (hasPreview)
                      Container(color: Colors.black.withValues(alpha: 0.35)),
                    if (hasPreview)
                      Center(
                        child: GestureDetector(
                          onTap: _playPreview,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _previewLoading
                                ? const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36.0,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),

        // Nút Back & Yêu thích dạng tròn mờ
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: AppDimens.p16,
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: AppDimens.p16,
          child: CourseFavoriteButton(course: _course),
        ),
      ],
    );
  }

  // Thẻ chỉ số (Metric Pill)
  Widget _buildMetricPill(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20.0, color: AppColors.primary),
            const SizedBox(height: 4.0),
            Text(
              text,
              style: AppTypography.captionTiny.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cây bài học Accordion (ExpansionTile)
  Widget _buildSyllabusAccordion() {
    final chapters = _course.chapters;
    if (chapters.isEmpty) {
      return const EmptyView(
        icon: Icons.list_alt_rounded,
        title: 'Chưa có đề cương',
        message: 'Khóa học này chưa cập nhật nội dung bài học.',
      );
    }

    return Column(
      children: chapters.map((chapter) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimens.p12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.radiusCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: chapter == chapters.first,
              title: Text(
                chapter.title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading,
                ),
              ),
              subtitle: Text(
                '${chapter.lessons.length} bài học',
                style: AppTypography.captionTiny.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              children: chapter.lessons.map((lesson) {
                return InkWell(
                  onTap: lesson.isFree ? () => _playPreview(lesson) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p16,
                      vertical: AppDimens.p12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.surfaceSubtle),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          lesson.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.play_circle_outline_rounded,
                          color: lesson.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                          size: 22.0,
                        ),
                        const SizedBox(width: AppDimens.p12),
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                        if (lesson.isFree) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              'Xem thử',
                              style: AppTypography.captionTiny.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimens.p8),
                        ],
                        Text(
                          lesson.duration,
                          style: AppTypography.captionTiny.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Khối Đánh giá & Nhận xét
  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đánh giá từ học viên',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              RatingStars(
                rating: _course.rating,
                reviewCount: _course.reviewCount,
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          if (_reviewsError != null)
            Text(
              'Không tải được đánh giá. Kéo lại trang để thử lại.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else if (_reviews.isEmpty)
            Text(
              'Khóa học chưa có đánh giá nào.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            for (var i = 0; i < _reviews.length; i++) ...[
              if (i > 0) const Divider(color: AppColors.border, height: 24),
              _buildReviewItem(
                JsonUtils.asString(
                  _reviews[i]['userName'] ??
                      _reviews[i]['fullName'] ??
                      _reviews[i]['user'],
                  fallback: 'Học viên',
                ),
                JsonUtils.asString(_reviews[i]['comment']),
                JsonUtils.asDouble(_reviews[i]['rating']),
                review: _reviews[i],
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildReviewItem(
    String name,
    String comment,
    double star, {
    Map<String, dynamic>? review,
  }) {
    final reviewId = JsonUtils.asString(review?['id']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            RatingStars(rating: star),
          ],
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 6.0),
          Text(
            comment,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textBody,
              height: 1.4,
            ),
          ),
        ],
        // "Bạn thấy hữu ích?" (E2)
        if (review != null && reviewId.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          ReviewHelpfulBar(key: ValueKey('helpful/$reviewId'), review: review),
        ],
      ],
    );
  }

  // Khóa học tương tự (B7)
  Widget _buildSimilarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khóa học tương tự',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 310,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _similar.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimens.p12),
            itemBuilder: (context, index) {
              final c = _similar[index];
              return CourseCard(
                course: c,
                onTap: () =>
                    CourseDetailScreen.open(context, c, ClickSource.similar),
              );
            },
          ),
        ),
      ],
    );
  }

  // Sticky Bottom Bar cố định ở chân trang
  Widget _buildStickyBottomBar() {
    final inCart = context.watch<CartProvider>().contains(_course.id);
    return Container(
      padding: EdgeInsets.only(
        top: AppDimens.p12,
        bottom: MediaQuery.of(context).padding.bottom + AppDimens.p12,
        left: AppDimens.p16,
        right: AppDimens.p16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: _course.isEnrolled
          ? AppButton(
              text: 'Vào học',
              icon: const Icon(Icons.play_circle_filled_rounded, size: 22),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LearningSpaceScreen(course: _course),
                  ),
                );
              },
            )
          : Row(
              children: [
                // Giá tiền bên trái
                PriceDisplay(
                  price: _course.price,
                  originalPrice: _course.originalPrice,
                  size: PriceSize.large,
                  stacked: true,
                ),
                const SizedBox(width: AppDimens.p16),

                // Cụm nút hành động bên phải
                Expanded(
                  child: _course.isFree
                      ? AppButton(
                          text: 'Đăng ký học ngay',
                          isLoading: _enrolling,
                          onPressed: _onEnrollFree,
                        )
                      : !_course.inCartAllowed
                      ? const AppButton(
                          text: 'Hiện chưa thể mua khóa học này',
                          onPressed: null,
                        )
                      : Row(
                          children: [
                            // Nút thêm vào giỏ
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: AppDimens.radiusButton,
                              ),
                              child: IconButton(
                                tooltip: inCart
                                    ? 'Xem giỏ hàng'
                                    : 'Thêm vào giỏ',
                                icon: Icon(
                                  inCart
                                      ? Icons.shopping_cart_checkout_rounded
                                      : Icons.add_shopping_cart_rounded,
                                  color: AppColors.primary,
                                ),
                                onPressed: inCart
                                    ? () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CartScreen(),
                                        ),
                                      )
                                    : _onAddToCart,
                              ),
                            ),
                            const SizedBox(width: AppDimens.p12),

                            // Nút Mua ngay
                            Expanded(
                              child: AppButton(
                                text: 'Mua ngay',
                                onPressed: _onBuyNow,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
