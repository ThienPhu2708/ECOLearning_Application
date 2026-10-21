/// Cấu hình kết nối API (Task_Tuan10.docx, mục 5.2).
///
/// Có thể ghi đè địa chỉ máy chủ bằng --dart-define=API_BASE_URL=... khi chạy.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ecolearning.runasp.net/api/v1',
  );

  static String resolveMediaUrl(String value) {
    if (value.isEmpty) return value;
    final uri = Uri.parse(value);
    if (uri.hasScheme) return value;
    return Uri.parse('${Uri.parse(baseUrl).origin}/').resolve(value).toString();
  }

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Số khóa học mỗi trang khi phân trang (server tối đa 50)
  static const int defaultPageSize = 12;

  /// Thanh toán VNPay (mục 6.9): WebView gặp địa chỉ chứa chuỗi này thì đóng lại và gọi F4 lấy trạng thái đơn
  static const String paymentResultPath = '/Payment/Result';

  /// Phương thức thanh toán duy nhất dùng được trên VNPay Sandbox
  static const String paymentMethodAtm = 'Napas';

  /// Lưu tiến độ học mỗi 15 giây khi đang phát video (mục 6.10)
  static const Duration progressSaveInterval = Duration(seconds: 15);
}
