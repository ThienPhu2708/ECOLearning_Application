/// Đọc JSON an toàn: server trả thiếu trường hoặc khác kiểu (int / double / chuỗi) thì dùng giá trị mặc định,
/// không làm app văng lỗi.
class JsonUtils {
  JsonUtils._();

  static String asString(dynamic v, {String fallback = ''}) => v == null ? fallback : v.toString();

  static String? asStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static int asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round() ?? fallback;
    return fallback;
  }

  static double asDouble(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool asBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return fallback;
  }

  /// Thời gian ISO 8601 (vd "2026-10-20T10:09:00+07:00"), đổi về giờ máy
  static DateTime? asDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  static Map<String, dynamic> asMap(dynamic v) =>
      v is Map ? v.map((k, value) => MapEntry(k.toString(), value)) : <String, dynamic>{};

  static List<dynamic> asList(dynamic v) => v is List ? v : const [];

  static List<Map<String, dynamic>> asMapList(dynamic v) => asList(v).whereType<Map>().map(asMap).toList();

  static List<String> asStringList(dynamic v) => asList(v).where((e) => e != null).map((e) => e.toString()).toList();
}
