/// Cấu hình kết nối API (Task_Tuan10.docx, mục 5.2).
///
/// Địa chỉ Cloudflare Tunnel đổi mỗi lần Phú chạy lại, nên chỉ cần sửa 1 dòng [baseUrl]
/// hoặc truyền khi chạy, không phải sửa code:
///   flutter run --dart-define=API_BASE_URL=https://xxxx.trycloudflare.com/api/v1
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://xxxx.trycloudflare.com/api/v1',
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
