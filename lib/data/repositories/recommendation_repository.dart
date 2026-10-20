import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/category.dart';
import '../models/course.dart';

/// Kết quả gợi ý (C1). [type]: `personal` (lọc cộng tác), `interest` (theo sở thích), `popular` (phổ biến)
class RecommendationResult {
  final String type;
  final List<Course> items;

  const RecommendationResult({required this.type, required this.items});

  bool get isPersonal => type == 'personal';

  /// Tiêu đề khối trên Trang chủ đổi theo nguồn gợi ý
  String get title => type == 'popular' ? 'Khóa học phổ biến' : 'Khóa học dành riêng cho bạn';
}

/// Trạng thái chọn sở thích (C2)
class InterestStatus {
  final bool needSurvey;
  final int maxSelect;
  final List<String> selected;
  final List<Category> categories;

  const InterestStatus({
    required this.needSurvey,
    required this.maxSelect,
    required this.selected,
    required this.categories,
  });
}

/// Nhóm C: Gợi ý khóa học và sở thích (Task_Tuan10.docx mục 6.3). Người dùng chính: Thư.
class RecommendationRepository {
  RecommendationRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// C1. Khóa học gợi ý (không đăng nhập vẫn gọi được, khi đó type = popular)
  Future<RecommendationResult> recommendations({int limit = 10}) async {
    final map = JsonUtils.asMap(await _api.get('/recommendations', query: {'limit': limit}));
    return RecommendationResult(
      type: JsonUtils.asString(map['type'], fallback: 'popular'),
      items: JsonUtils.asMapList(map['items']).map(Course.fromJson).toList(),
    );
  }

  /// C2. Có cần hiện màn chọn sở thích không + danh sách lĩnh vực
  Future<InterestStatus> interests() async {
    final map = JsonUtils.asMap(await _api.get('/interests'));
    return InterestStatus(
      needSurvey: JsonUtils.asBool(map['needSurvey']),
      maxSelect: JsonUtils.asInt(map['maxSelect'], fallback: 3),
      selected: JsonUtils.asStringList(map['selected']),
      categories: JsonUtils.asMapList(map['categories']).map(Category.fromJson).toList(),
    );
  }

  /// C3. Lưu sở thích (tối đa 3 lĩnh vực)
  Future<void> saveInterests(List<String> categoryIds) async {
    await _api.post('/interests', data: {'categoryIds': categoryIds});
  }

  /// C4. Bỏ qua chọn sở thích
  Future<void> skipInterests() async {
    await _api.post('/interests/skip');
  }
}
