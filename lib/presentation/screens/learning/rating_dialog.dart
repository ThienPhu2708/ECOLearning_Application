import 'package:flutter/material.dart';
import '../../widgets/state_views.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/course.dart';
import '../../widgets/app_button.dart';
import '../../widgets/rating_stars.dart';

/// Hộp thoại Đánh giá khóa học 5 sao theo QuyChuanThietKe_App.md Mục 4.6 & UC6
class RatingDialog extends StatefulWidget {
  final Course course;
  final String dismissLabel;
  final Future<void> Function(double rating, String comment) onSubmit;

  const RatingDialog({
    super.key,
    required this.course,
    required this.onSubmit,
    this.dismissLabel = 'Hủy',
  });

  static Future<void> show(
    BuildContext context, {
    required Course course,
    String dismissLabel = 'Hủy',
    required Future<void> Function(double rating, String comment) onSubmit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        course: course,
        onSubmit: onSubmit,
        dismissLabel: dismissLabel,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Tải lại đánh giá cũ nếu học viên đã từng đánh giá trước đó (UC6)
    if (widget.course.myReviewRating != null) {
      _selectedRating = widget.course.myReviewRating!;
    }
    if (widget.course.myReviewComment != null) {
      _commentController.text = widget.course.myReviewComment!;
    }
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    if (_selectedRating <= 0) {
      setState(() {
        _error = 'Vui lòng chọn số sao đánh giá (1 - 5 sao)';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_selectedRating, _commentController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppDimens.radiusCard),
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.all(AppDimens.p20),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: const BoxDecoration(
                    color: AppColors.warningLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.warning,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Đánh giá khóa học',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  widget.course.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Chọn số sao 1 - 5
                RatingStars(
                  rating: _selectedRating,
                  size: 36.0,
                  isInteractive: true,
                  onRatingChanged: (newRating) {
                    if (_submitting) return;
                    setState(() {
                      _selectedRating = newRating;
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 8.0),
                Text(
                  _selectedRating == 0
                      ? 'Chọn số sao đánh giá'
                      : '${_selectedRating.toInt()} / 5 sao (${_getRatingLabel(_selectedRating)})',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16.0),

                if (_error != null) ...[
                  Text(
                    _error!,
                    style: AppTypography.captionTiny.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                ],

                // Khung nhập cảm nhận
                TextField(
                  controller: _commentController,
                  enabled: !_submitting,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Cảm nhận của bạn về khóa học (tùy chọn)...',
                    contentPadding: EdgeInsets.all(12.0),
                  ),
                ),
                const SizedBox(height: 20.0),

                AppButton(
                  text: 'Gửi đánh giá',
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _handleSubmit,
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(widget.dismissLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(double rating) {
    switch (rating.toInt()) {
      case 5:
        return 'Tuyệt vời';
      case 4:
        return 'Rất tốt';
      case 3:
        return 'Bình thường';
      case 2:
        return 'Cần cải thiện';
      default:
        return 'Kém';
    }
  }
}
