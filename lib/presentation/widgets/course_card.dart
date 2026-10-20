import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/course.dart';
import 'rating_stars.dart';

enum CourseCardLayout { card, listHorizontal }

/// Widget Thẻ khóa học chuẩn hóa theo QuyChuanThietKe_App.md Mục 2.3 & 4.2
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final CourseCardLayout layout;
  final double? width;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.layout = CourseCardLayout.card,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (layout == CourseCardLayout.listHorizontal) {
      return _buildListRow(context);
    }
    return _buildVerticalCard(context);
  }

  // Bố cục Card dọc chuẩn cho danh sách cuộn ngang (Home)
  Widget _buildVerticalCard(BuildContext context) {
    return Container(
      width: width ?? 260.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppDimens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDimens.radiusCard,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimens.radiusCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Ảnh bìa tỉ lệ 16:9
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15.0),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        course.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.surfaceSubtle,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (course.tag.isNotEmpty)
                    Positioned(
                      top: AppDimens.p8,
                      left: AppDimens.p8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.p8,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: course.tag.contains('TOP MATCH')
                              ? AppColors.primary
                              : (course.isFree
                                  ? AppColors.success
                                  : AppColors.warning),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          course.tag,
                          style: AppTypography.captionTiny.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // 2. Nội dung thông tin khóa học
              Padding(
                padding: const EdgeInsets.all(AppDimens.p12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.category,
                      style: AppTypography.captionTiny.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      course.instructor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    RatingStars(
                      rating: course.rating,
                      reviewCount: course.reviewCount,
                    ),
                    const SizedBox(height: 10.0),

                    // Nếu đang học -> Hiển thị thanh tiến độ
                    if (course.isEnrolled) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999.0),
                        child: LinearProgressIndicator(
                          value: course.progress / 100.0,
                          backgroundColor: AppColors.surfaceSubtle,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 6.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${course.progress.toInt()}% hoàn thành',
                        style: AppTypography.captionTiny.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else ...[
                      // Giá bán kép (Ưu đãi & Gốc)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(course.price),
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (course.originalPrice > course.price) ...[
                            const SizedBox(width: AppDimens.p8),
                            Text(
                              AppFormatters.formatCurrency(course.originalPrice),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bố cục Hàng ngang cho màn hình Khám phá & Tìm kiếm
  Widget _buildListRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppDimens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDimens.radiusCard,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimens.radiusCard,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh bìa bên trái
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: SizedBox(
                    width: 110,
                    height: 80,
                    child: Image.network(
                      course.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceSubtle,
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),

                // Nội dung bên phải
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                              course.category,
                              style: AppTypography.captionTiny.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            course.duration,
                            style: AppTypography.captionTiny.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        course.instructor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RatingStars(rating: course.rating),
                          Text(
                            AppFormatters.formatCurrency(course.price),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
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
    );
  }
}
