import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/course.dart';
import 'rating_stars.dart';

enum CourseCardLayout { card, listHorizontal }

/// Nhãn "Phổ biến" cho các khóa thuộc nhóm khóa học phổ biến
class PopularBadge extends StatelessWidget {
  final bool compact;
  const PopularBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6.0 : AppDimens.p8, vertical: compact ? 2.0 : 4.0),
      decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(6.0)),
      child: Text(
        '🔥 Phổ biến',
        style: AppTypography.captionTiny.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Nhãn "Đang giảm giá -X%" cho khóa có giá bán thấp hơn giá gốc
class SaleBadge extends StatelessWidget {
  final double price;
  final double originalPrice;
  final bool compact;

  const SaleBadge({super.key, required this.price, required this.originalPrice, this.compact = false});

  static bool isOnSale(double price, double originalPrice) => originalPrice > price && originalPrice > 0;

  /// Nhãn `tag` server gắn sẵn mà cũng nói về giảm giá ("Giảm giá"...). Khi khóa đang giảm thì bỏ nhãn này
  /// để chỉ còn một nhãn "Đang giảm giá -X%".
  static bool isSaleTag(String tag) => tag.toLowerCase().contains('giảm');

  /// Có nên hiện nhãn `tag` của server không
  static bool showTag(String tag, double price, double originalPrice) =>
      tag.isNotEmpty && !(isOnSale(price, originalPrice) && isSaleTag(tag));

  @override
  Widget build(BuildContext context) {
    if (!isOnSale(price, originalPrice)) return const SizedBox.shrink();
    final percent = ((originalPrice - price) / originalPrice * 100).round();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6.0 : AppDimens.p8, vertical: compact ? 2.0 : 4.0),
      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(6.0)),
      child: Text(
        percent > 0 ? 'Đang giảm giá -$percent%' : 'Đang giảm giá',
        style: AppTypography.captionTiny.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Widget Thẻ khóa học chuẩn hóa theo QuyChuanThietKe_App.md Mục 2.3 & 4.2
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final CourseCardLayout layout;
  final double? width;

  /// Nút nhỏ đặt đè lên góc ảnh bìa (kiểu danh sách), vd: trái tim bỏ yêu thích
  final Widget? imageOverlay;

  /// Khóa thuộc nhóm phổ biến thì hiện nhãn "Phổ biến" trên ảnh
  final bool isPopular;

  /// Nút tim ở góc phải ảnh (kiểu danh sách). Null thì không hiện nút.
  final bool? isFavorite;
  final VoidCallback? onFavoriteTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.layout = CourseCardLayout.card,
    this.width,
    this.imageOverlay,
    this.isPopular = false,
    this.isFavorite,
    this.onFavoriteTap,
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
                  // Nhãn "Phổ biến" và "Đang giảm giá" xếp dọc, đè lên góc trái của ảnh;
                  // nhãn khác của server (vd "Bán chạy") nhường sang góc phải khi đã có nhãn bên trái
                  if (isPopular || SaleBadge.isOnSale(course.price, course.originalPrice))
                    Positioned(
                      top: AppDimens.p8,
                      left: AppDimens.p8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPopular) const PopularBadge(),
                          if (isPopular && SaleBadge.isOnSale(course.price, course.originalPrice))
                            const SizedBox(height: 4.0),
                          if (SaleBadge.isOnSale(course.price, course.originalPrice))
                            SaleBadge(price: course.price, originalPrice: course.originalPrice),
                        ],
                      ),
                    ),
                  if (SaleBadge.showTag(course.tag, course.price, course.originalPrice))
                    Positioned(
                      top: AppDimens.p8,
                      left: (isPopular || SaleBadge.isOnSale(course.price, course.originalPrice)) ? null : AppDimens.p8,
                      right: (isPopular || SaleBadge.isOnSale(course.price, course.originalPrice)) ? AppDimens.p8 : null,
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
    final onSale = SaleBadge.isOnSale(course.price, course.originalPrice);
    final favorite = isFavorite ?? false;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh bìa bên trái
                    Stack(
                      children: [
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
                        // Nhãn giảm giá đè lên góc trái của ảnh; chữ tự thu nhỏ nếu dài hơn ảnh
                        if (onSale || isPopular)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 102),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPopular) const PopularBadge(compact: true),
                                    if (isPopular && onSale) const SizedBox(height: 3.0),
                                    if (onSale)
                                      SaleBadge(price: course.price, originalPrice: course.originalPrice, compact: true),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (imageOverlay != null) Positioned(top: 4, left: 4, child: imageOverlay!),
                      ],
                    ),
                    const SizedBox(width: AppDimens.p12),

                    // Thông tin bên phải
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    course.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.captionTiny.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                course.duration,
                                style: AppTypography.captionTiny.copyWith(color: AppColors.textSecondary),
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
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6.0),
                          RatingStars(rating: course.rating, reviewCount: course.reviewCount),
                        ],
                      ),
                    ),
                  ],
                ),

                // Hàng cuối: giá ở góc dưới bên phải, nút tim ngay bên phải giá
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Giá cũ gạch ngang ở trên, giá mới ở dưới
                        if (onSale)
                          Text(
                            AppFormatters.formatCurrency(course.originalPrice),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          AppFormatters.formatCurrency(course.price),
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (onFavoriteTap != null) ...[
                      const SizedBox(width: 6.0),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: favorite ? 'Bỏ yêu thích' : 'Yêu thích',
                          icon: Icon(
                            favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: favorite ? AppColors.error : AppColors.textSecondary,
                          ),
                          onPressed: onFavoriteTap,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
