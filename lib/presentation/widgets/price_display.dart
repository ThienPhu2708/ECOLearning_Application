import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';

enum PriceSize { small, medium, large }

/// Giá khóa học dùng chung cho thẻ, chi tiết và giỏ hàng.
///
/// Khóa đang giảm: giá mới đậm màu đỏ, giá gốc xám gạch ngang, kèm nhãn "-X%".
/// Khóa không giảm chỉ hiện một giá, không gạch.
class PriceDisplay extends StatelessWidget {
  final double price;
  final double originalPrice;
  final PriceSize size;

  /// true: giá gốc nằm trên giá mới (dạng cột); false: cùng một hàng.
  final bool stacked;
  final CrossAxisAlignment alignment;
  final bool showPercent;

  const PriceDisplay({
    super.key,
    required this.price,
    required this.originalPrice,
    this.size = PriceSize.medium,
    this.stacked = false,
    this.alignment = CrossAxisAlignment.start,
    this.showPercent = true,
  });

  bool get onSale => originalPrice > price && originalPrice > 0;

  int get percent =>
      onSale ? ((originalPrice - price) / originalPrice * 100).round() : 0;

  @override
  Widget build(BuildContext context) {
    final (newStyle, oldStyle) = switch (size) {
      PriceSize.small => (AppTypography.bodyMedium, AppTypography.captionTiny),
      PriceSize.medium => (AppTypography.titleMedium, AppTypography.labelSmall),
      PriceSize.large => (
        AppTypography.headlineMedium,
        AppTypography.labelSmall,
      ),
    };
    final current = Text(
      AppFormatters.formatCurrency(price),
      style: newStyle.copyWith(
        color: onSale ? AppColors.error : AppColors.primary,
        fontWeight: FontWeight.w800,
        fontSize: size == PriceSize.large ? 20.0 : null,
      ),
    );
    if (!onSale) return current;

    final old = Text(
      AppFormatters.formatCurrency(originalPrice),
      style: oldStyle.copyWith(
        color: AppColors.textMuted,
        decoration: TextDecoration.lineThrough,
      ),
    );
    final pill = (showPercent && percent > 0)
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-$percent%',
              style: AppTypography.captionTiny.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        : null;

    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              old,
              if (pill != null) ...[const SizedBox(width: 6), pill],
            ],
          ),
          current,
        ],
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppDimens.p8,
      runSpacing: 2,
      children: [current, old, ?pill],
    );
  }
}
