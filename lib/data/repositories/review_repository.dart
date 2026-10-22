import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';

/// Nhóm E: Đánh giá khóa học (Task_Tuan10.docx mục 6.5). Người dùng chính: Ngọc.
/// Danh sách đánh giá của khóa học (B4) nằm ở CourseRepository.reviews.
class ReviewRepository {
  ReviewRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// E1. Gửi hoặc sửa đánh giá của tôi. [rating] 1 – 5, [comment] có thể để trống.
  /// Lỗi 403 `NOT_ELIGIBLE`: chưa học đủ 100% bài hoặc chưa đạt quiz.
  Future<Map<String, dynamic>> submit(
    String courseId, {
    required int rating,
    String? comment,
  }) async => JsonUtils.asMap(
    await _api.post(
      '/courses/$courseId/reviews',
      data: {'rating': rating, 'comment': comment?.trim()},
    ),
  );
  Future<void> delete(String courseId) async {
    await _api.delete('/courses/$courseId/reviews');
  }
}
