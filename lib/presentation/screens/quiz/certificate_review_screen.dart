import 'package:flutter/material.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../widgets/state_views.dart';
import '../learning/rating_dialog.dart';
import '../my_courses/certificate_screen.dart';

/// Only the successful claim flow offers a review; viewing an existing certificate does not.
class CertificateReviewScreen extends StatefulWidget {
  final Map<String, dynamic> certificate;
  final String courseId;
  final CourseRepository courses;
  final ReviewRepository reviews;
  const CertificateReviewScreen({
    super.key,
    required this.certificate,
    required this.courseId,
    required this.courses,
    required this.reviews,
  });
  @override
  State<CertificateReviewScreen> createState() =>
      _CertificateReviewScreenState();
}

class _CertificateReviewScreenState extends State<CertificateReviewScreen> {
  bool _prompting = false, _reviewed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _offerReview();
    });
  }

  Future<void> _offerReview() async {
    if (_prompting || _reviewed || !mounted) return;
    _prompting = true;
    try {
      final course = await widget.courses.detail(widget.courseId);
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (course.myReviewRating != null || !course.canReview) return;
      await RatingDialog.show(
        context,
        course: course,
        dismissLabel: 'Để sau',
        onSubmit: (rating, comment) async {
          await widget.reviews.submit(
            widget.courseId,
            rating: rating.toInt(),
            comment: comment,
          );
          _reviewed = true;
          course.myReviewRating = rating;
          course.myReviewComment = comment;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cảm ơn bạn đã đánh giá khóa học.')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nhận chứng chỉ. ${errorMessage(e)}'),
            action: SnackBarAction(label: 'Thử lại', onPressed: _offerReview),
          ),
        );
      }
    } finally {
      _prompting = false;
    }
  }

  @override
  Widget build(BuildContext context) =>
      CertificateScreen(certificate: widget.certificate);
}
