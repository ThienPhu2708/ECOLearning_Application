import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/mock_data.dart';
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
  bool _isPlayingTrailer = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }

  void _onAddToCart() {
    if (!MockData.cartItems.any((c) => c.id == _course.id)) {
      setState(() {
        MockData.cartItems.add(_course);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm "${_course.title}" vào giỏ hàng!'),
          backgroundColor: AppColors.success,
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khóa học này đã có sẵn trong giỏ hàng.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _onBuyNow() {
    if (!MockData.cartItems.any((c) => c.id == _course.id)) {
      MockData.cartItems.add(_course);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  void _onEnrollFree() {
    setState(() {
      _course.isEnrolled = true;
      if (!MockData.allCourses.any((c) => c.id == _course.id && c.isEnrolled)) {
        _course.progress = 5.0;
      }
    });

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Nội dung cuộn
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header Video Trailer / Ảnh bìa
              SliverToBoxAdapter(
                child: _buildMediaHeader(),
              ),

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
                            backgroundImage:
                                NetworkImage(_course.instructorAvatar),
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
          child: _isPlayingTrailer
              ? Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        _course.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.5)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đang phát Video Xem thử (Trailer)',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 40,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () =>
                              setState(() => _isPlayingTrailer = false),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      _course.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isPlayingTrailer = true),
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
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36.0,
                        ),
                      ),
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
                  const SnackBar(content: Text('Đã sao chép liên kết khóa học!')),
                );
              },
            ),
          ),
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
    final chapters = _course.chapters.isNotEmpty
        ? _course.chapters
        : MockData.createFlutterChapters();

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

          // Nhận xét mẫu 1
          _buildReviewItem(
            'Lê Hoàng Anh',
            'Khóa học quá hay và thực chiến! Kiến thức logic rõ ràng, phần dự án giúp mình tự tin phỏng vấn.',
            5.0,
          ),
          const Divider(color: AppColors.border, height: 24),
          // Nhận xét mẫu 2
          _buildReviewItem(
            'Nguyễn Thị Mai',
            'Giảng viên giải thích rất dễ hiểu, code theo mượt mà và hỗ trợ nhiệt tình.',
            5.0,
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
