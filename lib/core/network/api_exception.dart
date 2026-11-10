import 'package:dio/dio.dart';

/// Lỗi khi gọi API, theo khung lỗi chung (Task_Tuan10.docx, mục 5.3):
/// `{ "success": false, "code": "EMAIL_EXISTS", "message": "...", "errors": { "email": "..." } }`
///
/// [message] là câu tiếng Việt, hiện thẳng cho người dùng.
/// [code] để app xử lý riêng khi cần (vd: `NOT_ELIGIBLE`, `OTP_EXPIRED`).
class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;
  final Map<String, String> errors;

  const ApiException({
    this.statusCode,
    this.code = 'UNKNOWN',
    required this.message,
    this.errors = const {},
  });

  static const String networkCode = 'NETWORK';

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isNetwork => code == networkCode;

  /// Lỗi của một ô nhập (tô viền đỏ theo `errors`)
  String? fieldError(String field) => errors[field];

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const ApiException(
          code: networkCode,
          message: 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.',
        );
      default:
        break;
    }

    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (body is Map) {
      final errors = <String, String>{};
      final raw = body['errors'];
      if (raw is Map) {
        raw.forEach((k, v) => errors['$k'] = v is List ? v.join(' ') : '$v');
      }
      return ApiException(
        statusCode: status,
        code: (body['code'] ?? 'HTTP_${status ?? 0}').toString(),
        message: (body['message'] ?? defaultMessage(status)).toString(),
        errors: errors,
      );
    }
    return ApiException(
      statusCode: status,
      code: 'HTTP_${status ?? 0}',
      message: defaultMessage(status),
    );
  }

  static String defaultMessage(int? status) {
    switch (status) {
      case 400:
        return 'Dữ liệu gửi lên không hợp lệ.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không đủ điều kiện thực hiện thao tác này.';
      case 404:
        return 'Không tìm thấy dữ liệu.';
      case 409:
        return 'Dữ liệu bị trùng hoặc đã tồn tại.';
      default:
        return 'Có lỗi xảy ra, vui lòng thử lại.';
    }
  }

  @override
  String toString() => message;
}
