/// Cấu hình kết nối API (Task_Tuan10.docx, mục 5.2).
///
/// Địa chỉ Cloudflare Tunnel đổi mỗi lần Phú chạy lại, nên chỉ cần sửa 1 dòng [baseUrl]
/// hoặc truyền khi chạy, không phải sửa code:
///   flutter run --dart-define=API_BASE_URL=https://ecolearning.runasp.net/api/v1
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ecolearning.runasp.net/api/v1',
  );

  /// Web client ID của Google Cloud (loại "Web application"), dùng để lấy ID token gửi cho server.
  ///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Số khóa học mỗi trang khi phân trang (server tối đa 50). Cuộn gần cuối thì tải trang kế tiếp.
  static const int defaultPageSize = 10;

  /// Thanh toán VNPay (mục 6.9): WebView gặp địa chỉ chứa chuỗi này thì đóng lại và gọi F4 lấy trạng thái đơn
  static const String paymentResultPath = '/Payment/Result';

  /// Phương thức thanh toán duy nhất dùng được trên VNPay Sandbox
  static const String paymentMethodAtm = 'Napas';

  /// Lưu tiến độ học mỗi 15 giây khi đang phát video (mục 6.10)
  static const Duration progressSaveInterval = Duration(seconds: 15);
}
