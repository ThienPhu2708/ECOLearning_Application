import '../utils/json_utils.dart';

/// Dữ liệu phân trang (Task_Tuan10.docx, mục 5.4):
/// `{ "items": [...], "page": 1, "pageSize": 12, "total": 37, "totalPages": 4 }`
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  const PagedResult.empty()
      : items = const [],
        page = 1,
        pageSize = 0,
        total = 0,
        totalPages = 0;

  /// Còn trang sau để "cuộn tải thêm"
  bool get hasMore => page < totalPages;
  bool get isEmpty => items.isEmpty;

  factory PagedResult.fromJson(dynamic json, T Function(Map<String, dynamic>) fromItem) {
    final map = JsonUtils.asMap(json);
    return PagedResult(
      items: JsonUtils.asMapList(map['items']).map(fromItem).toList(),
      page: JsonUtils.asInt(map['page'], fallback: 1),
      pageSize: JsonUtils.asInt(map['pageSize']),
      total: JsonUtils.asInt(map['total']),
      totalPages: JsonUtils.asInt(map['totalPages']),
    );
  }
}
