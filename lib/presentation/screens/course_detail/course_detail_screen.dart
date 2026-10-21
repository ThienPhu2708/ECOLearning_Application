import 'package:flutter/material.dart';
import 'course_preview_screen.dart';
import '../../../core/utils/json_utils.dart';
import '../../widgets/course_favorite_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../learning_support/learning_data_scope.dart';
import '../../widgets/state_views.dart';
import '../../../data/models/course.dart';
import '../../widgets/app_button.dart';
import '../../widgets/rating_stars.dart';
import '../cart/cart_screen.dart';
import '../learning/learning_space_screen.dart';

/// Màn hình Chi tiết Khóa học theo QuyChuanThietKe_App.md Mục 4.4 & UC4
class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Course _course;
  Future<Map<String, dynamic>>? _reviews;
  bool _loading = true, _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final course =
          await (LearningDataScope.read(context)?.courses ?? CourseRepository())
              .detail(widget.course.id);
      if (mounted) setState(() => _course = course);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _requireLogin() {
    if (context.read<AuthProvider?>()?.isLoggedIn == true) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vui lòng đăng nhập để tiếp tục.')),
    );
    return false;
  }

  Future<void> _onAddToCart() async {
    if (!_requireLogin() || _busy) return;
    _busy = true;
    try {
      final added = await context.read<CartProvider>().add(_course);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added ? 'Đã thêm vào giỏ hàng.' : 'Khóa học đã có trong giỏ.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      _busy = false;
    }
  }

  Future<void> _onBuyNow() async {
    if (!_requireLogin()) return;
    await _onAddToCart();
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const CartScreen()),
      );
    }
  }

  Future<void> _onEnrollFree() async {
    if (!_requireLogin() || _busy) return;
    _busy = true;
    try {
      await OrderRepository().enrollFree(_course.id);
      await _load();
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => LearningSpaceScreen(course: _course),
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết khóa học')),
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
                          if (_course.tag.isNotEmpty)
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

                      // Giảng viên
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20.0,
                            backgroundImage: NetworkImage(
                              _course.instructorAvatar,
                            ),
                          ),
                          const SizedBox(width: AppDimens.p12),
                          Column(
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
                        ],
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
                        _course.description,
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

  // Header Video Trailer 16:9
  Widget _buildMediaHeader() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                _course.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) =>
                    const ColoredBox(color: AppColors.background),
              ),
              if (_course.chapters.any((c) => c.lessons.any((l) => l.isFree)))
                FilledButton.icon(
                  onPressed: () {
                    final lesson = _course.chapters
                        .expand((c) => c.lessons)
                        .firstWhere((l) => l.isFree);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => CoursePreviewScreen(
                          courseId: _course.id,
                          lessonId: lesson.id,
                          title: lesson.title,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Xem thử bài học'),
                ),
            ],
          ),
        ),

        // Nút Back & Share dạng tròn mờ
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
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.5),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép liên kết khóa học!'),
                  ),
                );
              },
            ),
          ),
        ),
        if (!_course.isEnrolled)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 64,
            child: CourseFavoriteButton(course: _course, size: 40),
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
                return Container(
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
    _reviews ??=
        (LearningDataScope.read(context)?.courses ?? CourseRepository())
            .reviews(_course.id);
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

          FutureBuilder<Map<String, dynamic>>(
            future: _reviews,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return Column(
                  children: [
                    const Text('Chưa tải được đánh giá.'),
                    TextButton(
                      onPressed: () => setState(() => _reviews = null),
                      child: const Text('Thử lại'),
                    ),
                  ],
                );
              }
              final items = JsonUtils.asMapList(snapshot.data?['items']);
              if (items.isEmpty) return const Text('Chưa có đánh giá.');
              return Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildReviewItem(
                          JsonUtils.asString(
                            item['fullName'] ?? item['userName'],
                          ),
                          JsonUtils.asString(item['comment']),
                          JsonUtils.asDouble(item['stars'] ?? item['rating']),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String comment, double star) {
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
        const SizedBox(height: 6.0),
        Text(
          comment,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textBody,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Sticky Bottom Bar cố định ở chân trang
  Widget _buildStickyBottomBar() {
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
              text: 'Tiếp tục học ngay',
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
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(_course.price),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20.0,
                      ),
                    ),
                    if (_course.originalPrice > _course.price)
                      Text(
                        AppFormatters.formatCurrency(_course.originalPrice),
                        style: AppTypography.captionTiny.copyWith(
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppDimens.p16),

                // Cụm nút hành động bên phải
                Expanded(
                  child: _course.isFree
                      ? AppButton(
                          text: 'Đăng ký học ngay',
                          onPressed: _onEnrollFree,
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
                                icon: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: AppColors.primary,
                                ),
                                onPressed: _onAddToCart,
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
