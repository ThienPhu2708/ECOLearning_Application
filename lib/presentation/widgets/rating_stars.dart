import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Widget hiển thị và chấm sao đánh giá (1 đến 5 sao vàng #F59E0B)
class RatingStars extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;
  final bool isInteractive;
  final ValueChanged<double>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 16.0,
    this.isInteractive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isInteractive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final starValue = index + 1.0;
          return IconButton(
            iconSize: size,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Icon(
              rating >= starValue ? Icons.star_rounded : Icons.star_border_rounded,
              color: rating >= starValue ? AppColors.warning : AppColors.textMuted,
            ),
            onPressed: () {
              if (onRatingChanged != null) {
                onRatingChanged!(starValue);
              }
            },
          );
        }),
      );
    }

    if (reviewCount == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_border_rounded, color: AppColors.textMuted, size: 18.0),
          const SizedBox(width: 4.0),
          Text(
            'Chưa có đánh giá',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w400),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.star_rounded,
          color: AppColors.warning,
          size: 18.0,
        ),
        const SizedBox(width: 4.0),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textHeading,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4.0),
          Text(
            '($reviewCount)',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
