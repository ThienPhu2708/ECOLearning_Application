import '../../core/network/api_client.dart';
import '../../core/network/paged_result.dart';
import '../../core/utils/json_utils.dart';
import '../models/course.dart';

/// Nhóm D: Yêu thích (Task_Tuan10.docx mục 6.4). Người dùng chính: Thư (nút tim ở chi tiết), Ngọc (danh sách).
class FavoriteRepository {
  FavoriteRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// D1. Thả tim / bỏ tim. Trả trạng thái mới.
  Future<bool> toggle(String courseId) async =>
      JsonUtils.asBool(JsonUtils.asMap(await _api.post('/favorites/$courseId/toggle'))['isFavorite']);

  /// D2. Danh sách khóa học đã thích
  Future<PagedResult<Course>> list({int page = 1}) async =>
      PagedResult.fromJson(await _api.get('/favorites', query: {'page': page}), Course.fromJson);
}
