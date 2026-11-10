import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../widgets/state_views.dart';
import 'rating_dialog.dart';

Future<void> openCourseReview(
  BuildContext context,
  Course course, {
  required CourseRepository courses,
  required ReviewRepository reviews,
}) async {
  try {
    final detail = await courses.detail(course.id);
    if (!context.mounted) return;
    if (detail.myReviewRating != null) {
      final edit = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Đánh giá của tôi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${detail.myReviewRating!.toInt()}/5 ★',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB96B08),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Icon(
                                index < detail.myReviewRating!.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFF4AB29),
                                size: 25,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nhận xét của bạn',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      detail.myReviewComment?.trim().isNotEmpty == true
                          ? detail.myReviewComment!
                          : 'Bạn chưa viết nhận xét.',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, 'close'),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Đóng', maxLines: 1),
                      ),
                    ),
                  ),
                ),
                if (detail.canReview) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 46,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, 'edit'),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Sửa đánh giá', maxLines: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (edit != 'edit') return;
    }
    if (!detail.canReview) {
      showErrorSnackBar(
        context,
        const ApiException(
          message: 'Bạn cần hoàn thành tất cả bài học trước khi đánh giá.',
        ),
      );
      return;
    }
    await RatingDialog.show(
      context,
      course: detail,
      onSubmit: (rating, comment) async {
        await reviews.submit(
          course.id,
          rating: rating.toInt(),
          comment: comment,
        );
        course.myReviewRating = rating;
        course.myReviewComment = comment;
      },
    );
  } catch (error) {
    if (context.mounted) showErrorSnackBar(context, error);
  }
}
