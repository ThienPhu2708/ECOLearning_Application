import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/coupon.dart';

/// Compact coupon card shared by home promotions and the coupon wallet.
class CouponVoucherCard extends StatelessWidget {
  const CouponVoucherCard({
    super.key,
    required this.coupon,
    required this.onDetails,
    this.width,
    this.saved = false,
    this.onSave,
  });

  static const double height = 110;

  final Coupon coupon;
  final double? width;
  final bool saved;
  final VoidCallback onDetails;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final isSaved = saved || coupon.saved;
    final expiry = coupon.expiresAt;
    final expiryText = expiry == null
        ? ''
        : 'HSD ${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}';

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 72,
              height: double.infinity,
              color: AppColors.primaryLight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      coupon.discountText,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (coupon.note != null && coupon.note!.isNotEmpty)
                    Text(
                      coupon.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.captionTiny.copyWith(
                        fontSize: 9,
                        color: AppColors.primary,
                      ),
                    ),
                  if (coupon.isLoyalty)
                    const Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.primary,
                      size: 14,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 7, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            coupon.title.isEmpty
                                ? coupon.description
                                : coupon.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          coupon.isPublic ? 'Công khai' : 'Riêng',
                          maxLines: 1,
                          style: AppTypography.captionTiny.copyWith(
                            fontSize: 8,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.description.isEmpty
                          ? coupon.code
                          : '${coupon.code}  ·  ${coupon.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionTiny.copyWith(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (coupon.conditions.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        coupon.conditions.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionTiny.copyWith(fontSize: 9),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expiryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.captionTiny.copyWith(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onDetails,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 28),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text(
                            'Chi tiết',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        if (isSaved)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              '✓ Đã lưu',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else if (onSave != null)
                          FilledButton.tonal(
                            onPressed: onSave,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 28),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text(
                              'Lưu mã',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
