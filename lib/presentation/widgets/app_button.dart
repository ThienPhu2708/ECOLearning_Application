import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';

enum AppButtonType { primary, secondary, danger, ghost }

/// Widget Nút bấm chuẩn hóa theo Design System Mục 2.3 & 3.3.1.1
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final Widget? icon;
  final bool isLoading;
  final double? height;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.height = 50.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.white;
        break;
      case AppButtonType.secondary:
        backgroundColor = AppColors.surface;
        foregroundColor = AppColors.textHeading;
        borderSide = const BorderSide(color: AppColors.border, width: 1.5);
        break;
      case AppButtonType.danger:
        backgroundColor = AppColors.error;
        foregroundColor = Colors.white;
        break;
      case AppButtonType.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        break;
    }

    final buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: AppDimens.p8)],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: borderSide,
          shape: RoundedRectangleBorder(borderRadius: AppDimens.radiusButton),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
        ),
        child: buttonChild,
      ),
    );
  }
}
