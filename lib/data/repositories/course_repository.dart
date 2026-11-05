import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/paged_result.dart';
import '../../core/utils/json_utils.dart';
import '../models/category.dart';
import '../models/course.dart';

/// Nguồn mở màn hình chi tiết, gửi kèm khi ghi nhận click (B6)
class ClickSource {
  ClickSource._();
  static const home = 'home';
  static const recommend = 'recommend';
  static const search = 'search';
  static const category = 'category';
  static const similar = 'similar';
  static const chatbot = 'chatbot';
  static const promo = 'promo';
}

/// Nhóm B: Danh mục, khóa học, tìm kiếm (Task_Tuan10.docx mục 6.2). Người dùng chính: Thư.
class CourseRepository {
  CourseRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// B1. Danh sách lĩnh vực (có ảnh minh họa)
  Future<List<Category>> categories() async =>
      JsonUtils.asMapList(await _api.get('/categories')).map(Category.fromJson).toList();

  /// B2. Danh sách / tìm kiếm khóa học.
  /// [level]: Cơ bản / Trung cấp / Nâng cao • [price]: free / paid •
  /// [sort]: popular / newest / rating / price_asc / price_desc
  Future<PagedResult<Course>> courses({
    String? q,
    String? categoryId,
    String? level,
    String? price,
    double? minRating,
    String? sort,
    int page = 1,
    int pageSize = ApiConfig.defaultPageSize,
  }) async {
    final data = await _api.get('/courses', query: {
      'q': q,
      'categoryId': categoryId,
      'level': level,
      'price': price,
      'minRating': minRating,
      'sort': sort,
      'page': page,
      'pageSize': pageSize,
    });
    return PagedResult.fromJson(data, Course.fromJson);
  }

  /// B3. Chi tiết khóa học (đã đăng nhập thì có thêm isEnrolled, isFavorite, canReview, myReview)
  Future<Course> detail(String courseId) async =>
      Course.fromJson(JsonUtils.asMap(await _api.get('/courses/$courseId')));

  /// B4. Đánh giá của khóa học: `{ "summary": {...}, "items": [...], "page", ... }`
  Future<Map<String, dynamic>> reviews(String courseId, {int? stars, int page = 1}) async =>
      JsonUtils.asMap(await _api.get('/courses/$courseId/reviews', query: {'stars': stars, 'page': page}));

  /// B5. Gợi ý từ khóa: `{ "keywords": [...], "courses": [...] }`. Để trống [q] → từ khóa thịnh hành.
  Future<({List<String> keywords, List<Course> courses})> suggest(String q) async {
    final map = JsonUtils.asMap(await _api.get('/search/suggest', query: {'q': q}));
    return (
      keywords: JsonUtils.asStringList(map['keywords']),
      courses: JsonUtils.asMapList(map['courses']).map(Course.fromJson).toList(),
    );
  }

  /// B6. Ghi nhận click thẻ khóa học (dữ liệu cho thuật toán gợi ý). Gọi khi đã đăng nhập, không chờ kết quả.
  void trackClick(String courseId, String source) {
    _api.fireAndForget('/courses/$courseId/click', data: {'source': source});
  }

  /// B7. Khóa học tương tự
  Future<List<Course>> similar(String courseId, {int limit = 8}) async =>
      JsonUtils.asMapList(await _api.get('/courses/$courseId/similar', query: {'limit': limit}))
          .map(Course.fromJson)
          .toList();

  /// B8. Link video xem thử của bài miễn phí: `{ "videoUrl", "durationSeconds" }`
  Future<Map<String, dynamic>> preview(String courseId, String lessonId) async =>
      JsonUtils.asMap(await _api.get('/courses/$courseId/preview/$lessonId'));
}
